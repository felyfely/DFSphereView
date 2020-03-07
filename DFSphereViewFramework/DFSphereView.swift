//
//  DFSphereView.swift
//  sphereTagCloud
//
//  Modified by Dan Fu on 01/19/2020.
//  Copyright © 2020 Dan Fu. All rights reserved.
//

import UIKit
import simd

open class DFSphereView: UIView, UIGestureRecognizerDelegate {
    
    var tags = [UIView]()
    private var coordinate = [simd_double3]()
    var normalDirection: simd_double3 = vector3(0, 0, 0)
    private var last = CGPoint.zero
    
    var velocity: CGFloat = 0.0
    
    private var timer: CADisplayLink!
    private var inertia: CADisplayLink!
    
    
    /// setting the view array will also reset its viewtags by order
    public func setCloudTags(_ array: [UIView]) {
        array.forEach { (v) in
            addSubview(v)
        }
        tags = array
        for i in 0 ..< tags.count {
            let view = tags[i]
            view.tag = i
            view.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height / 2.0)
        }
        let p1 = .pi * (3 - sqrt(5))
        let p2 = 2.0 / Double(tags.count)
        for i in 0 ..< tags.count {
            let y: Double = p2 * Double(i) - 1 + (p2 / 2)
            let r: Double = sqrt(1 - y * y)
            let p3: Double = p1 * Double(i)
            let x: Double = cos(p3) * r
            let z: Double = sin(p3) * r
            
            let point = simd_double3(x: x, y: y, z: z)
            coordinate.append(point)
            
            let time = Double.random(in: 1 ..< 2)
            UIView.animate(withDuration: time, delay: 0.0, options: .curveEaseOut, animations: {() -> Void in
                self.setTagOf(point, andIndex: i)
            }, completion: {(_ finished: Bool) -> Void in
            })
        }
        
        let a = Double.random(in: -5 ..< 5)
        let b = Double.random(in: -5 ..< 5)
        normalDirection = simd_double3(x: Double(a), y: Double(b), z: 0)
        timerStart()
    }
    
    /// Starts the cloud autorotation animation.
    public func timerStart() {
        timer.isPaused = false
    }
    
    ///  Stops the cloud autorotation animation.
    public func timerStop() {
        timer.isPaused = true
    }

    private func setup() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.addGestureRecognizer(gesture)
        
        inertia = CADisplayLink(target: self, selector: #selector(inertiaStep))
        inertia.add(to: .main, forMode: RunLoop.Mode.default)
        
        timer  = CADisplayLink(target: self, selector: #selector(autoTurnRotation))
        timer.add(to: .main, forMode: RunLoop.Mode.default)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
        
    func updateFrameOfPoint(_ index: Int, direction: simd_double3, andAngle angle: CGFloat) {
        let point: simd_double3 = coordinate[index]
        let rPoint = rotateSphere(point: point, direction: direction, angle: angle)
        coordinate[index] = rPoint
        
        setTagOf(rPoint, andIndex: index)
    }
    
    func setTagOf(_ point: simd_double3, andIndex index: Int) {
        let view: UIView = tags[index]
        view.center = CGPoint(x: (point.x + 1) * Double(frame.size.width / 2.0), y: (point.y + 1) * Double(frame.size.height / 2.0))
        
        let transform: CGFloat = CGFloat((point.z + 2) / 3)
        view.transform = CGAffineTransform.identity.scaledBy(x: transform, y: transform)
        view.layer.zPosition = transform
        view.alpha = transform
        if point.z < 0 {
            view.isUserInteractionEnabled = false
        }
        else {
            view.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - autoTurnRotation
    
    @objc func autoTurnRotation() {
        for i in 0..<tags.count {
            updateFrameOfPoint(i, direction: normalDirection, andAngle: 0.002)
        }
    }
    
    // MARK: - inertia
    
    func inertiaStart() {
        timerStop()
        inertia.isPaused = false
    }
    
    func inertiaStop() {
        timerStart()
        inertia.isPaused = true
    }
    
    @objc func inertiaStep() {
        if velocity <= 0 {
            self.inertiaStop()
        }
        else {
            velocity -= 70.0
            let angle: CGFloat = velocity / frame.size.width * 2.0 * CGFloat(inertia.duration)
            for i in 0..<tags.count {
                updateFrameOfPoint(i, direction: normalDirection, andAngle: angle)
            }
        }
    }
        
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            last = gesture.location(in: self)
            timerStop()
            inertiaStop()
        }
        else if gesture.state == .changed {
            let current = gesture.location(in: self)
            let deltaY = Double(last.y - current.y)
            let deltaX = Double(current.x - last.x)
            let direction = simd_double3(x: deltaY, y: deltaX, z: 0)
            let distance: CGFloat = CGFloat(sqrt(direction.x * direction.x + direction.y * direction.y))
            let angle: CGFloat = distance / (frame.size.width / 2.0)
            for i in 0 ..< tags.count {
                updateFrameOfPoint(i, direction: direction, andAngle: angle)
            }
            normalDirection = direction
            last = current
        }
        else if gesture.state == .ended {
            let velocityP = gesture.velocity(in: self)
            velocity = sqrt(velocityP.x * velocityP.x + velocityP.y * velocityP.y)
            inertiaStart()
        }
        
    }
}

extension DFSphereView {
    fileprivate func rotateSphere(point: simd_double3, direction: simd_double3, angle: CGFloat) -> simd_double3 {
        if direction.x == 0 && direction.y == 0 && direction.z == 0 { return point }
        if angle == 0 { return point }
        let quaternion = simd_quatd(angle: Double(angle), axis: simd_normalize(direction))
        let rotatedVector = quaternion.act(point)
        return simd_double3(x: rotatedVector.x, y: rotatedVector.y, z: rotatedVector.z)
    }

}
