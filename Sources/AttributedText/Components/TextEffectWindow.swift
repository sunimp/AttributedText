//
//  TextEffectWindow.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

/// `TextEffectWindow` default `rootViewController`
private final class TextEffectRootViewController: UIViewController {
    
    override var shouldAutorotate: Bool {
        return TextUtilities.topVC?.shouldAutorotate ?? false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return TextUtilities.topVC?.supportedInterfaceOrientations ?? .portrait
    }
}

/// A window to display magnifier and extra contents for text view.
///
/// Use `sharedWindow` to get the instance, don't create your own instance.
/// Typically, you should not use this class directly.
///
public class TextEffectWindow: UIWindow {
    private static var _sharedWindow: TextEffectWindow?
    
    private static var placeholderRect: CGRect = .zero
    private static var placeholder: UIImage = {
        placeholderRect.origin = .zero
        let format = UIGraphicsImageRendererFormat()
        format.scale = 0
        let renderer = UIGraphicsImageRenderer(size: placeholderRect.size, format: format)
        return renderer.image { context in
            UIColor(white: 1, alpha: 0.8).set()
            context.fill(placeholderRect)
        }
    }()
    
    /// Returns the shared instance (returns nil in App Extension).
    public static var shared: TextEffectWindow? {
        if let window = _sharedWindow {
            return window
        }
        if let scene = TextUtilities.windowScene {
            let one = TextEffectWindow(windowScene: scene)
            one.rootViewController = TextEffectRootViewController()
            one.frame = CGRect(origin: .zero, size: TextUtilities.screenSize)
            one.isUserInteractionEnabled = false
            one.windowLevel = UIWindow.Level(UIWindow.Level.statusBar.rawValue + 1)
            one.isHidden = false
            one.isOpaque = false
            one.backgroundColor = .clear
            one.layer.backgroundColor = UIColor.clear.cgColor
            _sharedWindow = one
        }
        return _sharedWindow
    }
    
    /// 当展示出放大镜时的事件
    public static var actionWhenShowMagnifier: (() -> Void)?
    
    override public var rootViewController: UIViewController? {
        get {
            guard TextUtilities.windowScene?.windows != nil else {
                return nil
            }
            return super.rootViewController
        }
        set {
            super.rootViewController = newValue
        }
    }
    
    /// Show the magnifier in this window with a 'popup' animation.
    ///
    /// - Parameters:
    ///     - magnifier: A magnifier.
    public func show(_ magnifier: TextMagnifier?) {
        guard let mag = magnifier else {
            return
        }
        if mag.superview != self {
            addSubview(mag)
        }
        Self.actionWhenShowMagnifier?()
        _updateWindowLevel()
        let rotation = _update(magnifier: mag)
        let center: CGPoint = self._convert(mag.hostPopoverCenter, from: mag.hostView)
        var transform = CGAffineTransform(rotationAngle: rotation)
        transform = transform.scaledBy(x: 0.3, y: 0.3)
        mag.transform = transform
        mag.center = center
        let time: TimeInterval = 0.08
        UIView.animate(
            withDuration: time,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
            animations: {
                var newCenter = CGPoint(x: 0, y: -mag.fitSize.height * 0.85)
                newCenter = newCenter.applying(CGAffineTransform(rotationAngle: rotation))
                newCenter.x += center.x
                newCenter.y += center.y
                mag.center = self._corrected(center: newCenter, for: mag, rotation: rotation)
                mag.transform = CGAffineTransform(rotationAngle: rotation)
                mag.alpha = 1
            }
        )
    }
    
    /// Update the magnifier content and position.
    ///
    /// - Parameters:
    ///     - magnifier: A magnifier.
    public func move(_ magnifier: TextMagnifier?) {
        guard let mag = magnifier else {
            return
        }
        self._updateWindowLevel()
        let rotation = self._update(magnifier: mag)
        let center: CGPoint = self._convert(mag.hostPopoverCenter, from: mag.hostView)
        var newCenter = CGPoint(x: 0, y: -mag.fitSize.height * 0.85)
        newCenter = newCenter.applying(CGAffineTransform(rotationAngle: rotation))
        newCenter.x += center.x
        newCenter.y += center.y
        mag.center = self._corrected(center: newCenter, for: mag, rotation: rotation)
        mag.transform = CGAffineTransform(rotationAngle: rotation)
    }
    
