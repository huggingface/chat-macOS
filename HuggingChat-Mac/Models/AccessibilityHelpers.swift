//
//  AccessibilityHelpers.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/11/24.
//

import Cocoa
import ApplicationServices
import UniformTypeIdentifiers

// MARK: VSCode Reader
struct VSCodeWindow: Decodable {
    let windowId: String
    let lastFocusTime: TimeInterval
    let content: String
    let selectedText: String
    let language: String?
    let fileName: String?
    let timestamp: String
    let isFocused: Bool
}

class VSCodeReader {
    static let shared = VSCodeReader()
    private let portRange = 54321...54330
    
    private init() {}
    
    struct VSCodeContent {
        let content: String
        let selectedText: String
        let language: String?
        let fileName: String?
    }
    
    func getActiveEditorContent() async throws -> VSCodeContent {
        // Try each port until we find an active window
        for port in portRange {
            do {
                let window = try await getWindowContent(port: port)
                if window.isFocused {
                    return VSCodeContent(
                        content: window.content,
                        selectedText: window.selectedText,
                        language: window.language,
                        fileName: window.fileName
                    )
                }
            } catch {
                continue
            }
        }
        
        // If no focused window found, get the most recently focused one
        let windows = try await getAllWindows()
        guard let mostRecent = windows.max(by: { $0.lastFocusTime < $1.lastFocusTime }) else {
            throw AccessibilityError.noActiveWindow
        }
        
        return VSCodeContent(
            content: mostRecent.content,
            selectedText: mostRecent.selectedText,
            language: mostRecent.language,
            fileName: mostRecent.fileName
        )
    }
    
    private func getAllWindows() async throws -> [VSCodeWindow] {
        var windows: [VSCodeWindow] = []
        
        for port in portRange {
            do {
                let window = try await getWindowContent(port: port)
                windows.append(window)
            } catch {
                continue
            }
        }
        
        guard !windows.isEmpty else {
            throw AccessibilityError.noActiveWindow
        }
        
        return windows
    }
    
    private func getWindowContent(port: Int) async throws -> VSCodeWindow {
        let url = URL(string: "http://127.0.0.1:\(port)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(VSCodeWindow.self, from: data)
    }
}

enum AccessibilityError: Error {
    case noActiveWindow
    case extractionFailed
}

class AccessibilityContentReader {
    private enum TextExtractionError: Error {
        case noTextFound
        case invalidHierarchy
    }
    
    static let shared = AccessibilityContentReader()
    
    private let supportedApps = [
        "com.apple.dt.Xcode",          // Xcode
        "com.googlecode.iterm2",       // iTerm2
        "com.apple.Terminal",          // Terminal
        "com.microsoft.VSCode"         // Visual Studio Code
    ]
    
    private init() {
        checkAccessibilityPermissions()
    }
    
    struct EditorContent {
        let fullText: String
        let selectedText: String?
        let applicationName: String?
        let bundleIdentifier: String?
        let applicationIcon: NSImage?
        
        var isSupported: Bool {
            guard let bundleId = bundleIdentifier else { return false }
            return AccessibilityContentReader.shared.supportedApps.contains(bundleId)
        }
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            NSLog("⚠️ Accessibility permissions not granted. Content reading features will not work.")
        }
    }
    
    func getActiveEditorContent() async -> EditorContent? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let windowElement = getFocusedWindow(for: app) else {
            return nil
        }
        
        async let icon = getApplicationIcon(for: app)
        
