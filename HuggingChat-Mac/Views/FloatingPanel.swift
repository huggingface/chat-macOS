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
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless], backing: backing, defer: flag)
        self.delegate = self
        
        // Spotlight behavior
        self.setFrameAutosaveName("hfChatBar")
        self.isFloatingPanel = false
        self.level = .floating
        
        self.collectionBehavior.insert(.fullScreenAuxiliary)
        self.collectionBehavior.insert(.canJoinAllSpaces)
        
        self.titlebarAppearsTransparent = true
        
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false // Attachment shadows not updated when scrolling leading to artifact.
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
        if !isFileImporterVisible {
            close()
        }
    }
    
    func updateFileImporterVisibility(_ isVisible: Bool) {
        isFileImporterVisible = isVisible
    }
}