    /// Remove the magnifier from this window with a 'shrink' animation.
    ///
    /// - Parameters:
    ///     - magnifier: A magnifier.
    public func hide(_ magnifier: TextMagnifier?) {
        guard let mag = magnifier else {
            return
        }
        if mag.superview != self {
            return
        }
        let rotation = _update(magnifier: mag)
        let center: CGPoint = _convert(mag.hostPopoverCenter, from: mag.hostView)
        let time: TimeInterval = 0.20
        UIView.animate(
            withDuration: time,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
            animations: {
                var trans = CGAffineTransform(rotationAngle: rotation)
                trans = trans.scaledBy(x: 0.01, y: 0.01)
                mag.transform = trans
                var newCenter: CGPoint = .zero
                newCenter = newCenter.applying(CGAffineTransform(rotationAngle: rotation))
                newCenter.x += center.x
                newCenter.y += center.y
                mag.center = self._corrected(center: newCenter, for: mag, rotation: rotation)
            }
        ) { finished in
            if finished {
                mag.removeFromSuperview()
                mag.transform = CGAffineTransform.identity
                mag.alpha = 1
            }
        }
    }
    
    /// Show the selection dot in this window if the dot is clipped by the selection view.
    ///
    /// - Parameters:
    ///     - selectionDot: A selection view.
    ///
    public func show(selectionDot: TextSelectionView?) {
        guard let selection = selectionDot else {
            return
        }
        _updateWindowLevel()
        let aMirror = selection.startGrabber.dot.mirror
        insertSubview(aMirror, at: 0)
        
        let eMirror = selection.endGrabber.dot.mirror
        insertSubview(eMirror, at: 0)
        
        _update(dot: selection.startGrabber.dot, selection: selection)
        _update(dot: selection.endGrabber.dot, selection: selection)
    }
    
    /// Remove the selection dot from this window.
    ///
    /// - Parameters:
    ///     - selectionDot: A selection view.
    public func hide(selectionDot: TextSelectionView?) {
        guard let selection = selectionDot else {
            return
        }
        selection.startGrabber.dot.mirror.removeFromSuperview()
        selection.endGrabber.dot.mirror.removeFromSuperview()
    }
    
    // stop self from becoming the KeyWindow
    override public func becomeKey() {
        guard let delegate = TextUtilities.windowScene?.delegate as? UIWindowSceneDelegate else {
            return
        }
        delegate.window??.makeKey()
    }
    
    // Bring self to front
    private func _updateWindowLevel() {
        guard let scene = TextUtilities.windowScene else {
            return
        }
        var top = scene.windows.last
        let key = TextUtilities.keyWindow
        if let aLevel = key?.windowLevel, let aLevel1 = top?.windowLevel {
            if key != nil, aLevel > aLevel1 {
                top = key
            }
        }
        if top == self {
            return
        }
        windowLevel = UIWindow.Level((top?.windowLevel.rawValue ?? 0) + 1)
    }
    
    private func _keyboardDirection() -> TextDirection {
        var keyboardFrame: CGRect = TextKeyboardManager.default.keyboardFrame
        keyboardFrame = TextKeyboardManager.default.convert(keyboardFrame, to: self)
        if keyboardFrame.isNull || keyboardFrame.isEmpty {
            return TextDirection.none
        }
        if keyboardFrame.minY == 0, keyboardFrame.minX == 0, keyboardFrame.maxX == frame.width {
            return TextDirection.top
        }
        if keyboardFrame.maxX == frame.width, keyboardFrame.minY == 0, keyboardFrame.maxY == frame.height {
            return TextDirection.right
        }
        if keyboardFrame.maxY == frame.height, keyboardFrame.minX == 0, keyboardFrame.maxX == frame.width {
            return TextDirection.bottom
        }
        if keyboardFrame.minX == 0, keyboardFrame.minY == 0, keyboardFrame.maxY == frame.height {
            return TextDirection.left
        }
        return TextDirection.none
    }
    
