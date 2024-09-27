//
//  TextKeyboardManager.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

private var textKeyboardViewFrameObserverKey: Int = 0

/// Observer for view's frame/bounds/center/transform
private class TextKeyboardViewFrameObserver: NSObject {
    
    private var keyboardView: UIView?
    var notifyBlock: ((_ keyboard: UIView?) -> Void)?
    
    /// 静态构造方法
    static func observerForView(_ keyboardView: UIView) -> TextKeyboardViewFrameObserver? {
        let view = keyboardView
        return objc_getAssociatedObject(view, &textKeyboardViewFrameObserverKey) as? Self
    }
    
    /// 添加
    func addTo(keyboardView: UIView?) {
        if self.keyboardView == keyboardView {
            return
        }
        if let keyboardView = self.keyboardView {
            removeFrameObserver()
            objc_setAssociatedObject(
                keyboardView,
                &textKeyboardViewFrameObserverKey,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
        self.keyboardView = keyboardView
        if let keyboardView = keyboardView {
            addFrameObserver()
            objc_setAssociatedObject(
                keyboardView,
                &textKeyboardViewFrameObserverKey,
                self,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    // swiftlint:disable:next block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        let isPrior: Bool = ((change?[.notificationIsPriorKey] as? Int) != 0)
        if isPrior {
            return
        }
        let changeKind = NSKeyValueChange(rawValue: UInt((change?[.kindKey] as? Int) ?? 0))
        if changeKind != .setting {
            return
        }
        var newVal = change?[.newKey]
        if (newVal as? NSNull) == NSNull() {
            newVal = nil
        }
        notifyBlock?(keyboardView)
    }
    
    private func addFrameObserver() {
        if keyboardView == nil {
            return
        }
        keyboardView?.addObserver(self, forKeyPath: "frame", options: [], context: nil)
        keyboardView?.addObserver(self, forKeyPath: "center", options: [], context: nil)
        keyboardView?.addObserver(self, forKeyPath: "bounds", options: [], context: nil)
        keyboardView?.addObserver(self, forKeyPath: "transform", options: [], context: nil)
    }
    
    private func removeFrameObserver() {
        keyboardView?.removeObserver(self, forKeyPath: "frame")
        keyboardView?.removeObserver(self, forKeyPath: "center")
        keyboardView?.removeObserver(self, forKeyPath: "bounds")
        keyboardView?.removeObserver(self, forKeyPath: "transform")
        keyboardView = nil
    }
    
    deinit {
        removeFrameObserver()
    }
}

/// The TextKeyboardObserver protocol defines the method you can use
/// to receive system keyboard change information.
@objc
public protocol TextKeyboardObserver: NSObjectProtocol {
    @objc
    optional func keyboardChanged(with transition: TextKeyboardTransition)
}

/// System keyboard transition information.
///
/// Use -[TextKeyboardManager convertRect:toView:] to convert frame to specified view.
public class TextKeyboardTransition: NSObject {
    /// Keyboard visible before transition.
    public var fromVisible: Bool = false
    
    /// Keyboard visible after transition.
    public var toVisible: Bool = false
    
    /// Keyboard frame before transition.
    public var fromFrame: CGRect = .zero
    
    /// Keyboard frame after transition.
    public var toFrame: CGRect = .zero
    
    /// Keyboard transition animation duration.
    public var animationDuration: TimeInterval = 0
    
    /// Keyboard transition animation curve.
    public var animationCurve: UIView.AnimationCurve = .easeInOut
    
    /// Keybaord transition animation option.
    public var animationOption: UIView.AnimationOptions = .layoutSubviews
}

/// A TextKeyboardManager object lets you get the system keyboard information,
/// and track the keyboard visible/frame/transition.
///
/// You should access this class in main thread.
public class TextKeyboardManager: NSObject {
    /// Get the default manager (returns nil in App Extension).
    public static let `default` = TextKeyboardManager()
    
    /// Get the keyboard window. nil if there's no keyboard window.
    public var keyboardWindow: UIWindow? {
        guard let windowScene = TextUtilities.windowScene else {
            return nil
        }
        
        for window in windowScene.windows where _getKeyboardView(from: window) != nil {
            return window
        }
        let window = TextUtilities.keyWindow
        if _getKeyboardView(from: window) != nil {
            return window
        }
        var kbWindows = [UIWindow]()
        for window in windowScene.windows {
            let windowName = NSStringFromClass(type(of: window))
            // UIRemoteKeyboardWindow
            if windowName.length == 22, windowName.hasPrefix("UI"), windowName.hasSuffix("RemoteKeyboardWindow") {
                kbWindows.append(window)
            }
        }
        if kbWindows.count == 1 {
            return kbWindows.first
        }
        return nil
    }
    
    /// Get the keyboard view. nil if there's no keyboard view.
    public var keyboardView: UIView? {
        guard let windowScene = TextUtilities.windowScene else {
            return nil
        }
        var window: UIWindow?
        var view: UIView?
        for window in windowScene.windows {
            view = _getKeyboardView(from: window)
            if view != nil {
                return view
            }
        }
        window = TextUtilities.keyWindow
        view = _getKeyboardView(from: window)
        if view != nil {
            return view
        }
        return nil
    }
    
    /// Whether the keyboard is visible.
    public var keyboardVisible: Bool {
        guard let window = keyboardWindow else {
            return false
        }
        
        guard let view = keyboardView else {
            return false
        }
        let rect: CGRect = window.bounds.intersection(view.frame)
        if rect.isNull {
            return false
        }
        if rect.isInfinite {
            return false
        }
        return rect.size.width > 0 && rect.size.height > 0
    }
    
    /// Get the keyboard frame. CGRectNull if there's no keyboard view.
    /// Use convertRect:toView: to convert frame to specified view.
    public var keyboardFrame: CGRect {
        guard let keyboard = keyboardView else {
            return CGRect.null
        }
        var frame = CGRect.null
        
        if let window = keyboard.window {
            frame = window.convert(keyboard.frame, to: nil)
        } else {
            frame = keyboard.frame
        }
        return frame
    }
    
    private var observers: NSHashTable<TextKeyboardObserver>
    private var fromFrame = CGRect.zero
    private var fromVisible = false
    private var notificationFromFrame = CGRect.zero
    private var notificationToFrame = CGRect.zero
    private var notificationDuration: TimeInterval = 0
    private var notificationCurve = UIView.AnimationCurve.linear
    private var hasNotification = false
    private var observedToFrame = CGRect.zero
    private var hasObservedChange = false
    private var lastIsNotification = false
    
    override private init() {
        self.observers = NSHashTable<TextKeyboardObserver>(
            options: [.weakMemory, .objectPointerPersonality],
            capacity: 0
        )
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardFrameWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_keyboardFrameDidChange(_:)),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }
   
    /// 开始管理
    public static func startManager() {
        _ = `default`
    }
    
    private func _initFrameObserver() {
        guard let keyboardView = keyboardView else {
            return
        }
        var observer: TextKeyboardViewFrameObserver? = TextKeyboardViewFrameObserver.observerForView(keyboardView)
        if observer == nil {
            observer = TextKeyboardViewFrameObserver()
            observer?.notifyBlock = { [weak self] keyboard in
                guard let self else { return }
                self._keyboardFrameChanged(keyboard)
            }
            observer?.addTo(keyboardView: keyboardView)
        }
    }
    
    /// Add an observer to manager to get keyboard change information.
    /// This method makes a weak reference to the observer.
    ///
    /// - Parameters:
    ///     - observer: An observer.
    /// This method will do nothing if the observer is nil, or already added.
    public func add(observer: TextKeyboardObserver?) {
        guard let observer = observer else {
            return
        }
        self.observers.add(observer)
    }
    
    /// Remove an observer from manager.
    ///
    /// - Parameters:
    ///     - observer: An observer.
    /// This method will do nothing if the observer is nil, or not in manager.
    public func remove(observer: TextKeyboardObserver?) {
        guard let observer = observer else {
            return
        }
        self.observers.remove(observer)
    }
    
    private func _getKeyboardView(from window: UIWindow?) -> UIView? {
        /// UIRemoteKeyboardWindow
        /// UIInputSetContainerView
        /// UIInputSetHostView << keyboard
        guard let window = window else {
            return nil
        }
        // Get the window
        let windowName = NSStringFromClass(type(of: window))
        // UIRemoteKeyboardWindow
        if windowName.length != 22 {
            return nil
        }
        if !windowName.hasPrefix("UI") {
            return nil
        }
        if !windowName.hasSuffix("RemoteKeyboardWindow") {
            return nil
        }
        
        // Get the view
        // UIInputSetContainerView
        for view in window.subviews {
            let viewName = NSStringFromClass(type(of: view))
            if viewName.length != 23 {
                continue
            }
            if !viewName.hasPrefix("UI") {
                continue
            }
            if !viewName.hasSuffix("InputSetContainerView") {
                continue
            }
            // UIInputSetHostView
            for subview in view.subviews {
                let subViewName = NSStringFromClass(type(of: subview))
                if subViewName.length != 18 {
                    continue
                }
                if !subViewName.hasPrefix("UI") {
                    continue
                }
                if !subViewName.hasSuffix("InputSetHostView") {
                    continue
                }
                return subview
            }
        }
        return nil
    }
    
    @objc
    private func _keyboardFrameWillChange(_ notification: Notification?) {
        guard let notification = notification else {
            return
        }
        guard notification.name == UIResponder.keyboardWillChangeFrameNotification else {
            return
        }
        guard let userInfo = notification.userInfo else {
            return
        }
        _initFrameObserver()
        let beforeValue = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue
        let afterValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        let curveNumber = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        let durationNumber = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        let before: CGRect = beforeValue?.cgRectValue ?? .zero
        let after: CGRect = afterValue?.cgRectValue ?? .zero
        let curve = UIView.AnimationCurve(rawValue: curveNumber ?? 0) ?? .linear
        let duration = durationNumber
        // ignore zero end frame
        if after.size.width <= 0, after.size.height <= 0 {
            return
        }
        notificationFromFrame = before
        notificationToFrame = after
        notificationCurve = curve
        notificationDuration = duration ?? 0.25
        hasNotification = true
        lastIsNotification = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_notifyAllObservers), object: nil)
        if duration == 0 {
            perform(#selector(_notifyAllObservers), with: nil, afterDelay: 0, inModes: [.common])
        } else {
            _notifyAllObservers()
        }
    }
    
    @objc
    private func _keyboardFrameDidChange(_ notification: Notification?) {
        guard let notification = notification else {
            return
        }
        guard notification.name == UIResponder.keyboardDidChangeFrameNotification else {
            return
        }
        guard let userInfo = notification.userInfo else {
            return
        }
        _initFrameObserver()
        let after: CGRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        // ignore zero end frame
        if after.size.width <= 0, after.size.height <= 0 {
            return
        }
        notificationToFrame = after
        notificationCurve = UIView.AnimationCurve.easeInOut
        notificationDuration = 0
        hasNotification = true
        lastIsNotification = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_notifyAllObservers), object: nil)
        perform(#selector(_notifyAllObservers), with: nil, afterDelay: 0, inModes: [.common])
    }
    
    private func _keyboardFrameChanged(_ keyboard: UIView?) {
        if keyboard != keyboardView {
            return
        }
        
        if let window = keyboard?.window {
            observedToFrame = window.convert(keyboard?.frame ?? .zero, to: nil)
        } else {
            observedToFrame = keyboard?.frame ?? .zero
        }
        hasObservedChange = true
        lastIsNotification = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_notifyAllObservers), object: nil)
        perform(#selector(_notifyAllObservers), with: nil, afterDelay: 0, inModes: [.common])
    }
    
