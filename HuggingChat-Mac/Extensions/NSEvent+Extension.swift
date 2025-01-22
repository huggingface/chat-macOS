//
//  NSEvent+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import Foundation
import AppKit

extension NSEvent {
    var isRightClickUp: Bool {
        let rightClick = (self.type == .rightMouseUp)
        let controlClick = self.modifierFlags.contains(.control)
        return rightClick || controlClick
    }
}
