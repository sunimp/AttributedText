//
//  UIView+Additionals.swift
//  AttributedText
//
//  Created by Sun on 2023/6/29.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

extension UIView {
    
    /// Shortcut for frame.origin.x.
    @objc var left: CGFloat {
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
    @objc var top: CGFloat {
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
    @objc var right: CGFloat {
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
    @objc var bottom: CGFloat {
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
    @objc var width: CGFloat {
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
    @objc var height: CGFloat {
        get {
            return frame.size.height
        }
        set {
            var frame: CGRect = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    /// Shortcut for center.x
    @objc var centerX: CGFloat {
        get {
            return center.x
        }
        set {
            center = CGPoint(x: newValue, y: center.y)
        }
    }
    
    /// Shortcut for center.y
    @objc var centerY: CGFloat {
        get {
            return center.y
        }
        set {
            center = CGPoint(x: center.x, y: newValue)
        }
    }
    
    /// Shortcut for frame.origin.
    @objc var origin: CGPoint {
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
    @objc var size: CGSize {
        get {
            return frame.size
        }
        set {
            var frame: CGRect = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }
    
    /**
     Shortcut to set the view.layer's shadow
     
     @param color  Shadow Color
     @param offset Shadow offset
     @param radius Shadow radius
     */
    @objc
    func setLayerShadow(_ color: UIColor?, offset: CGSize, radius: CGFloat) {
        if let aColor = color?.cgColor {
            layer.shadowColor = aColor
        }
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = 1
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    /**
     Remove all subviews.
     
     @warning Never call this method inside your view's drawRect: method.
     */
    @objc
    func removeAllSubviews() {
        while !subviews.isEmpty {
            subviews.last?.removeFromSuperview()
        }
    }
    
}
