//
//  NSVisualEffectView+Extension.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 1/21/25.
//

import Foundation
import SwiftUI

extension View {
    public static func semiOpaqueWindow(withStyle material: NSVisualEffectView.Material = .headerView) -> some View {
        VisualEffect(material: material).ignoresSafeArea()
    }
}

struct VisualEffect: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    
    init(material: NSVisualEffectView.Material = .headerView) {
        self.material = material
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }
    
    func updateNSView(_ view: NSVisualEffectView, context: Context) { }
}
