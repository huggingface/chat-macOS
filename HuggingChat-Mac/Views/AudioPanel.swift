//
//  AudioPanel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/17/24.
//

import Foundation
import AppKit

class ToastPanel: FloatingPanel {
    override init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, backing: backing, defer: flag)
        self.setFrameAutosaveName("hfToastPanel")
    }
    
    override func resignMain() {}
    
//    override func windowDidResignKey(_ notification: Notification) { }
}
