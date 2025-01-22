//
//  Publisher+Extensions.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/22/25.
//

import Combine
import Foundation

extension Publisher {
    func toNetworkError() -> AnyPublisher<Output, HFError> {
        self.mapError { error in
            if let error = error as? HFError {
                return error
            } else {
                return HFError.unknown
            }
        }.eraseToAnyPublisher()
    }
}