        if let bundleId = app.bundleIdentifier,
           supportedApps.contains(bundleId) {
            do {
                async let fullText = getFullText(from: windowElement)
                async let selectedText = getSelectedText(from: windowElement)
                
                return EditorContent(
                    fullText: (try await fullText) ?? "",
                    selectedText: await selectedText,
                    applicationName: app.localizedName,
                    bundleIdentifier: app.bundleIdentifier,
                    applicationIcon: await icon
                )
            } catch {
                print("Error getting editor content: \(error)")
                return nil
            }
        } else {
            return await EditorContent(
                fullText: "",
                selectedText: nil,
                applicationName: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                applicationIcon: icon
            )
        }
    }
    
    private func getApplicationIcon(for app: NSRunningApplication) -> NSImage? {
        if let icon = app.icon {
            return icon
        }
        
        if let bundleIdentifier = app.bundleIdentifier,
           let bundle = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let icon = NSWorkspace.shared.icon(forFile: bundle.path)
            return icon
        }
        return NSWorkspace.shared.icon(for: UTType.application)
    }
    
    private func getFocusedWindow(for app: NSRunningApplication) -> AXUIElement? {
        let appRef = AXUIElementCreateApplication(app.processIdentifier)
        var focusedWindow: CFTypeRef?
        
        guard AXUIElementCopyAttributeValue(appRef,
                                          kAXFocusedWindowAttribute as CFString,
                                          &focusedWindow) == .success else {
            return nil
        }
        
        return (focusedWindow as! AXUIElement)
    }
    
    private func getSelectedText(from element: AXUIElement) -> String? {
        if isTextInputElement(element) {
            var selectedText: CFTypeRef?
            if AXUIElementCopyAttributeValue(element,
                                           kAXSelectedTextAttribute as CFString,
                                           &selectedText) == .success,
               let text = selectedText as? String,
               !text.isEmpty {
                return text
            }
        }
        
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXChildrenAttribute as CFString,
                                          &children) == .success,
              let childrenArray = children as? [AXUIElement] else {
            return nil
        }
        
        for child in childrenArray {
            if let selected = getSelectedText(from: child) {
                return selected
            }
        }
        
        return nil
    }
    
    private func isTextInputElement(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXRoleAttribute as CFString,
                                          &role) == .success,
              let roleString = role as? String else {
            return false
        }
        
        return ["AXTextArea", "AXTextField", "AXTextInput", "AXComboBox"].contains(roleString)
    }
    
    private func getFullText(from element: AXUIElement) async throws -> String? {
        guard let bundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return nil
        }
        
        return try await extractTextForApp(bundleId: bundleId, from: element)
    }
    
    private func extractTextForApp(bundleId: String, from element: AXUIElement) async throws -> String {
        switch bundleId {
        case "com.apple.dt.Xcode":
            return try extractTextFromXcode(element)
        
        case "com.microsoft.VSCode":
            do {
                let content = try await VSCodeReader.shared.getActiveEditorContent()
                return content.content
            } catch {
                return try extractTextGeneric(element)
            }
            
        default:
            return try extractTextGeneric(element)
        }
    }
    
    private func extractTextFromXcode(_ element: AXUIElement) throws -> String {
        var role: CFTypeRef?
        var subrole: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
        let roleString = role as? String ?? "unknown"
        
        if roleString == "AXTextArea",
           let parent = getParentElement(of: element),
           let parentRole = getRole(of: parent),
           parentRole == "AXScrollArea" {
            
            if let value = getValue(from: element), !value.isEmpty {
                return value
            }
            
            var textValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, "AXValue" as CFString, &textValue) == .success,
               let text = textValue as? String,
               !text.isEmpty {
                return text
            }
        }
        
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXChildrenAttribute as CFString,
                                          &children) == .success,
              let childrenArray = children as? [AXUIElement] else {
            return ""
        }
        
        for child in childrenArray {
            if let result = try? extractTextFromXcode(child), !result.isEmpty {
                return result
            }
        }
        
        return ""
    }
    
    private func extractTextGeneric(_ element: AXUIElement) throws -> String {
        if isTextInputElement(element) {
            if let text = getValue(from: element), !text.isEmpty {
                return text
            }
        }
        return try searchChildrenForText(element)
    }
    
    private func searchChildrenForText(_ element: AXUIElement) throws -> String {
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXChildrenAttribute as CFString,
                                          &children) == .success,
              let childrenArray = children as? [AXUIElement] else {
            throw TextExtractionError.invalidHierarchy
        }
        
        var combinedText = ""
        for child in childrenArray {
            if let childText = try? extractTextGeneric(child) {
                combinedText += childText + " "
            }
        }
        
        if combinedText.isEmpty {
            throw TextExtractionError.noTextFound
        }
        
        return combinedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getValue(from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXValueAttribute as CFString,
                                          &value) == .success else {
            return nil
        }
        return value as? String
    }
    
    private func getParentElement(of element: AXUIElement) -> AXUIElement? {
        var parent: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXParentAttribute as CFString,
                                          &parent) == .success else {
            return nil
        }
        return (parent as! AXUIElement)
    }
    
    private func getRole(of element: AXUIElement) -> String? {
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXRoleAttribute as CFString,
                                          &role) == .success else {
            return nil
        }
        return role as? String
    }
}

