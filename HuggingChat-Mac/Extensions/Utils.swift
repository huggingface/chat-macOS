//
//  Utils.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/25/25.
//

import Foundation

infix operator .. : MultiplicationPrecedence

/**
 Custom operator that calls the specified block `self` value as its argument and returns `self`.

 Usage:

 self.backgroundView = UILabel()..{
 $0.backgroundColor = .red
 $0.textColor = .white
 $0.numberOfLines = 0
 }
 */

@discardableResult
public func .. <T>(object: T, block: (inout T) -> Void) -> T {
    var object = object
    block(&object)
    return object
}
