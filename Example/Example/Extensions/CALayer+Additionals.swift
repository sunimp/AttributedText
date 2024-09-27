//
//  CALayer+Additionals.swift
//  AttributedText
//
//  Created by Sun on 2023/6/29.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

extension CALayer {
    
    /// Shortcut for frame.origin.x.
    var left: CGFloat {
        get {
            return frame.origin.x
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.origin.y
    var top: CGFloat {
        get {
            return frame.origin.y
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.origin.x + frame.size.width
    var right: CGFloat {
        get {
            return frame.origin.x + frame.size.width
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue - frame.size.width
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.origin.y + frame.size.height
    var bottom: CGFloat {
        get {
            return frame.origin.y + frame.size.height
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue - frame.size.height
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.size.width.
    var width: CGFloat {
        get {
            return frame.size.width
        }
        set {
            var frame: CGRect = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.size.height.
    var height: CGFloat {
        get {
            return frame.size.height
        }
        set {
            var frame: CGRect = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    /// Shortcut for center.
    var center: CGPoint {
        get {
            return CGPoint(
                x: frame.origin.x + frame.size.width * 0.5,
                y: frame.origin.y + frame.size.height * 0.5
            )
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue.x - frame.size.width * 0.5
            frame.origin.y = newValue.y - frame.size.height * 0.5
            self.frame = frame
        }
    }
    
    /// Shortcut for center.x
    var centerX: CGFloat {
        get {
            return frame.origin.x + frame.size.width * 0.5
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue - frame.size.width * 0.5
            self.frame = frame
        }
    }
    
    /// Shortcut for center.y
    var centerY: CGFloat {
        get {
            return frame.origin.y + frame.size.height * 0.5
        }
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue - frame.size.height * 0.5
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.origin.
    var origin: CGPoint {
        get {
            return frame.origin
        }
        set {
            var frame: CGRect = self.frame
            frame.origin = newValue
            self.frame = frame
        }
    }
    
    /// Shortcut for frame.size.
    var size: CGSize {
        get {
            return frame.size
        }
        set {
            var frame: CGRect = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }
    
    /// key path "tranform.rotation"
    var transformRotation: CGFloat {
        get {
            let value = self.value(forKeyPath: "transform.rotation") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.rotation")
        }
    }
    
    /// key path "tranform.rotation.x"
    var transformRotationX: CGFloat {
        get {
            let value = self.value(forKeyPath: "transform.rotation.x") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            self.setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.rotation.x")
        }
    }
    
    /// key path "tranform.rotation.y"
    var transformRotationY: CGFloat {
        get {
            let value = value(forKeyPath: "transform.rotation.y") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.rotation.y")
        }
    }
    
    /// key path "tranform.rotation.z"
    var transformRotationZ: CGFloat {
        get {
            let value = value(forKeyPath: "transform.rotation.z") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.rotation.z")
        }
    }
    
    /// key path "tranform.scale"
    var transformScale: CGFloat {
        get {
            let value = value(forKeyPath: "transform.scale") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.scale")
        }
    }
    
    /// key path "tranform.scale.x"
    var transformScaleX: CGFloat {
        get {
            let value = value(forKeyPath: "transform.scale.x") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.scale.x")
        }
    }
    
    /// key path "tranform.scale.y"
    var transformScaleY: CGFloat {
        get {
            let value = value(forKeyPath: "transform.scale.y") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.scale.y")
        }
    }
    
    /// key path "tranform.scale.z"
    var transformScaleZ: CGFloat {
        get {
            let value = value(forKeyPath: "transform.scale.z") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.scale.z")
        }
    }
    
    /// key path "tranform.translation.x"
    var transformTranslationX: CGFloat {
        get {
            let value = value(forKeyPath: "transform.translation.x") as? NSNumber
            return CGFloat(value?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.translation.x")
        }
    }
    
    /// key path "tranform.translation.y"
    var transformTranslationY: CGFloat {
        get {
            let newValue = value(forKeyPath: "transform.translation.y") as? NSNumber
            return CGFloat(newValue?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.translation.y")
        }
    }
    
    /// key path "tranform.translation.z"
    var transformTranslationZ: CGFloat {
        get {
            let newValue = value(forKeyPath: "transform.translation.z") as? NSNumber
            return CGFloat(newValue?.doubleValue ?? 0)
        }
        set {
            setValue(NSNumber(value: Float(newValue)), forKeyPath: "transform.translation.z")
        }
    }
    
    /**
     Shortcut for transform.m34, -1/1000 is a good value.
     It should be set before other transform shortcut.
     */
    var transformDepth: CGFloat {
        get {
            return self.transform.m34
        }
        set {
            var transform3D: CATransform3D = transform
            transform3D.m34 = newValue
            self.transform = transform3D
        }
    }
    /// Take snapshot without transform, image's size equals to bounds.
    func snapshotImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = self.isOpaque
        format.scale = 0
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
        return renderer.image { [weak self] context in
            guard let self else { return }
            self.render(in: context.cgContext)
        }
    }
    
    /// Take snapshot without transform, PDF's page size equals to bounds.
    func snapshotPDF() -> Data? {
        var bounds: CGRect = self.bounds
        let data = Data()
        // swiftlint:disable:next force_cast
        guard let consumer = CGDataConsumer(data: data as! CFMutableData) else {
            return nil
        }
        
        guard let context = CGContext(consumer: consumer, mediaBox: &bounds, nil) else {
            return nil
        }
        
        context.beginPDFPage(nil)
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1, y: -1)
        render(in: context)
        context.endPDFPage()
        context.closePDF()
        
        return data
    }
    
    ///
    /// Shortcut to set the layer's shadow
    ///
    /// - Parameters:
    /// - color: Shadow Color
    /// - offset: Shadow offset
    /// - radius: Shadow radius
    ///
    func setLayerShadow(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        if let CGColor = color?.cgColor {
            shadowColor = CGColor
        }
        shadowOffset = offset
        shadowRadius = radius
        shadowOpacity = 1
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale
    }
    
    /// Remove all sublayers.
    func removeAllSublayers() {
        while sublayers?.count ?? 0 > 0 {
            sublayers?.last?.removeFromSuperlayer()
        }
    }
    
    /**
     Add a fade animation to layer's contents when the contents is changed.
     
     @param duration Animation duration
     @param curve    Animation curve.
     */
    func addFadeAnimation(withDuration duration: TimeInterval, curve: UIView.AnimationCurve) {
        if duration <= 0 {
            return
        }
        
        var mediaFunction: CAMediaTimingFunctionName
        switch curve {
        case .easeInOut:
            mediaFunction = CAMediaTimingFunctionName.easeOut
        case .easeIn:
            mediaFunction = CAMediaTimingFunctionName.easeIn
        case .easeOut:
            mediaFunction = CAMediaTimingFunctionName.easeInEaseOut
        case .linear:
            mediaFunction = CAMediaTimingFunctionName.linear
        default:
            mediaFunction = CAMediaTimingFunctionName.linear
        }
        
        let transition = CATransition()
        transition.duration = CFTimeInterval(duration)
        transition.timingFunction = CAMediaTimingFunction(name: mediaFunction)
        transition.type = .fade
        add(transition, forKey: "AttributedText.fade")
    }
    
    /**
     Cancel fade animation which is added with "-addFadeAnimationWithDuration:curve:".
     */
    func removePreviousFadeAnimation() {
        removeAnimation(forKey: "AttributedText.fade")
    }
}
