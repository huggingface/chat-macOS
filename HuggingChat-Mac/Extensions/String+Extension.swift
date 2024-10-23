//
//  String+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/23/24.
//

import Foundation

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
