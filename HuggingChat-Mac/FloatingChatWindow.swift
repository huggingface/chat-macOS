//
//  FloatingPanel.swift
//  HuggingChat-Mac
//
//  Created by Cyril Zakka on 8/16/24.
//

import AppKit
import Foundation

class FloatingChatWindow: NSPanel, NSWindowDelegate {
    
    // Snapping window
    enum SnapPosition: Int {
        case bottomLeft = 1
        case bottomRight = 4
        case topLeft = 2
        case topRight = 3
    }
    
    /// Padding from edge of screen
    let padding: CGFloat = 10
    private var initialMouseOffset: NSPoint = .zero
    private var currentVelocity: NSPoint = .zero
    private var lastMousePosition: NSPoint = .zero
    private var lastUpdateTime: TimeInterval = 0
    var snapPosition: SnapPosition = .topRight
    
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable], backing: backing, defer: flag)
        self.delegate = self
        
        // Spotlight behavior
        self.setFrameAutosaveName("hfChatWindow")
        self.isFloatingPanel = true
        self.level = .floating
        
        self.collectionBehavior.insert(.fullScreenAuxiliary)
        self.collectionBehavior.insert(.canJoinAllSpaces)
        
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        self.isMovableByWindowBackground = true
        self.isReleasedWhenClosed = false
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = true
        //  Attachment shadows not updated when scrolling leading to artifact.
        // Should invalidate shadow on scroll. Set to false for now.
        // Shadow is set manually.
        
        // Animates but slightly slower
        //         self.animationBehavior = .utilityWindow
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    @objc func cancel(_ sender: Any?) {
        close()
    }
    
    override func resignMain() {
        super.resignMain()
    }
    
    func windowDidResignKey(_ notification: Notification) {
    }
    
}