    @objc
    private func _notifyAllObservers() {
        guard TextUtilities.sharedApp != nil else {
            return
        }
        let keyboard: UIView? = keyboardView
        var window: UIWindow? = keyboard?.window
        if window == nil {
            window = TextUtilities.keyWindow
        }
        if window == nil {
            window = TextUtilities.windowScene?.windows.first
        }
        guard let window = window else {
            return
        }
        let transition = TextKeyboardTransition()
        // from
        if fromFrame.size.width == 0 && fromFrame.size.height == 0 {
            // first notify
            fromFrame.size.width = window.bounds.size.width
            fromFrame.size.height = transition.toFrame.size.height
            fromFrame.origin.x = transition.toFrame.origin.x
            fromFrame.origin.y = window.bounds.size.height
        }
        transition.fromFrame = fromFrame
        transition.fromVisible = fromVisible
        // to
        if lastIsNotification || (hasObservedChange && observedToFrame.equalTo(notificationToFrame)) {
            transition.toFrame = notificationToFrame
            transition.animationDuration = notificationDuration
            transition.animationCurve = notificationCurve
            transition.animationOption = UIView.AnimationOptions(rawValue: UInt(notificationCurve.rawValue << 16))
        } else {
            transition.toFrame = observedToFrame
        }
        if transition.toFrame.size.width > 0, transition.toFrame.size.height > 0 {
            let rect: CGRect = window.bounds.intersection(transition.toFrame)
            if !rect.isNull, !rect.isEmpty {
                transition.toVisible = true
            }
        }
        if !transition.toFrame.equalTo(fromFrame) {
            for observer in observers.objectEnumerator() {
                guard let observer = observer as? TextKeyboardObserver else {
                    return
                }
                if observer.responds(to: #selector(TextKeyboardObserver.keyboardChanged(with:))) {
                    observer.keyboardChanged?(with: transition)
                }
            }
        }
        hasNotification = false
        hasObservedChange = false
        fromFrame = transition.toFrame
        fromVisible = transition.toVisible
    }
    
