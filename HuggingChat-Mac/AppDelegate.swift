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

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    
    @State var coordinatorModel = CoordinatorModel()
    @AppStorage(UserDefaultsKeys.userLoggedIn) private var isLoggedIn: Bool = false
    
    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem!
    
    var chatBar: FloatingChatBar!
    var chatWindow: FloatingChatWindow!

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        createMenuBarItem()
        createChatBar()
        createChatWindow()
        chatBar.center()
        chatWindow.center()
        
        // Set keyboard shortcut
        KeyboardShortcuts.onKeyUp(for: .showChatBar, action: {
            if self.isLoggedIn {
                self.toggleChatBar()
            }
        })
    }
    
    // MARK: Status item
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
            if isLoggedIn {
                toggleChatBar()
            }
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
        let contentView = InputView(cornerRadius: 22, isChatBarMode: true, onSubmit: {})
            .frame(minHeight: 287, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
            .environment(coordinatorModel)
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
    
    // MARK: Chat window
    private func createChatWindow() {
        let contentView = ChatView(
            isPipMode: true,
            onPipToggle: { [weak self] in
                self?.toggleChatWindow()
            }, showShareSheet: .constant(false)
        )
        .environment(coordinatorModel)
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 600)
        .frame(minHeight: 300, idealHeight: 300)
        
    
        
        chatWindow = FloatingChatWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 100),
                                      backing: .buffered,
                                      defer: false)
        
        chatWindow.contentView = NSHostingView(rootView: contentView)
    }
    
    // Update ContentView usage
    func makeContentView() -> some View {
        ContentView()
            .environment(coordinatorModel)
            .onOpenURL { url in
                if let component = URLComponents(string: url.absoluteString),
                   let code = component.queryItems?.first(where: { $0.name == "code"})?.value,
                   let state = component.queryItems?.first(where: { $0.name == "state"})?.value {
                    self.coordinatorModel.validateSignup(code: code, state: state)
                }
            }
    }
    
    @objc func toggleChatWindow() {
        if self.chatWindow.isVisible {
            self.chatWindow.orderOut(nil)
        } else {
            self.chatWindow.makeKeyAndOrderFront(nil)
        }
    }
}
