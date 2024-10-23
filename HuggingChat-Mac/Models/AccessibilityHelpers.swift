//
//  AccessibilityHelpers.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/11/24.
//

import Cocoa
import ApplicationServices

class AccessibilityTextPaster {
    
    private static var lastPastedLength: Int = 0
    
    private init() {}
    
    static func pasteTextToFocusedElement(_ text: String) {
        // Get the focused text field
        guard let focusedTextField = getFocusedTextField() else {
            print("No focused text field found")
            return
        }

        // Delete previous content
        deletePreviousContent(from: focusedTextField)

        // Copy the new text to pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Perform paste action
        performPasteAction(for: focusedTextField)

        // Update the last pasted length
        lastPastedLength = text.count
    }

    // MARK: - Focused element
    private static func getFocusedTextField() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard result == .success else {
            print("Failed to get focused element")
            return nil
        }

        // Check if the focused element is a text field
        if isTextField(focusedElement as! AXUIElement) {
            return (focusedElement as! AXUIElement)
        }

        // If not, search for a text field within the focused element
        return findTextFieldWithin(focusedElement as! AXUIElement)
    }

    private static func isTextField(_ element: AXUIElement) -> Bool {
        var role: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        
        guard result == .success,
              let roleString = role as? String
        else {
            return false
        }
        
        return roleString == "AXTextField" || roleString == "AXTextArea"
    }

    private static func findTextFieldWithin(_ element: AXUIElement) -> AXUIElement? {
        var children: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)
        
        guard result == .success,
              let childrenArray = children as? [AXUIElement]
        else {
            return nil
        }
        
        for child in childrenArray {
            if isTextField(child) {
                return child
            }
            if let textField = findTextFieldWithin(child) {
                return textField
            }
        }
        
        return nil
    }
    
    // MARK: - Text selection
    // TODO: Use AXTextMarkerForIndex instead?
    func getTextMarker(forIndex index: CFIndex) throws -> AXTextMarker? {
            var textMarker: AnyObject?
        guard AXUIElementCopyParameterizedAttributeValue(self as! AXUIElement,"AXTextMarkerForIndex" as CFString, index as AnyObject, &textMarker) == .success else { return nil }
        return (textMarker as! AXTextMarker)
    }

    func selectStaticText(withRange range: CFRange) throws {
            guard let textMarkerStart = try? getTextMarker(forIndex: range.location) else { return }
            guard let textMarkerEnd = try? getTextMarker(forIndex: range.location + range.length) else { return }
            let textMarkerRange = AXTextMarkerRangeCreate(kCFAllocatorDefault, textMarkerStart, textMarkerEnd)

        AXUIElementSetAttributeValue(self as! AXUIElement, "AXSelectedTextMarkerRange" as CFString, textMarkerRange)
    }
    
    private static func selectPreviousContent(in element: AXUIElement) {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        
        guard result == .success, let stringValue = value as? String else {
            print("Failed to get text value")
            return
        }
        
        let endLocation = stringValue.count
        let startLocation = max(0, endLocation - lastPastedLength)
        var range = CFRangeMake(startLocation, lastPastedLength)
        
        let rangeValue = AXValueCreate(.cfRange, &range)
        if let rangeValue = rangeValue {
            AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, rangeValue)
        } else {
            print("Failed to create AXValue for range")
        }
    }
    
    // MARK: - Text Deletion
    private static func deletePreviousContent(from element: AXUIElement) {
        if lastPastedLength > 0 {
            // Select the previous content
            selectPreviousContent(in: element)
            
            // Delete the selected content
            deleteSelectedContent(in: element)
        }
    }
    
    private static func deleteSelectedContent(in element: AXUIElement) {
        var actionNames: CFArray?
        AXUIElementCopyActionNames(element, &actionNames)
        
        if let actions = actionNames as? [String],
           actions.contains("AXDelete") {
            AXUIElementPerformAction(element, "AXDelete" as CFString)
        } else {
            print("Delete action not available for this element")
            simulateDeleteKey()
        }
    }
    
    // MARK: - Text Insertion
    private static func performPasteAction(for element: AXUIElement) {
        var actionNames: CFArray?
        AXUIElementCopyActionNames(element, &actionNames)
        
        if let actions = actionNames as? [String],
           actions.contains("AXPaste") {
            AXUIElementPerformAction(element, "AXPaste" as CFString)
        } else {
            print("Paste action not available for this element")
            simulateCommandV()
        }
    }
    
    
    // MARK: - Helper functions
    private static func simulateDeleteKey() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let deleteKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true)
        let deleteKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false)
        
        deleteKeyDown?.post(tap: .cghidEventTap)
        deleteKeyUp?.post(tap: .cghidEventTap)
    }
    
    private static func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        vKeyDown?.flags = .maskCommand
        vKeyUp?.flags = .maskCommand
        
        vKeyDown?.post(tap: .cghidEventTap)
        vKeyUp?.post(tap: .cghidEventTap)
    }
}