    /// Convert rect to specified view or window.
    /// - Parameters:
    ///     - rect: The frame rect.
    ///     - view: A specified view or window (pass nil to convert for main window).
    /// - Returns: The converted rect in specifeid view.
    public func convert(_ rect: CGRect, to view: UIView?) -> CGRect {
        guard TextUtilities.sharedApp != nil else {
            return .zero
        }
        if rect.isNull {
            return rect
        }
        if rect.isInfinite {
            return rect
        }
        var rect = rect
        var mainWindow = TextUtilities.keyWindow
        if mainWindow == nil {
            mainWindow = TextUtilities.windowScene?.windows.first
        }
        if mainWindow == nil {
            // no window ?!
            if view != nil {
                view?.convert(rect, from: nil)
            } else {
                return rect
            }
        }
        rect = mainWindow?.convert(rect, from: nil) ?? CGRect.zero
        if view == nil {
            return mainWindow?.convert(rect, to: nil) ?? CGRect.zero
        }
        if view == mainWindow {
            return rect
        }
        let toWindow = (view is UIWindow) ? (view as? UIWindow) : view?.window
        if mainWindow == nil || toWindow == nil {
            return mainWindow?.convert(rect, to: view) ?? CGRect.zero
        }
        if mainWindow == toWindow {
            return mainWindow?.convert(rect, to: view) ?? CGRect.zero
        }
        // in different window
        rect = mainWindow?.convert(rect, to: mainWindow) ?? CGRect.zero
        rect = toWindow?.convert(rect, from: mainWindow) ?? CGRect.zero
        rect = view?.convert(rect, from: toWindow) ?? CGRect.zero
        return rect
    }
}

extension UIApplication {
    private static let runOnce: Void = {
        TextKeyboardManager.startManager()
    }()
    
    override open var next: UIResponder? {
        // Called before applicationDidFinishLaunching
        UIApplication.runOnce
        return super.next
    }
}
