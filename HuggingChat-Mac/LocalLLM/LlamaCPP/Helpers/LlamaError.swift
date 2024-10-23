//
//  LlamaError.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 10/2/24.
//

import Foundation

public enum LlamaError: Error {
    case decoderError
    case couldNotInitializeContext
    case others(String)
}

extension LlamaError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .decoderError:
            return "Decoder error occurred during Llama model processing"
        case .couldNotInitializeContext:
            return "Failed to initialize Llama model context"
        case .others(let message):
            return "Llama error: \(message)"
        }
    }
}
