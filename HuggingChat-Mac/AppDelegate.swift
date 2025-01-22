//
//  AppDelegate.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/16/24.
//

import Foundation
import AppKit
import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem!
    
    var chatBar: FloatingChatBar!

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        createMenuBarItem()
        createChatBar()
        chatBar.center()
        
        
        // Set keyboard shortcut
        KeyboardShortcuts.onKeyUp(for: .showChatBar, action: {
            self.toggleChatBar()
        })
    }
    
    private func createMenuBarItem() {
        statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(named: "huggy")
            button.target = self
            button.action = #selector(handleStatusItemClick)
            button.sendAction(on: [.leftMouseDown, .rightMouseUp])
        }
    }
    
    @objc private func handleStatusItemClick(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.isRightClickUp {
            showContextMenu()
        } else {
//            toggleFloatingPanel()
        }
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
//        menu.addItem(NSMenuItem(title: "About", action: #selector(openAboutWindow), keyEquivalent: ""))
//        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openPreferencesWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }
    
    
    // MARK: Chat bar
    private func createChatBar() {
        let contentView = InputView(cornerRadius: 22, isChatBarMode: true)
            .frame(minHeight: 287, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
        //            .edgesIgnoringSafeArea(.top)
        //            .frame(width: 500) // TODO: Should be relative to screen size
        chatBar = FloatingChatBar(contentRect: NSRect(x: 0, y: 0, width: 400, height: 400), backing: .buffered, defer: false)
        chatBar.contentView = NSHostingView(rootView: contentView)
    }
    
    @objc private func toggleChatBar() {
            if self.chatBar.isVisible {
                self.chatBar.orderOut(nil)
            } else {
                self.chatBar.makeKeyAndOrderFront(nil)
            }
        }
}
