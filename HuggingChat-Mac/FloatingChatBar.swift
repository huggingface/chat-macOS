//
//  FloatingPanel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/16/24.
//

import AppKit
import Foundation

class FloatingChatBar: NSPanel, NSWindowDelegate {
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless], backing: backing, defer: flag)
        self.delegate = self
        
        // Spotlight behavior
        self.setFrameAutosaveName("hfChatBar")
        self.isFloatingPanel = true
        self.level = .popUpMenu
        
        self.collectionBehavior.insert(.fullScreenAuxiliary)
        self.collectionBehavior.insert(.canJoinAllSpaces)
        
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = true
        //  Attachment shadows not updated when scrolling leading to artifact.
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
        close()
    }
    
    override func resignMain() {
        super.resignMain()
            close()
    }
    
    func windowDidResignKey(_ notification: Notification) {
            close()
    }
}