    private func _corrected(captureCenter center: CGPoint) -> CGPoint {
        var center = center
        var keyboardFrame: CGRect = TextKeyboardManager.default.keyboardFrame
        keyboardFrame = TextKeyboardManager.default.convert(keyboardFrame, to: self)
        if !keyboardFrame.isNull, !keyboardFrame.isEmpty {
            let direction: TextDirection = _keyboardDirection()
            switch direction {
            case TextDirection.top:
                if center.y < keyboardFrame.maxY {
                    center.y = keyboardFrame.maxY
                }
            case TextDirection.right:
                if center.x > keyboardFrame.minX {
                    center.x = keyboardFrame.minX
                }
            case TextDirection.bottom:
                if center.y > keyboardFrame.minY {
                    center.y = keyboardFrame.minY
                }
            case TextDirection.left:
                if center.x < keyboardFrame.maxX {
                    center.x = keyboardFrame.maxX
                }
            default:
                break
            }
        }
        return center
    }
    
    private func _corrected(center: CGPoint, for mag: TextMagnifier, rotation: CGFloat) -> CGPoint {
        var center = center
        var degree = rotation.toDegrees()
        degree /= 45.0
        if degree < 0 {
            degree += CGFloat(Int(-degree / 8.0 + 1) * 8)
        }
        if degree > 8 {
            degree -= CGFloat(Int(degree / 8.0) * 8)
        }
        let caretExt: CGFloat = 10
        if degree <= 1 || degree >= 7 {
            // top
            if center.y < caretExt {
                center.y = caretExt
            }
        } else if degree > 1, degree < 3 {
            // right
            if center.x > bounds.size.width - caretExt {
                center.x = bounds.size.width - caretExt
            }
        } else if degree >= 3, degree <= 5 {
            // bottom
            if center.y > bounds.size.height - caretExt {
                center.y = bounds.size.height - caretExt
            }
        } else if degree > 5, degree < 7 {
            // left
            if center.x < caretExt {
                center.x = caretExt
            }
        }
        
        var keyboardFrame: CGRect = TextKeyboardManager.default.keyboardFrame
        keyboardFrame = TextKeyboardManager.default.convert(keyboardFrame, to: self)
        if !keyboardFrame.isNull, !keyboardFrame.isEmpty {
            let direction: TextDirection = _keyboardDirection()
            switch direction {
            case TextDirection.top:
                if center.y - mag.bounds.size.height / 2 < keyboardFrame.maxY {
                    center.y = keyboardFrame.maxY + mag.bounds.size.height / 2
                }
            case TextDirection.right:
                if center.x + mag.bounds.size.height / 2 > keyboardFrame.minX {
                    center.x = keyboardFrame.minX - mag.bounds.size.width / 2
                }
            case TextDirection.bottom:
                if center.y + mag.bounds.size.height / 2 > keyboardFrame.minY {
                    center.y = keyboardFrame.minY - mag.bounds.size.height / 2
                }
            case TextDirection.left:
                if center.x - mag.bounds.size.height / 2 < keyboardFrame.maxX {
                    center.x = keyboardFrame.maxX + mag.bounds.size.width / 2
                }
            default:
                break
            }
        }
        
        return center
    }
    
