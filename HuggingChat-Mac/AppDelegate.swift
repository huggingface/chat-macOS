//
//  AppDelegate.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/16/24.
//

import Foundation
import AppKit
import MLXLLM

import Combine
import KeyboardShortcuts
import SwiftUI
import WhisperKit
import AVFoundation

extension KeyboardShortcuts.Name {
    static let showFloatingPanel = Self("showFloatingPanel", default: .init(.return, modifiers: [.command, .shift]))
    static let toggleLocalGeneration = Self("toggleLocalGeneration", default: .init(.backslash, modifiers: [.command, .shift]))
    static let showTranscriptionPanel = Self("showTranscriptionPanel", default: .init(.space, modifiers: [.command, .shift]))
}

class AppDelegate: NSObject, NSApplicationDelegate {

    @AppStorage("hideDock") private var hideDock: Bool = false
    @AppStorage("localModel") private var selectedLocalModel: String = "None"
    @AppStorage("selectedAudioModel") private var selectedAudioModel: String = "None"
    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = "None"
    @AppStorage("smartDictation") private var smartDictation: Bool = false
    @AppStorage("isLocalGeneration") private var isLocalGeneration: Bool = false
    @AppStorage("useContext") private var useContext: Bool = false
    
    @Environment(\.openSettings) private var openSettings
    
    @State var modelManager = ModelManager()
    @State var audioModelManager = AudioModelManager()
    @State var conversationModel = ConversationViewModel()
    @State var themeEngine = ThemingEngine()
    
    var newEntryPanel: FloatingPanel!
    var transcriptionPanel: ToastPanel!
    var statusBar: NSStatusBar!
    var statusBarItem: NSStatusItem!
    
    private var recordingTimer: Timer?
    private var isKeyDown = false
    private var cancellable: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        createFloatingPanel()
        newEntryPanel.center()
        
        createTranscriptionPanel()
        
        // Set keyboard shortcut
        KeyboardShortcuts.onKeyUp(for: .showFloatingPanel, action: {
            self.toggleFloatingPanel()
        })
        
        KeyboardShortcuts.onKeyUp(for: .toggleLocalGeneration, action: {
            if self.selectedLocalModel != "None" {
                self.isLocalGeneration.toggle()
            }
        })
        
        KeyboardShortcuts.onKeyDown(for: .showTranscriptionPanel, action: {
            self.handleKeyDown()
        })
        
        KeyboardShortcuts.onKeyUp(for: .showTranscriptionPanel, action: {
            self.handleKeyUp()
        })
        
        // Check hide dock status
        NSApp.setActivationPolicy(hideDock ? .accessory : .regular)
        
        // Setup local model if needed
        if selectedLocalModel != "None" {
            if let selectedLocalModel = modelManager.availableModels.first(where: { $0.displayName == selectedLocalModel }) {
                Task {
                    await modelManager.localModelDidChange(to: selectedLocalModel)
                }
            }
        }
        
        // Setup transcription model if needed
        audioModelManager.setupMicrophone()
        if selectedAudioModel != "None" {
            audioModelManager.loadModel(selectedAudioModel)
        }
        
        createMenuBarItem()
    }
    
    private func createFloatingPanel() {
        let contentView = ChatView()
            .environment(themeEngine)
            .environment(modelManager)
            .environment(conversationModel)
            .environment(audioModelManager)
            .frame(minWidth: 300, idealWidth: 450, maxWidth: 600)
//            .fixedSize(horizontal: true, vertical: false)
        //            .edgesIgnoringSafeArea(.top)
        //            .frame(width: 500) // TODO: Should be relative to screen size
        newEntryPanel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 400), backing: .buffered, defer: false)
        newEntryPanel.contentView = NSHostingView(rootView: contentView)
