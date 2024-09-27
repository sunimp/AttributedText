//
//  TextContainerView.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

/// A simple view to diaplay `TextLayout`.
///
/// This view can become first responder. If this view is first responder,
/// all the action (such as UIMenu's action) would forward to the `hostView` property.
/// Typically, you should not use this class directly.
///
/// All the methods in this class should be called on main thread.
public class TextContainerView: UIView {
    /// First responder's aciton will forward to this view.
    public weak var hostView: UIView?
    
    private var _debugOption: TextDebugOption?
    /// Debug option for layout debug. Set this property will let the view redraw it's contents.
    public var debugOption: TextDebugOption? {
        get {
            return _debugOption
        }
        set {
            let needDraw = _debugOption?.needDrawDebug ?? false
            _debugOption = newValue?.copy() as? TextDebugOption
            if _debugOption?.needDrawDebug ?? false != needDraw {
                setNeedsDisplay()
            }
        }
    }
    
    /// Text vertical alignment.
    public var textVerticalAlignment: TextVerticalAlignment = .top {
        didSet {
            if textVerticalAlignment == oldValue {
                return
            }
            setNeedsDisplay()
        }
    }
    
    /// Text layout. Set this property will let the view redraw it's contents.
    public var layout: TextLayout? {
        willSet {
            if layout == newValue {
                return
            }
            isAttachmentChanged = true
            setNeedsDisplay()
        }
    }
    
    /// The contents fade animation duration when the layout's contents changed. Default is 0 (no animation).
    public var contentsFadeDuration: TimeInterval = 0 {
        didSet {
            if contentsFadeDuration == oldValue {
                return
            }
            if contentsFadeDuration <= 0 {
                layer.removeAnimation(forKey: "contents")
            }
        }
    }
    
    private var isAttachmentChanged = false
    private lazy var attachmentViews: [UIView] = []
    private lazy var attachmentLayers: [CALayer] = []
    
    override public var frame: CGRect {
        get {
            return super.frame
        }
        set {
            let oldSize: CGSize = bounds.size
            super.frame = newValue
            if !oldSize.equalTo(bounds.size) {
                setNeedsLayout()
            }
        }
    }
    
    override public var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            let oldSize: CGSize = self.bounds.size
            super.bounds = newValue
            if !oldSize.equalTo(self.bounds.size) {
                setNeedsLayout()
            }
        }
    }
    
    // MARK: - UIResponder forward
    
    override public var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// 构造方法
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Convenience method to set `layout` and `contentsFadeDuration`.
    /// @param layout  Same as `layout` property.
    /// @param fadeDuration  Same as `contentsFadeDuration` property.
    public func set(layout: TextLayout?, with fadeDuration: TimeInterval) {
        contentsFadeDuration = fadeDuration
        self.layout = layout
    }
    
    // MARK: - override function

    override public func draw(_ rect: CGRect) {
        // fade content
        layer.removeAnimation(forKey: "contents")
        if contentsFadeDuration > 0 {
            let transition = CATransition()
            transition.duration = contentsFadeDuration
            transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
            transition.type = .fade
            layer.add(transition, forKey: "contents")
        }

        // update attachment
        if isAttachmentChanged {
            for view in attachmentViews where view.superview == self {
                view.removeFromSuperview()
            }
            for layer in attachmentLayers where layer.superlayer == self.layer {
                layer.removeFromSuperlayer()
            }
            attachmentViews.removeAll()
            attachmentLayers.removeAll()
        }

        // draw layout
        let boundingSize: CGSize = layout?.textBoundingSize ?? CGSize.zero
        var point = CGPoint.zero
        if textVerticalAlignment == TextVerticalAlignment.center {
            if layout?.container.isVerticalForm ?? false {
                point.x = -(bounds.size.width - boundingSize.width) * 0.5
            } else {
                point.y = (bounds.size.height - boundingSize.height) * 0.5
            }
        } else if textVerticalAlignment == TextVerticalAlignment.bottom {
            if layout?.container.isVerticalForm ?? false {
                point.x = -(bounds.size.width - boundingSize.width)
            } else {
                point.y = bounds.size.height - boundingSize.height
            }
        }
        layout?.draw(
            in: UIGraphicsGetCurrentContext(),
            size: bounds.size,
            point: point,
            view: self,
            layer: layer,
            debug: self._debugOption,
            cancel: nil
        )
        
        // update attachment
        if isAttachmentChanged {
            isAttachmentChanged = false
            for attachment in layout?.attachments ?? [] {
                if let view = attachment.content as? UIView {
                    attachmentViews.append(view)
                }
                if let layer = attachment.content as? CALayer {
                    attachmentLayers.append(layer)
                }
            }
        }
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return hostView?.canPerformAction(action, withSender: sender) ?? false
    }

    override public func forwardingTarget(for aSelector: Selector?) -> Any? {
        return hostView
    }
}
