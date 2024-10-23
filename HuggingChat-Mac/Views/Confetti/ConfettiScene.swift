//
//  ConfettiScene.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/26/24.
//

import Foundation
import SpriteKit

class ConfettiScene: SKScene {
    /// Confetti emission duration in seconds.
    /// Duration for all confetto to fall isn't controllable. It's depends on confetto falling speed that are random.
    var emissionDuration: Double!
    
    // emission rate per seconds
    private let emissionRate = 120.0
    // max angle from straight down (270 degree) in radians
    private let maxDirectionAngle = Double.pi / 4
    private let colors = [SKColor(.red), SKColor(.purple), SKColor(.blue), SKColor(.yellow), SKColor(.green)]
    // debug mode
    private let debug = false
    // label for debug
    private var nodeCountLabel: SKLabelNode!
    
    // timer for emission
    private var emissionTimer: Timer?
    
    convenience init(size: CGSize, emissionDuration: Double) {
        self.init(size: size)
        self.emissionDuration = emissionDuration
    }
    
    // generate random confetti size
    private func randomSize() -> CGSize {
        let longSide = [18.0, 22.0, 25.0].randomElement()!
        let aspectRatio = [0.5, 0.4, 0.3].randomElement()!
        return CGSize(width: longSide, height: longSide * aspectRatio)
    }
    
    // generate random confetti direction
    private func randomDirection() -> Double {
        Double.random(in: (Double.pi * 1.5 - maxDirectionAngle) ... (Double.pi * 1.5 + maxDirectionAngle))
    }
    
    // generate random confetti rotation speed
    private func randomRotationSpeed() -> Double {
        Double.random(in: 0.3...4.0) * [-1, 1].randomElement()!
    }
    
    // generate random confetti scale speed
    private func randomScaleSpeed() -> Double {
        Double.random(in: 0.8...1.3)
    }
    
    // generate random confetti color
    private func randomColor() -> SKColor {
        colors.randomElement()!
    }
    
    // generage random confetti initial position
    private func randomInitialPosition(viewSize: CGSize) -> CGPoint {
        let maxXMovement = viewSize.height * sin(maxDirectionAngle)
        let x = Double.random(in: -maxXMovement ... (viewSize.width + maxXMovement))
        // FIXME: 固定値（10）ではなくノードの回転を考慮した取りうる最大高さを計算して足す
        let y = Double.random(in: (viewSize.height + 10) ... viewSize.height * 1.2)
        return CGPoint(x: x, y: y)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // remove fallen confetto
        for node in children {
            if node.position.y < -50 {
                node.removeAllActions()
                node.removeFromParent()
            }
        }
        
        // update label for debug
        if debug {
            nodeCountLabel.text = "confetti count: \(children.count - 1)"
        }
    }
    
    override func didMove(to view: SKView) {
        // make background transparent
        backgroundColor = .clear
        view.allowsTransparency = true
        view.scene?.backgroundColor = .clear
        
        // set confetti emission timer
        emissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / emissionRate, repeats: true) { timer in
            // create random confetti and add it to scene
            let confettiNode = self.createConfettiNode(
                color: self.randomColor(),
                size: self.randomSize(),
                direction: self.randomDirection(),
                rotationSpeedX: self.randomRotationSpeed(),
                rotationSpeedY: self.randomRotationSpeed(),
                rotationSpeedZ: self.randomRotationSpeed(),
                scaleSpeed: self.randomScaleSpeed())
            confettiNode.position = self.randomInitialPosition(viewSize: view.frame.size)
            self.addChild(confettiNode)
        }
        
        // finish emisison after `emissionDuration` sec
        Timer.scheduledTimer(withTimeInterval: emissionDuration, repeats: false) { timer in
            self.emissionTimer?.invalidate()
        }
        
        // put label for debug
        if debug {
            nodeCountLabel = SKLabelNode(text: "")
            nodeCountLabel.position = CGPoint(x: 50, y: 50)
            nodeCountLabel.fontColor = .blue
            addChild(nodeCountLabel)
        }
    }
    
    // create confetti node
    private func createConfettiNode(color: SKColor, size: CGSize, direction: Double,
                                    rotationSpeedX: Double, rotationSpeedY: Double, rotationSpeedZ: Double, scaleSpeed: Double) -> SKNode {
        
        let node = SKShapeNode(path: .init(rect: CGRect(origin: .zero, size: size), transform: nil), centered: true)
        node.fillColor = color
        node.strokeColor = .clear
        
        // wrapping node for x-rotation and y-rotation
        let transformNode = SKTransformNode()
        transformNode.addChild(node)
        
        // x-rotation action
        let rotationActionX = SKAction.customAction(withDuration: abs(rotationSpeedX)) { (node: SKNode, time: CGFloat) -> Void in
            (node as! SKTransformNode).xRotation = (time / rotationSpeedX) * 2 * CGFloat(Double.pi)
        }
        
        // y-rotation action
        let rotationActionY = SKAction.customAction(withDuration: abs(rotationSpeedY)) { (node: SKNode, time: CGFloat) -> Void in
            (node as! SKTransformNode).yRotation = (time / rotationSpeedY) * 2 * CGFloat(Double.pi)
        }
        
        // z-rotation action
        let rotationActionZ = SKAction.customAction(withDuration: abs(rotationSpeedZ)) { (node: SKNode, time: CGFloat) -> Void in
            (node as! SKTransformNode).zRotation = (time / rotationSpeedZ) * 2 * CGFloat(Double.pi)
        }
        
        // move action
        // biger(near) faster, smaller(far) slower
        let moveSpeed = pow(size.width, 1.2) * 8
        let moveAction = SKAction.move(by: CGVector(dx: cos(direction) * moveSpeed, dy: sin(direction) * moveSpeed), duration: 1.0)
        
        // scale action
        let scaleAction = SKAction.scale(by: scaleSpeed, duration: 1.0)
        
        // add actions to node
        transformNode.run(SKAction.repeatForever(rotationActionX))
        transformNode.run(SKAction.repeatForever(rotationActionY))
        transformNode.run(SKAction.repeatForever(rotationActionZ))
        transformNode.run(SKAction.repeatForever(moveAction))
        transformNode.run(SKAction.repeatForever(scaleAction))
        
        return transformNode
    }
}
