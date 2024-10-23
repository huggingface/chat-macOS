//
//  AudioMeterIndicator.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/17/24.
//

import SwiftUI

struct AudioMeterIndicator: View {
    
    var bufferEnergy: [Float] = (0..<20).map { _ in 0 }
    var barCount: Int = 20
    let maxHeight: CGFloat = 24
    let barWidth: CGFloat = 3
    let cornerRadius: CGFloat = 2
    let spacing: CGFloat = 1
    
    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                bar(energy: normalizedEnergy(at: index))
            }
        }
        .frame(height: maxHeight)
    }
    
    private func bar(energy: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.green.gradient)
            .frame(width: barWidth, height: (0.1 + energy) * maxHeight, alignment: .center)
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: energy)
    }
    
    private func normalizedEnergy(at index: Int) -> CGFloat {
        guard index < bufferEnergy.count else { return 0 }
        return CGFloat(max(0, min(1, bufferEnergy[index])))
    }
}

#Preview {
    TranscriptionView()
        .environment(AudioModelManager())
}

