//
//  ScreenshotReviewPanel.swift
//  Assistant
//
//  Created by Jared Davidson on 11/6/24.
//

import SwiftUI

class ScreenshotReviewPanel: NSPanel {
    private var reviewViewController: NSHostingController<ScreenshotReviewView>?
    
    init(image: NSImage, rect: NSRect, targetScreen: NSScreen? = nil) {
        // Use the provided screen or fallback to main screen
        let screen = targetScreen ?? NSScreen.main
        guard let screen = screen else {
            super.init(contentRect: .zero,
                      styleMask: [],
                      backing: .buffered,
                      defer: true)
            return
        }
        
        // Initialize with the exact screen frame
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        
        setupWindow()
        
        // Important: Convert rect to screen coordinates before passing to view
        let screenRect = convertRectToScreen(rect, screen: screen)
        setupContentView(image: image, rect: screenRect, screenFrame: screen.frame)
        
        self.setFrame(screen.frame, display: true)
    }
    
    private func setupWindow() {
        backgroundColor = NSColor.black.withAlphaComponent(0.2)
        isOpaque = false
        ignoresMouseEvents = false
        isMovableByWindowBackground = false
        hasShadow = false
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        level = .floating
        
        collectionBehavior = [
            .canJoinAllApplications,
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .transient,
            .ignoresCycle
        ]
        
        isReleasedWhenClosed = false
    }
    
    private func convertRectToScreen(_ rect: NSRect, screen: NSScreen) -> NSRect {
        // Convert the rect to absolute screen coordinates
        NSRect(
            x: rect.origin.x + screen.frame.origin.x,
            y: rect.origin.y + screen.frame.origin.y,
            width: rect.width,
            height: rect.height
        )
    }
    
    private func setupContentView(image: NSImage, rect: NSRect, screenFrame: NSRect) {
        let contentView = ScreenshotReviewView(
            image: image,
            rect: rect,
            screenFrame: screenFrame
        )
        
        self.contentView = NSHostingView(rootView: contentView)
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
