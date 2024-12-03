//
//  StatusIndicatorView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/27/24.
//

import SwiftUI
import WhisperKit

struct StatusIndicatorView: View {
    
    var status: LoadState?
    var audioState: ModelState?

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .help(Text(helpText))
    }

    private var statusColor: Color {
        if let status = status {
            switch status {
            case .error(_):
                return .red
            case .idle:
                return .gray
            case .loaded:
                return .green
            }
        }
        else if let audioState = audioState {
            switch audioState {
            case .unloading, .unloaded:
                return .gray
            case .loading, .downloading, .prewarmed, .downloaded:
                return .gray
            case .loaded:
                return .green
            case .prewarming:
                return .orange
            }
        }
        return .gray
    }
    
    private var helpText: String {
        if let status = status {
            switch status {
            case .error(let error):
                return "Error: \(error)"
            case .idle:
                return "No model selected"
            case .loaded(_):
                return "Model is ready for use."
            }
        }
        else if let audioState = audioState {
            return "Audio model state: \(audioState.description)"
        }
        return "Unknown state" // Default text if both status and audioState are nil
    }
}

#Preview {
//    StatusIndicatorView(status: .noModel)
}
