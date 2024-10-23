//
//  UTType+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/26/24.
//

import UniformTypeIdentifiers

extension UTType {
    static let mlpackage = UTType(filenameExtension: "mlpackage", conformingTo: .item)!
    static let mlmodelc = UTType(filenameExtension: "mlmodelc", conformingTo: .item)!
    static let gguf = UTType(filenameExtension: "gguf", conformingTo: .data)!
}