    /// Capture screen snapshot and set it to magnifier.
    ///
    /// - Parameters:
    ///     - magnifier: A magnifier.
    ///
    /// - Returns: Magnifier rotation radius.
    private func _update(magnifier mag: TextMagnifier) -> CGFloat {
        guard let scene = TextUtilities.windowScene else {
            return 0
        }
        let hostView: UIView? = mag.hostView
        let hostWindow = (hostView is UIWindow) ? (hostView as? UIWindow) : hostView?.window
        if hostView == nil || hostWindow == nil {
            return 0
        }
        var captureCenter: CGPoint = self._convert(mag.hostCaptureCenter, from: hostView)
        captureCenter = _corrected(captureCenter: captureCenter)
        var captureRect = CGRect()
        captureRect.size = mag.snapshotSize
        captureRect.origin.x = captureCenter.x - captureRect.size.width / 2
        captureRect.origin.y = captureCenter.y - captureRect.size.height / 2
        let trans: CGAffineTransform = TextUtilities.affineTransform(from: hostView, to: self)
        let rotation: CGFloat = trans.rotation()
        if mag.isCaptureDisabled {
            if mag.snapshot == nil || (mag.snapshot?.size.width ?? 0) > 1 {
                Self.placeholderRect = mag.bounds
                
                mag.isCaptureFadeAnimation = true
                mag.snapshot = Self.placeholder
                mag.isCaptureFadeAnimation = false
            }
            return rotation
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 0
        let renderer = UIGraphicsImageRenderer(size: captureRect.size, format: format)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            var tp = CGPoint(x: captureRect.size.width / 2, y: captureRect.size.height / 2)
            tp = tp.applying(CGAffineTransform(rotationAngle: rotation))
            cgContext.rotate(by: -rotation)
            cgContext.translateBy(x: tp.x - captureCenter.x, y: tp.y - captureCenter.y)
            var windows = scene.windows
            if let aWindow = TextUtilities.keyWindow {
                if !windows.contains(aWindow) {
                    windows.append(aWindow)
                }
            }
            windows.sort { w1, w2 in
                if w1.windowLevel < w2.windowLevel {
                    return true
                } else if w1.windowLevel > w2.windowLevel {
                    return false
                }
                return true
            }
 
            let mainScreen = UIScreen.main
            for window in windows {
                if window.isHidden || window.alpha <= 0.01 {
                    continue
                }
                if window.screen != mainScreen {
                    continue
                }
                if window.isKind(of: type(of: self)) {
                    break // don't capture window above self
                }
                cgContext.saveGState()
                cgContext.concatenate(TextUtilities.affineTransform(from: window, to: self))
                window.layer.render(in: cgContext)
                cgContext.restoreGState()
            }
        }
        
        if let snapshot = mag.snapshot, snapshot.size.width == 1 {
            mag.isCaptureFadeAnimation = true
        }
        mag.snapshot = image
        mag.isCaptureFadeAnimation = false
        return rotation
    }
    
    private func _update(dot: SelectionGrabberDot, selection: TextSelectionView) {
        dot.mirror.isHidden = true
        if selection.hostView?.clipsToBounds == true && dot._visibleAlpha > 0.1 {
            let dotRect = dot._convert(dot.bounds, to: self)
            var dotInKeyboard = false
            var keyboardFrame: CGRect = TextKeyboardManager.default.keyboardFrame
            keyboardFrame = TextKeyboardManager.default.convert(keyboardFrame, to: self)
            if !keyboardFrame.isNull, !keyboardFrame.isEmpty {
                let inter: CGRect = dotRect.intersection(keyboardFrame)
                if !inter.isNull, inter.size.width > 1 || inter.size.height > 1 {
                    dotInKeyboard = true
                }
            }
            if !dotInKeyboard, let hostView = selection.hostView {
                let hostRect = hostView.convert(hostView.bounds, to: self)
                let intersection: CGRect = dotRect.intersection(hostRect)
                if intersection.getArea() < dotRect.getArea() {
                    let dist = CGPoint(x: dotRect.midX, y: dotRect.midY).distance(toRect: hostRect)
                    if dist < dot.frame.width * 0.55 {
                        dot.mirror.isHidden = false
                    }
                }
            }
        }
        let center = dot._convert(CGPoint(x: dot.frame.width / 2, y: dot.frame.height / 2), to: self)
        if center.x.isNaN || center.y.isNaN || center.x.isInfinite || center.y.isInfinite {
            dot.mirror.isHidden = true
        } else {
            dot.mirror.center = center
        }
    }
}