class AccessibilityTextPaster {
    /// Singleton instance for shared access
    static let shared = AccessibilityTextPaster()
    
    private init() {
        // Check for accessibility permissions
        checkAccessibilityPermissions()
    }
    
    // MARK: - Public Interface
    
    /// Paste text to the currently focused text field
    /// - Parameter text: The text to paste
    /// - Returns: Bool indicating success
    @discardableResult
    func pasteText(_ text: String) -> Bool {
        // First try using the pasteboard - this is the most reliable method
        if pasteThroughPasteboard(text) {
            return true
        }
        
        // Fall back to accessibility API if pasteboard method fails
        return pasteThroughAccessibility(text)
    }
    
    // MARK: - Private Methods
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            NSLog("⚠️ Accessibility permissions not granted. Some features may not work.")
        }
    }
    /// Get the currently active application
    /// - Returns: NSRunningApplication? of the active app
    func getCurrentApplication() -> NSRunningApplication? {
        return NSWorkspace.shared.frontmostApplication
    }
    
    /// Get the bundle identifier of the currently active application
    /// - Returns: String? containing the bundle identifier
    func getCurrentApplicationBundleIdentifier() -> String? {
        return getCurrentApplication()?.bundleIdentifier
    }
    
    /// Get the localized name of the currently active application
    /// - Returns: String? containing the application name
    func getCurrentApplicationName() -> String? {
        return getCurrentApplication()?.localizedName
    }
    
    private func pasteThroughPasteboard(_ text: String) -> Bool {
        // Store current pasteboard contents
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        // Set new content
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Simulate Cmd+V
        if simulateCommandV() {
            // Wait a brief moment to ensure paste completes
            Thread.sleep(forTimeInterval: 0.1)
            
            // Restore old contents if needed
            if let oldContents = oldContents {
                pasteboard.clearContents()
                pasteboard.setString(oldContents, forType: .string)
            }
            
            return true
        }
        
        return false
    }
    
    private func pasteThroughAccessibility(_ text: String) -> Bool {
        guard let focusedElement = getFocusedTextElement() else {
            return false
        }
        
        // Try setting value directly first
        if setValueDirectly(text, for: focusedElement) {
            return true
        }
        
        // Fall back to simulating insertion
        return insertTextThroughAccessibility(text, in: focusedElement)
    }
    
    private func getFocusedTextElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        
        guard AXUIElementCopyAttributeValue(systemWide,
                                            kAXFocusedUIElementAttribute as CFString,
                                            &focusedElement) == .success else {
            return nil
        }
        
        let element = focusedElement as! AXUIElement
        
        // Check if element is directly a text element
        if isTextElement(element) {
            return element
        }
        
        // Search children for text element
        return findTextElement(in: element)
    }
    
    private func isTextElement(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                            kAXRoleAttribute as CFString,
                                            &role) == .success,
              let roleString = role as? String else {
            return false
        }
        
        return ["AXTextField", "AXTextArea", "AXComboBox"].contains(roleString)
    }
    
    private func findTextElement(in element: AXUIElement) -> AXUIElement? {
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                            kAXChildrenAttribute as CFString,
                                            &children) == .success,
              let childrenArray = children as? [AXUIElement] else {
            return nil
        }
        
        for child in childrenArray {
            if isTextElement(child) {
                return child
            }
            if let found = findTextElement(in: child) {
                return found
            }
        }
        
        return nil
    }
    
    private func setValueDirectly(_ text: String, for element: AXUIElement) -> Bool {
        let result = AXUIElementSetAttributeValue(element,
                                                  kAXValueAttribute as CFString,
                                                  text as CFTypeRef)
        return result == .success
    }
    
    private func insertTextThroughAccessibility(_ text: String, in element: AXUIElement) -> Bool {
        // First try to use AXInsertText if available
        var actions: CFArray?
        guard AXUIElementCopyActionNames(element, &actions) == .success,
              let actionNames = actions as? [String] else {
            return false
        }
        
        if actionNames.contains("AXInsertText") {
            return AXUIElementPerformAction(element, "AXInsertText" as CFString) == .success
        }
        
        return false
    }
    
    private func simulateCommandV() -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }
        
        guard let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            return false
        }
        
        vDown.flags = .maskCommand
        vUp.flags = .maskCommand
        
        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)
        
        return true
    }
}
