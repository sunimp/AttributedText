//
//  UIView+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//

import UIKit

extension UIView {
    
    /// 可见的透明度
    var _visibleAlpha: CGFloat {
        if self is UIWindow {
            if self.isHidden {
                return 0
            }
            return self.alpha
        }
        if self.window == nil {
            return 0
        }
        var alpha: CGFloat = 1.0
        var view: UIView? = self
        while view != nil {
            guard let theView = view, !theView.isHidden else {
                alpha = 0
                break
            }
            alpha *= theView.alpha
            view = theView.superview
        }
        return alpha
    }
    
    func _viewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        repeat {
            nextResponder = nextResponder?.next
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
        } while nextResponder != nil
        return nil
    }
    
    /// 把一个 CGPoint 转换到一个 View 或 Window 上
    func _convert(_ point: CGPoint, to view: UIView?) -> CGPoint {
        var point = point
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(point, to: nil)
            }
            return self.convert(point, to: nil)
        }
        let from: UIWindow? = (self as? UIWindow) ?? self.window
        let to = (view as? UIWindow) ?? view.window
        if (from == nil || to == nil) || from == to {
            return self.convert(point, to: view)
        }
        point = self.convert(point, to: from)
        point = to?.convert(point, from: from) ?? .zero
        point = view.convert(point, from: to)
        return point
    }
    
    /// 从一个 View 或 Window 上转换一个 CGPoint
    func _convert(_ point: CGPoint, from view: UIView?) -> CGPoint {
        var point = point
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(point, from: nil)
            }
            return self.convert(point, from: nil)
        }
        let from = (view as? UIWindow) ?? view.window
        let to: UIWindow? = (self as? UIWindow) ?? self.window
        if (from == nil || to == nil) || from == to {
            return self.convert(point, from: view)
        }
        point = from?.convert(point, from: view) ?? .zero
        point = to?.convert(point, from: from) ?? .zero
        point = self.convert(point, from: to)
        return point
    }
    
    /// 把一个 CGRect 转换到一个 View 或 Window 上
    func _convert(_ rect: CGRect, to view: UIView?) -> CGRect {
        var rect = rect
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(rect, to: nil)
            }
            return self.convert(rect, to: nil)
        }
        let from: UIWindow? = (self as? UIWindow) ?? self.window
        let to = (view as? UIWindow) ?? view.window
        if from == nil || to == nil {
            return self.convert(rect, to: view)
        }
        if from == to {
            return self.convert(rect, to: view)
        }
        rect = self.convert(rect, to: from)
        rect = to?.convert(rect, from: from) ?? .zero
        rect = view.convert(rect, from: to)
        return rect
    }
    
    /// 从一个 View 或 Window 上转换一个 CGRect
    func _convert(_ rect: CGRect, from view: UIView?) -> CGRect {
        var rect = rect
        guard let view = view else {
            if let window = self as? UIWindow {
                return window.convert(rect, from: nil)
            }
            return self.convert(rect, from: nil)
        }
        let from = (view as? UIWindow) ?? view.window
        let to: UIWindow? = (self as? UIWindow) ?? self.window
        if (from == nil || to == nil) || from == to {
            return self.convert(rect, from: view)
        }
        rect = from?.convert(rect, from: view) ?? .zero
        rect = to?.convert(rect, from: from) ?? .zero
        rect = self.convert(rect, from: to)
        return rect
    }
}
