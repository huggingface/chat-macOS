//
//  StatusIndicatorView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/27/24.
//

import SwiftUI
import WhisperKit

struct StatusIndicatorView: View {
    
    var status: LocalModelState?
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
            case .noModel:
                return .gray
            case .loading:
                return .yellow
            case .generating, .ready:
                return .green
            case .failed, .error:
                return .red
            }
        } else if let audioState = audioState {
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
            case .noModel:
                return "No model selected"
            case .loading:
                return "Model is currently loading. Please wait..."
            case .ready(_), .generating(_):
                return "Model is ready for use."
            case .failed(let error):
                return "Model failed: \(error). Please try again or select a different model."
            case .error:
                return "There was an error. Please try again or select a different model."
            }
        } else if let audioState = audioState {
            return "Audio model state: \(audioState.description)"
        }
        return "Unknown state" // Default text if both status and audioState are nil
    }
}

#Preview {
    StatusIndicatorView(status: .noModel)
}
