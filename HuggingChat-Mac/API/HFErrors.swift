//
//  HFErrors.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import Foundation

enum HFError: Error {
    case unknown
    case fileLimitExceeded
    case genericError(Error)
    case networkError(Error)
    case httpError(Int, Data?)
    case verbose(String) // Only for debug purpose
    case modelNotFound
    case httpTooManyRequest
    case missingHFToken
    case httpUnauthorized
    case notHTTPResponse(URLResponse, Data?)
    case noResponse
    case decodeError(Error)
    case encodeError(Error)
}

extension HFError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknown:
            return "Unknown Error"
        case .fileLimitExceeded:
            return "File limit exceeded. A file cannot be larger than 10 MB."
        case .genericError(let error):
            return "Generic error \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code, let data):
            let info = "httpError code \(code)"
            if let data = data, let string = String(data: data, encoding: .utf8) {
                return "\(info) with content:\n\(string)"
            }
            return info
        case .verbose(let verbose):
            return "\(verbose)"
        case .modelNotFound:
            return "Model Not Found"
        case .httpTooManyRequest:
            return "Too Many Requests. Please try logging in."
        case .missingHFToken:
            return "Missing HF Token"
        case .httpUnauthorized:
            return "Unauthorized"
        case .notHTTPResponse(let response, let data):
            let info = "notHTTPResponse response \(response)"
            if let data = data, let string = String(data: data, encoding: .utf8) {
                return "\(info) with content:\n\(string)"
            }
            return info
        case .noResponse:
            return "No Response"
        case .decodeError(let error):
            return "decodeError \(error.localizedDescription)"
        case .encodeError(let error):
            return "encodeError \(error.localizedDescription)"
        }
    }
}

