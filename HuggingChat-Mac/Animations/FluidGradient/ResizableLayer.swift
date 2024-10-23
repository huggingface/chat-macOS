//
//  ResizableLayer.swift
//  ResizableLayer
//
//  Created by João Gabriel Pozzobon dos Santos on 03/10/22.
//

import SwiftUI

/// An implementation of ``CALayer`` that resizes its sublayers
public class ResizableLayer: CALayer {
    override init() {
        super.init()
        #if os(OSX)
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        #endif
        sublayers = []
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSublayers() {
        super.layoutSublayers()
        sublayers?.forEach { layer in
            layer.frame = self.frame
        }
    }
}
