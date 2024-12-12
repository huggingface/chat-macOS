//
//  FloatingPanel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/16/24.
//

import AppKit
import Foundation

class FloatingPanel: NSPanel, NSWindowDelegate {
    
    var isFileImporterVisible: Bool = false
    var isFocused: Bool = false
    
    // Snapping window
    enum SnapPosition: Int {
        case bottomLeft = 1
        case bottomRight = 4
        case topLeft = 2
        case topRight = 3
    }
    
    /// Padding from edge of screen
    let padding: CGFloat = 10
    
    /// The latest position the window was snapped to
    var snapPosition: SnapPosition?
    
    private var hasBeenDragged: Bool = false
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless], backing: backing, defer: flag)
        self.delegate = self
        
        // Spotlight behavior
        self.setFrameAutosaveName("hfChatBar")
        self.isFloatingPanel = true
        self.level = .floating
        
        self.collectionBehavior.insert(.fullScreenAuxiliary)
        self.collectionBehavior.insert(.canJoinAllSpaces)
        
        self.titlebarAppearsTransparent = true
        
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
//        self.hasShadow = false  Attachment shadows not updated when scrolling leading to artifact.
                              // Should invalidate shadow on scroll. Set to false for now.
                              // Shadow is set manually.
        
        // Animates but slightly slower
//         self.animationBehavior = .utilityWindow
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    @objc func cancel(_ sender: Any?) {
        // Enables using 'esc' to close the window
        close()
    }
    
    override func resignMain() {
        super.resignMain()
        close()
    }
    
    func windowDidResignKey(_ notification: Notification) {
        if !isFileImporterVisible && !isFocused {
            close()
        }
    }
    
    func updateFileImporterVisibility(_ isVisible: Bool) {
        isFileImporterVisible = isVisible
    }
    
    func updateFocusMode(_ isInFocus: Bool) {
        isFocused = isInFocus
    }
}

extension FloatingPanel {
    override func mouseDragged(with event: NSEvent) {
        if isFocused {
            self.hasBeenDragged = true
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if isFocused {
            if self.hasBeenDragged {
                let mouseY = NSEvent.mouseLocation.y
                let mouseX = NSEvent.mouseLocation.x
                
                if mouseY > (NSScreen.main?.frame.height)! / 2 && mouseX < (NSScreen.main?.frame.width)! / 2 {
                    self.snapTo(position: .topLeft)
                    self.snapPosition = .topLeft
                }
                
                if mouseY <= (NSScreen.main?.frame.height)! / 2 && mouseX < (NSScreen.main?.frame.width)! / 2 {
                    self.snapTo(position: .bottomLeft)
                    self.snapPosition = .bottomLeft
                }
                
                if mouseY > (NSScreen.main?.frame.height)! / 2 && mouseX >= (NSScreen.main?.frame.width)! / 2 {
                    self.snapTo(position: .topRight)
                    self.snapPosition = .topRight
                }
                
                if mouseY <= (NSScreen.main?.frame.height)! / 2 && mouseX >= (NSScreen.main?.frame.width)! / 2 {
                    self.snapTo(position: .bottomRight)
                    self.snapPosition = .bottomRight
                }
                
                self.hasBeenDragged = false
            }
        }
    }
    
    func snapTo(position: SnapPosition) {
        switch position {
        case .bottomLeft:
            self.animator().setFrame(NSRect(x: padding, y: padding + padding*4, width: self.frame.width, height: self.frame.height), display: false, animate: true)
        case .topLeft:
            let position = (NSScreen.main?.frame.height)! - self.frame.height - padding
            self.animator().setFrame(NSRect(x: padding, y: position, width: self.frame.width, height: self.frame.height), display: false, animate: true)
        case .bottomRight:
            self.animator().setFrame(NSRect(x: (NSScreen.main?.frame.width)! - self.frame.width - padding, y: padding + padding*4, width: self.frame.width, height: self.frame.height), display: false, animate: true)
        case .topRight:
            self.animator().setFrame(NSRect(x: (NSScreen.main?.frame.width)! - self.frame.width - padding, y: (NSScreen.main?.frame.height)! - self.frame.height - padding, width: self.frame.width, height: self.frame.height), display: false, animate: true)
        }
    }
}
