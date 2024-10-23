//
//  NSEvent+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/3/24.
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
