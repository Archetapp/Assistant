//
//  AppDelegate.swift
//  Assistant
//
//  Created by Jared Davidson on 11/4/24.
//

import Cocoa
import SwiftUI
import HotKey

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var hotKey: HotKey?
    var reviewWindow: NSWindow?
    private var reviewWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        setupHotkey()
    }
    
    private func setupMenuBar() {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "brain", accessibilityDescription: "AI")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create and configure the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
    }
    
    private func setupHotkey() {
        hotKey = HotKey(key: .a, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.captureScreenSelection()
            }
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover()
            } else {
                showPopover(button)
            }
        }
    }
    
    func showPopover(_ sender: NSView) {
        // Close review window if it's open
        closeReviewWindow()
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
    
    func closePopover() {
        popover.performClose(nil)
    }
    
    func captureScreenSelection() {
        // Ensure previous window is properly closed before creating a new one
        closeReviewWindow()
        closePopover() // Also close popover if it's open
        
        let selectionWindow = ScreenSelectionWindow()
        selectionWindow.beginSelection { [weak self] image in
            guard let self = self,
                  let capturedImage = image else {
                return
            }
            
            self.showReviewWindow(image: capturedImage, rect: selectionWindow.selectionRect)
        }
    }
    
    private func closeReviewWindow() {
        if let window = reviewWindow {
            window.close()
            reviewWindow = nil
        }
        reviewWindowController = nil
    }
    
    func showReviewWindow(image: NSImage, rect: NSRect) {
        self.closeReviewWindow()
        
        let panel = ScreenshotReviewPanel(image: image, rect: rect)
        let windowController = NSWindowController(window: panel)
        
        reviewWindow = panel
        reviewWindowController = windowController
        
        panel.makeKeyAndOrderFront(nil)
        panel.makeKey()
    }
}
