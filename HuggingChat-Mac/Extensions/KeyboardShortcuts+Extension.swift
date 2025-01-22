//
//  KeyboardShortcuts+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showChatBar = Self("showFloatingPanel", default: .init(.space, modifiers: [.command, .shift]))
}
