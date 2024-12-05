//
//  TranscriptionView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/11/24.
//

import SwiftUI

struct TranscriptionView: View {
    
    @Environment(ModelManager.self) private var modelManager
    @Environment(ConversationViewModel.self) private var conversationModel
    @Environment(AudioModelManager.self) private var audioModelManager
    
    @AppStorage("selectedAudioModel") private var selectedModel: String = "None"
    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = "None"
    @AppStorage("smartDictation") private var smartDictation: Bool = false
    @AppStorage("useLocalCleanup") private var useLocalCleanup: Bool = false
    
    var barCount: Int = 6
    
    var body: some View {
        ZStack {
            let baseEnergy = audioModelManager.bufferEnergy.last ?? 0
            let stridedValues = (0..<barCount).map { _ in
                let randomVariation = Float.random(in: -0.2...0.2)
                return baseEnergy > Float(audioModelManager.silenceThreshold) ? max(0, min(1, baseEnergy + randomVariation)) : max(0, min(1, baseEnergy))
            }
            HStack {
                AudioMeterIndicator(bufferEnergy: Array(stridedValues), barCount: barCount)
                Text(formatTime(audioModelManager.bufferSeconds))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
                    
            }
        }
        .frame(width: 95, height: 30)
        .background {
            Capsule()
                .fill(.thickMaterial)
        }
        .onChange(of: audioModelManager.isTranscriptionComplete) { old, new in
            if audioModelManager.isTranscriptionComplete && audioModelManager.transcriptionSource == .transcriptionView {
                let fullTranscript = audioModelManager.getFullTranscript()
//                if smartDictation {
//                    let currentAppName = AccessibilityTextPaster.shared.getCurrentApplicationName() ?? ""
//                    print(currentAppName)
//                    let directive = "Clean up and reformat the transcript to fit the context of the app \(currentAppName). Then paste the following text into the app:\(fullTranscript). Return only the new text. Nothing else."
//                    if useLocalCleanup {
//                        Task {
//                            await modelManager.generate(prompt: directive)
//                        }
//                    } else {
//                        conversationModel.sendAttributed(text: directive, withFiles: nil)
//                    }
//
//                } else {
                    if AccessibilityTextPaster.shared.pasteText(fullTranscript) {
                        print("Text pasted successfully")
                    } else {
                        print("Failed to paste text")
                    }
//                }
            }
        }
        
    }
    
    private func formatTime(_ seconds: Double) -> String {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            let seconds = Int(seconds) % 60
            
            if hours > 0 {
                return String(format: "%01d:%01d:%01d", hours, minutes, seconds)
            } else {
                return String(format: "%01d:%02d", minutes, seconds)
            }
        }
}

#Preview {
    TranscriptionView()
        .environment(AudioModelManager())
}
