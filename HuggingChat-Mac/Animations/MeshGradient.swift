//
//  MeshGradient.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 9/5/24.
//

import SwiftUI

struct AnimatedMeshGradient: View {
    
    @State var colors: [Color] = [.blue, .purple, .indigo, .pink, .red,
                                  .mint, .teal,]
    
    @Binding var speed: CGFloat
    
    var body: some View {
        FluidGradient(blobs: colors,
                      highlights: [],
                      speed: speed, blur: 0.75)
//        .saturation(2)
    }
}


#Preview {
    AnimatedMeshGradient(speed: .constant(0.1))
}