//        newEntryPanel.contentView?.clipsToBounds = false
        
    }
    
    private func createTranscriptionPanel() {
        let contentView = TranscriptionView()
            .environment(modelManager)
            .environment(conversationModel)
            .environment(audioModelManager)
        
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
        let panelWidth: CGFloat = 95
        let panelHeight: CGFloat = 75
        let topPadding: CGFloat = 10
        
        let xPosition = (screenFrame.width - panelWidth) / 2 + screenFrame.minX
        let yPosition = screenFrame.maxY - panelHeight - topPadding
        
        let panelFrame = NSRect(x: xPosition, y: yPosition, width: panelWidth, height: panelHeight)
        
        transcriptionPanel = ToastPanel(contentRect: panelFrame, backing: .buffered, defer: false)
        transcriptionPanel.contentView = NSHostingView(rootView: contentView)
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
    
    @objc private func toggleFloatingPanel() {
        if self.newEntryPanel.isVisible {
            self.newEntryPanel.orderOut(nil)
        } else {
            self.newEntryPanel.makeKeyAndOrderFront(nil)
            
            if useContext {
                conversationModel.fetchContext()
            }
//            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func handleKeyDown() {
        isKeyDown = true
        // Add a small delay, otherwise won't cancel properly on key up
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            if self?.isKeyDown == true {
                self?.startRecording()
            }
        }
    }
    
    private func handleKeyUp() {
        isKeyDown = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        if self.transcriptionPanel.isVisible {
            self.stopRecording()
        }
    }
    
    @objc private func startRecording() {
        if selectedAudioModel != "None" && selectedAudioInput != "None" && audioModelManager.modelState == .loaded  {
            self.transcriptionPanel.orderFront(nil)
            if self.transcriptionPanel.isVisible {
                audioModelManager.resetState()
                audioModelManager.startRecording(true, source: .transcriptionView)
            }
        }
    }
    
    @objc private func stopRecording() {
        audioModelManager.stopRecording(false)
        self.transcriptionPanel.orderOut(nil)
    }
    
    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "About", action: #selector(openAboutWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openPreferencesWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu
        statusBarItem.button?.performClick(nil)
        statusBarItem.menu = nil
    }
    
    @objc private func handleStatusItemClick(sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.isRightClickUp {
            showContextMenu()
        } else {
            toggleFloatingPanel()
        }
    }
    
    // Sometimes we do things we aren't proud of.
    @objc private func openPreferencesWindow() {
        //        openSettings()
        let kAppMenuInternalIdentifier  = "app"
        let kSettingsLocalizedStringKey = "Settings\\U2026";
        if let internalItemAction = NSApp.mainMenu?.item(
            withInternalIdentifier: kAppMenuInternalIdentifier
        )?.submenu?.item(
            withLocalizedTitle: kSettingsLocalizedStringKey
        )?.internalItemAction {
            internalItemAction();
            return;
        }
    }
    
    @objc private func openAboutWindow() {
        // I would much prefer this but it results in a runtime warning:
        // openWindow(id: "about")
        for window in NSApplication.shared.windows {
            if window.identifier?.rawValue == "about" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        
        let aboutView = AboutView()
            .frame(width: 450, height: 175)
            .toolbarBackground(.hidden, for: .windowToolbar)
        let aboutWindow = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 450, height: 175),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        aboutWindow.identifier = NSUserInterfaceItemIdentifier("about")
        aboutWindow.title = "About"
        aboutWindow.isReleasedWhenClosed = false
        aboutWindow.center()
        aboutWindow.isOpaque = false
        
        // Hide the title bar
        aboutWindow.titlebarAppearsTransparent = true
        aboutWindow.titleVisibility = .hidden
        aboutWindow.isMovableByWindowBackground = true
        
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .menu
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        
        let hostingView = NSHostingView(rootView: aboutView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add visual effect view and hosting view to the window
        aboutWindow.contentView = visualEffectView
        visualEffectView.addSubview(hostingView)
        
        // Add constraints
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor)
        ])
        
        aboutWindow.makeKeyAndOrderFront(nil)
    }
}
