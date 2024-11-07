//
//  ScreenSelectionWindow.swift
//  Assistant
//
//  Created by Jared Davidson on 11/4/24.
//

import AppKit
import ScreenCaptureKit
import Combine

class ScreenSelectionWindow: NSPanel {
    var selectionRect = NSRect.zero
    var startPoint = NSPoint.zero
    var selectionView: NSView!
    var completion: ((NSImage?) -> Void)?
    var stream: SCStream?
    var streamOutput: StreamOutputHandler?
    
    deinit {
        stream = nil
        streamOutput = nil
    }
    
    init() {
        super.init(contentRect: NSScreen.main?.frame ?? .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: true)
        
        setupWindow()
        setupSelectionView()
    }
    
    private func setupWindow() {
        backgroundColor = NSColor.black.withAlphaComponent(0.2)
        isOpaque = false
        ignoresMouseEvents = false
        isMovableByWindowBackground = false
        hasShadow = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        
        // Set the window level to the highest possible level
        level = .floating
        
        // Modify collection behavior
        collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .transient,
            .ignoresCycle,
            .moveToActiveSpace
        ]
        
        isReleasedWhenClosed = false
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    private func setupSelectionView() {
        selectionView = NSView(frame: .zero)
        selectionView.wantsLayer = true
        selectionView.layer?.borderColor = NSColor.systemBlue.cgColor
        selectionView.layer?.borderWidth = 1.0
        selectionView.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.2).cgColor
        contentView?.addSubview(selectionView)
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        selectionView.frame = NSRect(origin: startPoint, size: .zero)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let currentPoint = event.locationInWindow
        let origin = NSPoint(x: min(startPoint.x, currentPoint.x),
                             y: min(startPoint.y, currentPoint.y))
        let size = NSSize(width: abs(startPoint.x - currentPoint.x),
                          height: abs(startPoint.y - currentPoint.y))
        selectionRect = NSRect(origin: origin, size: size)
        selectionView.frame = selectionRect
    }
    
    override func mouseUp(with event: NSEvent) {
        Task {
            let captureRect = selectionRect
            
            await MainActor.run {
                selectionView.isHidden = true
                backgroundColor = .clear
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            await captureSelectedArea(captureRect: captureRect)
            
            await MainActor.run {
                self.orderOut(nil)
                self.selectionView.isHidden = false
                self.backgroundColor = NSColor.black.withAlphaComponent(0.2)
            }
        }
    }
    
    func beginSelection(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        
        // Get the screen where the mouse currently is
        let mouseLocation = NSEvent.mouseLocation
        let currentScreen = NSScreen.screens.first { NSPointInRect(mouseLocation, $0.frame) } ?? NSScreen.main
        
        // Set the window frame to the current screen
        if let screenFrame = currentScreen?.frame {
            setFrame(screenFrame, display: false)
        }
        
        makeKeyAndOrderFront(nil)
    }
    
    private func captureSelectedArea(captureRect: NSRect) async {
        do {
            // Convert window coordinates to screen coordinates
            let screenRect = self.convertToScreen(captureRect)
            
            // Get the screen where the window is currently displayed
            guard let targetScreen = screen,
                  let displayID = targetScreen.displayID else {
                print("Failed to find target screen")
                await completeCapture(nil)
                return
            }
            
            let content = try await SCShareableContent.current
            
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                print("Failed to find matching display")
                await completeCapture(nil)
                return
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            let configuration = SCStreamConfiguration()
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            configuration.queueDepth = 1
            
            streamOutput = StreamOutputHandler()
            
            let newStream = SCStream(filter: filter, configuration: configuration, delegate: streamOutput)
            stream = newStream
            
            try stream?.addStreamOutput(streamOutput!,
                                        type: .screen,
                                        sampleHandlerQueue: DispatchQueue(label: "ScreenCaptureQueue"))
            
            try await stream?.startCapture()
            
            if let sampleBuffer = await streamOutput?.captureNextFrame() {
                let image = convertSampleBufferToNSImage(sampleBuffer: sampleBuffer)
                
                // Calculate selection rect relative to the target screen
                let relativeRect = NSRect(
                    x: screenRect.origin.x - targetScreen.frame.origin.x,
                    y: screenRect.origin.y - targetScreen.frame.origin.y,
                    width: screenRect.width,
                    height: screenRect.height
                )
                
                let croppedImage = image.flatMap { cropImage(image: $0, to: relativeRect, targetScreen: targetScreen) }
                await completeCapture(croppedImage)
            } else {
                print("Failed to capture frame")
                await completeCapture(nil)
            }
            
            try await cleanup()
            
        } catch {
            print("Error capturing screen: \(error.localizedDescription)")
            await completeCapture(nil)
            try? await cleanup()
        }
    }
    
    private func cleanup() async throws {
        if let stream = stream {
            try await stream.stopCapture()
        }
        await MainActor.run {
            self.stream = nil
            self.streamOutput = nil
        }
    }
    
    private func completeCapture(_ image: NSImage?) async {
        await MainActor.run {
            completion?(image)
            completion = nil
        }
    }
    
    private func convertSampleBufferToNSImage(sampleBuffer: CMSampleBuffer) -> NSImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let context = CGContext(data: baseAddress,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue),
              let cgImage = context.makeImage() else {
            return nil
        }
        
        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
    }
    
    private func cropImage(image: NSImage, to rect: NSRect, targetScreen: NSScreen) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // Flip the Y coordinate since Core Graphics uses a different coordinate system
        let flippedRect = NSRect(
            x: rect.origin.x,
            y: targetScreen.frame.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: flippedRect) else {
            return nil
        }
        
        return NSImage(cgImage: croppedCGImage, size: rect.size)
    }
}

// StreamOutputHandler and NSScreen extension remain the same...
class StreamOutputHandler: NSObject, SCStreamDelegate, SCStreamOutput {
    private var continuation: CheckedContinuation<CMSampleBuffer?, Never>?
    
    func captureNextFrame() async -> CMSampleBuffer? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
        continuation?.resume(returning: nil)
        continuation = nil
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        continuation?.resume(returning: sampleBuffer)
        continuation = nil
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return screenNumber.uint32Value
    }
}
