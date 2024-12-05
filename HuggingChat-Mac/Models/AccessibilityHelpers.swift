//
//  AccessibilityHelpers.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/11/24.
//

import Cocoa
import ApplicationServices
import UniformTypeIdentifiers

class AccessibilityContentReader {
    static let shared = AccessibilityContentReader()
    
    private init() {
        checkAccessibilityPermissions()
    }
    
    struct EditorContent {
        let fullText: String
        let selectedText: String?
        let applicationName: String?
        let bundleIdentifier: String?
        let applicationIcon: NSImage?
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            NSLog("⚠️ Accessibility permissions not granted. Content reading features will not work.")
        }
    }
    
    func getActiveEditorContent() async -> EditorContent? {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self,
                  let app = NSWorkspace.shared.frontmostApplication,
                  let windowElement = self.getFocusedWindow(for: app) else {
                return nil
            }
            
            async let fullText = self.getFullText(from: windowElement)
            async let selectedText = self.getSelectedText(from: windowElement)
            async let icon = self.getApplicationIcon(for: app)
            
            let content = await EditorContent(
                fullText: fullText ?? "",
                selectedText: selectedText,
                applicationName: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                applicationIcon: icon
            )
            
            return content
        }.value
    }
    
    private func getApplicationIcon(for app: NSRunningApplication) -> NSImage? {
        // Try to get the icon directly from the running application
        if let icon = app.icon {
            return icon
        }
        
        // Fallback: Try to get the icon from the bundle
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
        // First check if this element has selected text
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
        
        // If not, search children
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element,
                                          kAXChildrenAttribute as CFString,
                                          &children) == .success,
              let childrenArray = children as? [AXUIElement] else {
            return nil
        }
        
        // Search all children recursively
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
    
    private func getFullText(from element: AXUIElement) -> String? {
//        // First check if this element has text value
//        if isTextInputElement(element) {
//            var value: CFTypeRef?
//            if AXUIElementCopyAttributeValue(element,
//                                           kAXValueAttribute as CFString,
//                                           &value) == .success,
//               let text = value as? String {
//                return text
//            }
//        }
//        
//        // If not, search children
//        var children: CFTypeRef?
//        guard AXUIElementCopyAttributeValue(element,
//                                          kAXChildrenAttribute as CFString,
//                                          &children) == .success,
//              let childrenArray = children as? [AXUIElement] else {
//            return nil
//        }
//        
//        // Search all children recursively
//        for child in childrenArray {
//            if let text = getFullText(from: child) {
//                return text
//            }
//        }
//        
        return nil
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