//extension FloatingChatWindow {
//    override func mouseDragged(with event: NSEvent) {
//        
//        let currentTime = ProcessInfo.processInfo.systemUptime
//        let deltaTime = currentTime - lastUpdateTime
//        
//        if lastUpdateTime == 0 {
//            // First drag event
//            let mouseLocation = NSEvent.mouseLocation
//            initialMouseOffset = NSPoint(
//                x: mouseLocation.x - frame.minX,
//                y: mouseLocation.y - frame.minY
//            )
//        } else {
//            // Calculate velocity
//            let mouseLocation = NSEvent.mouseLocation
//            currentVelocity = NSPoint(
//                x: (mouseLocation.x - lastMousePosition.x) / CGFloat(deltaTime),
//                y: (mouseLocation.y - lastMousePosition.y) / CGFloat(deltaTime)
//            )
//            lastMousePosition = mouseLocation
//        }
//        
//        lastUpdateTime = currentTime
//        updateWindowPosition(with: NSEvent.mouseLocation)
//    }
//    
//    override func mouseUp(with event: NSEvent) {
//        
//        lastUpdateTime = 0
//        
//        guard let screen = NSScreen.main else { return }
//        
//        // Check if velocity is high enough to move
//        let velocityMagnitude = hypot(currentVelocity.x, currentVelocity.y)
//        let minVelocityThreshold: CGFloat = 300 // Increased threshold for movement
//        
//        if velocityMagnitude < minVelocityThreshold {
//            // If velocity is too low, snap back to original position
//            animateToPosition(snapPosition)
//            currentVelocity = .zero
//            return
//        }
//        
//        // Project where the window would end up based on velocity and deceleration
//        let projectedPoint = calculateProjectedPosition()
//        
//        // Calculate window center
//        let currentCenter = NSPoint(x: frame.midX, y: frame.midY)
//        
//        // Calculate movement vector
//        let movementVector = NSPoint(
//            x: projectedPoint.x - currentCenter.x,
//            y: projectedPoint.y - currentCenter.y
//        )
//        
//        // Find target edge based on projected position
//        let targetPosition = determineTargetPosition(
//            from: currentCenter,
//            projectedPoint: projectedPoint,
//            movementVector: movementVector,
//            screenFrame: screen.frame
//        )
//        
//        // Clamp velocity for animation
//        let maxVelocity: CGFloat = 2000
//        currentVelocity = NSPoint(
//            x: max(min(currentVelocity.x, maxVelocity), -maxVelocity),
//            y: max(min(currentVelocity.y, maxVelocity), -maxVelocity)
//        )
//        
//        animateToPosition(targetPosition)
//        currentVelocity = .zero
//    }
//    
//    private func determineTargetPosition(
//        from currentCenter: NSPoint,
//        projectedPoint: NSPoint,
//        movementVector: NSPoint,
//        screenFrame: NSRect
//    ) -> SnapPosition {
//        // Determine quadrant of projected position
//        let projectedOnLeft = projectedPoint.x < screenFrame.width / 2
//        let projectedOnTop = projectedPoint.y > screenFrame.height / 2
//        
//        // Calculate primary movement direction
//        let isHorizontalMovement = abs(movementVector.x) > abs(movementVector.y)
//        
//        // If movement is strongly diagonal (within 30% of 45 degrees), use pure projection
//        let movementRatio = abs(abs(movementVector.x) / abs(movementVector.y) - 1)
//        let isDiagonalMovement = movementRatio < 0.3
//        
//        if isDiagonalMovement {
//            // For diagonal movement, just use the projected quadrant
//            return projectedOnTop ?
//                (projectedOnLeft ? .topLeft : .topRight) :
//                (projectedOnLeft ? .bottomLeft : .bottomRight)
//        }
//        
//        // For primarily horizontal or vertical movement
//        if isHorizontalMovement {
//            let targetLeft = movementVector.x < 0
//            // Use the projected vertical position instead of current
//            return projectedOnTop ?
//                (targetLeft ? .topLeft : .topRight) :
//                (targetLeft ? .bottomLeft : .bottomRight)
//        } else {
//            let targetTop = movementVector.y > 0
//            // Use the projected horizontal position instead of current
//            return projectedOnLeft ?
//                (targetTop ? .topLeft : .bottomLeft) :
//                (targetTop ? .topRight : .bottomRight)
//        }
//    }
//    
//    private func calculateProjectedPosition() -> NSPoint {
//        let decelerationRate: CGFloat = 0.998
//        
//        let projectedX = frame.midX + projectFinalDistance(velocity: currentVelocity.x, decelerationRate: decelerationRate)
//        let projectedY = frame.midY + projectFinalDistance(velocity: currentVelocity.y, decelerationRate: decelerationRate)
//        
//        guard let screen = NSScreen.main else { return NSPoint(x: projectedX, y: projectedY) }
//        
//        let margin: CGFloat = frame.width / 2 + padding
//        return NSPoint(
//            x: min(max(projectedX, margin), screen.frame.width - margin),
//            y: min(max(projectedY, margin), screen.frame.height - margin)
//        )
//    }
//
//    private func projectFinalDistance(velocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
//        return velocity * decelerationRate / (1 - decelerationRate)
//    }
//    
//    private func updateWindowPosition(with mouseLocation: NSPoint) {
//        let newOrigin = NSPoint(
//            x: mouseLocation.x - initialMouseOffset.x,
//            y: mouseLocation.y - initialMouseOffset.y
//        )
//        setFrame(NSRect(origin: newOrigin, size: frame.size), display: true)
//    }
//    
//    private func nearestSnapPosition(to point: NSPoint) -> SnapPosition {
//        guard let screen = NSScreen.main else { return .topRight }
//        
//        let positions: [(SnapPosition, NSPoint)] = [
//            (.topLeft, NSPoint(x: padding, y: screen.frame.height - frame.height - padding)),
//            (.topRight, NSPoint(x: screen.frame.width - frame.width - padding, y: screen.frame.height - frame.height - padding)),
//            (.bottomLeft, NSPoint(x: padding, y: padding*4)),
//            (.bottomRight, NSPoint(x: screen.frame.width - frame.width - padding, y: padding*4))
//        ]
//        
//        // Weight the decision based on both distance and velocity direction
//        let nearest = positions.min(by: { (a, b) in
//            let distanceA = hypot(point.x - a.1.x, point.y - a.1.y)
//            let distanceB = hypot(point.x - b.1.x, point.y - b.1.y)
//            
//            // Add velocity bias - prefer positions in the direction of movement
//            let velocityBiasA = velocityBias(towards: a.1)
//            let velocityBiasB = velocityBias(towards: b.1)
//            
//            return (distanceA - velocityBiasA) < (distanceB - velocityBiasB)
//        })
//        
//        return nearest?.0 ?? .topRight
//    }
//    
//    private func velocityBias(towards point: NSPoint) -> CGFloat {
//        let deltaX = point.x - frame.minX
//        let deltaY = point.y - frame.minY
//        let distance = hypot(deltaX, deltaY)
//        
//        guard distance > 0 else { return 0 }
//        
//        let directionX = deltaX / distance
//        let directionY = deltaY / distance
//        
//        let velocityMagnitude = hypot(currentVelocity.x, currentVelocity.y)
//        if velocityMagnitude > 0 {
//            let normalizedVelocityX = currentVelocity.x / velocityMagnitude
//            let normalizedVelocityY = currentVelocity.y / velocityMagnitude
//            
//            // Reduce the velocity bias influence
//            let velocityBiasFactor: CGFloat = 50  // Reduced from 100
//            let alignment = (normalizedVelocityX * directionX + normalizedVelocityY * directionY)
//            return alignment * velocityBiasFactor
//        }
//        
//        return 0
//    }
//    
//    private func animateToPosition(_ position: SnapPosition) {
//        guard let screen = NSScreen.main else { return }
//        
//        let targetFrame: NSRect
//        switch position {
//        case .topLeft:
//            targetFrame = NSRect(
//                x: padding,
//                y: screen.frame.height - frame.height - padding,
//                width: frame.width,
//                height: frame.height
//            )
//        case .topRight:
//            targetFrame = NSRect(
//                x: screen.frame.width - frame.width - padding,
//                y: screen.frame.height - frame.height - padding,
//                width: frame.width,
//                height: frame.height
//            )
//        case .bottomLeft:
//            targetFrame = NSRect(
//                x: padding,
//                y: padding*4,
//                width: frame.width,
//                height: frame.height
//            )
//        case .bottomRight:
//            targetFrame = NSRect(
//                x: screen.frame.width - frame.width - padding,
//                y: padding*4,
//                width: frame.width,
//                height: frame.height
//            )
//        }
//        let velocityMagnitude = min(hypot(currentVelocity.x, currentVelocity.y), 1000)
//        
//        let baseDuration: TimeInterval = 0.4
//        let velocityDampingFactor: CGFloat = 0.3
//        let velocityFactor = min((velocityMagnitude * velocityDampingFactor) / 1000, 0.8) // Cap the minimum duration
//        let duration = baseDuration * (1.0 - velocityFactor)
//        
//        NSAnimationContext.runAnimationGroup { [weak self] context in
//            context.duration = max(duration, 0.15) // Ensure minimum animation duration
//            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
//            self?.animator().setFrame(targetFrame, display: true)
//        }
//        
//        snapPosition = position
//    }
//    
//    private func snapToFocusedPosition() {
//        guard let screen = NSScreen.main else { return }
//        
//        // Determine which side of the screen we're currently closer to
//        let isOnLeftSide = frame.midX < screen.frame.width / 2
//        let isOnTopHalf = frame.midY > screen.frame.height / 2
//        
//        // Get target position based on current location
//        let targetPosition: SnapPosition = isOnTopHalf ?
//            (isOnLeftSide ? .topLeft : .topRight) :
//            (isOnLeftSide ? .bottomLeft : .bottomRight)
//        
//        // Animate to position with a quick, smooth animation
//        NSAnimationContext.runAnimationGroup { [weak self] context in
//            context.duration = 0.3
//            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1.0)
//            self?.animator().setFrame(self?.frameFor(position: targetPosition) ?? .zero, display: true)
//        }
//        
//        snapPosition = targetPosition
//    }
//
//    // Helper method to get frame for position (to avoid code duplication)
//    private func frameFor(position: SnapPosition) -> NSRect {
//        guard let screen = NSScreen.main else { return .zero }
//        
//        switch position {
//        case .topLeft:
//            return NSRect(
//                x: padding,
//                y: screen.frame.height - frame.height - padding,
//                width: frame.width,
//                height: frame.height
//            )
//        case .topRight:
//            return NSRect(
//                x: screen.frame.width - frame.width - padding,
//                y: screen.frame.height - frame.height - padding,
//                width: frame.width,
//                height: frame.height
//            )
//        case .bottomLeft:
//            return NSRect(
//                x: padding,
//                y: padding,
//                width: frame.width,
//                height: frame.height
//            )
//        case .bottomRight:
//            return NSRect(
//                x: screen.frame.width - frame.width - padding,
//                y: padding,
//                width: frame.width,
//                height: frame.height
//            )
//        }
//    }
//}
