//
//  URL+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/25/24.
//

import UniformTypeIdentifiers

extension URL {
    
    var mimeType: String {
        return UTType(filenameExtension: self.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
    
    func contains(_ uttype: UTType) -> Bool {
        return UTType(mimeType: self.mimeType)?.conforms(to: uttype) ?? false
    }

}
