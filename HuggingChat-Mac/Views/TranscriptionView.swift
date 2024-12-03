//
//  TranscriptionView.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/11/24.
//

import SwiftUI

struct TranscriptionView: View {
    
    @Environment(AudioModelManager.self) private var audioModelManager
    @AppStorage("selectedAudioModel") private var selectedModel: String = "None"
    @AppStorage("selectedAudioInput") private var selectedAudioInput: String = "None"
    @AppStorage("streamTranscript") private var streamTranscript: Bool = false
    
    var barCount: Int = 6
    
    var body: some View {
        Color.red
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
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    
            }
        }
        .frame(width: 95, height: 30)
        .background {
            Capsule()
                .fill(.black)
        }
        
//        .onChange(of: audioModelManager.getFullTranscript()) {
//            AccessibilityTextPaster.pasteTextToFocusedElement(audioModelManager.getFullTranscript())
//        }
        
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
