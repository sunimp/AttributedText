//
//  TextSelectionView.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

private let selectionMarkAlpha: CGFloat = 0.2
private let selectionLineWidth: CGFloat = 2.0
private let selectionBlinkDuration = 0.5
private let selectionBlinkFadeDuration = 0.2
private let selectionBlinkFirstDelay = 0.1
private let selectionTouchTestExtend: CGFloat = 14.0
private let selectionTouchDotExtend: CGFloat = 7.0

/// A single dot view. The frame should be foursquare.
/// Change the background color for display.
///
/// Typically, you should not use this class directly.
public class SelectionGrabberDot: UIView {
    
    /// Dont't access this property. It was used by `TextEffectWindow`.
    public var mirror: UIView = UIView()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        let length = min(bounds.size.width, bounds.size.height)
        layer.cornerRadius = length * 0.5
        mirror.bounds = bounds
        mirror.layer.cornerRadius = layer.cornerRadius
    }
    
    /// 设置背景色
    public func setBackgroundColor(_ backgroundColor: UIColor?) {
        super.backgroundColor = backgroundColor
        mirror.backgroundColor = backgroundColor
    }
}

/// A grabber (stick with a dot).
///
/// Typically, you should not use this class directly.
public class SelectionGrabber: UIView {
    
    /// the dot view
    public private(set) var dot = SelectionGrabberDot(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    
    /// don't support composite direction
    public var dotDirection = TextDirection.none {
        didSet {
            addSubview(dot)
            var frame: CGRect = dot.frame
            let ofs: CGFloat = 0.5
            if dotDirection == TextDirection.top {
                frame.origin.y = -frame.size.height + ofs
                frame.origin.x = (bounds.size.width - frame.size.width) / 2
            } else if dotDirection == TextDirection.right {
                frame.origin.x = bounds.size.width - ofs
                frame.origin.y = (bounds.size.height - frame.size.height) / 2
            } else if dotDirection == TextDirection.bottom {
                frame.origin.y = bounds.size.height - ofs
                frame.origin.x = (bounds.size.width - frame.size.width) / 2
            } else if dotDirection == TextDirection.left {
                frame.origin.x = -frame.size.width + ofs
                frame.origin.y = (bounds.size.height - frame.size.height) / 2
            } else {
                dot.removeFromSuperview()
            }
            dot.frame = frame
        }
    }
    
    /// tint color, default is nil
    public var color: UIColor? {
        willSet {
            backgroundColor = newValue
            dot.backgroundColor = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        let direction = self.dotDirection
        self.dotDirection = direction
    }
    
    func touchRect() -> CGRect {
        var rect: CGRect = frame.insetBy(dx: -selectionTouchTestExtend, dy: -selectionTouchTestExtend)
        var insets = UIEdgeInsets.zero
        if dotDirection == TextDirection.top {
            insets.top = -selectionTouchDotExtend
        } else if dotDirection == TextDirection.right {
            insets.right = -selectionTouchDotExtend
        } else if dotDirection == TextDirection.bottom {
            insets.bottom = -selectionTouchDotExtend
        } else if dotDirection == TextDirection.left {
            insets.left = -selectionTouchDotExtend
        }
        rect = rect.inset(by: insets)
        return rect
    }
}

/// The selection view for text edit and select.
///
/// Typically, you should not use this class directly.
public class TextSelectionView: UIView {
    
    /// the holder view
    public weak var hostView: UIView?
    
    /// the tint color
    public var color: UIColor? {
        didSet {
            caretView.backgroundColor = color
            startGrabber.color = color
            endGrabber.color = color
            for view in markViews {
                view.backgroundColor = color
            }
        }
    }
    
    /// whether the caret is blinks
    public var isCaretBlinks = false {
        willSet {
            if isCaretBlinks != newValue {
                caretView.alpha = 1
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self._startBlinks), object: nil)
                if newValue {
                    perform(#selector(self._startBlinks), with: nil, afterDelay: selectionBlinkFirstDelay)
                } else {
                    caretTimer?.invalidate()
                    caretTimer = nil
                }
            }
        }
    }
    
    /// whether the caret is visible
    public var isCaretVisible = false {
        didSet {
            caretView.isHidden = !isCaretVisible
            caretView.alpha = 1
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self._startBlinks), object: nil)
            if isCaretBlinks {
                perform(#selector(self._startBlinks), with: nil, afterDelay: selectionBlinkFirstDelay)
            }
        }
    }
    
    /// weather the text view is vertical form
    public var isVerticalForm = false {
        didSet {
            if isVerticalForm != oldValue {
                let rect = caretRect
                self.caretRect = rect
                startGrabber.dotDirection = isVerticalForm ? TextDirection.right : TextDirection.top
                endGrabber.dotDirection = isVerticalForm ? TextDirection.left : TextDirection.bottom
            }
        }
    }
    
    /// caret rect (width == 0 or height == 0)
    public var caretRect = CGRect.zero {
        didSet {
            caretView.frame = _standardCaretRect(caretRect)
            let minWidth = min(caretView.bounds.size.width, caretView.bounds.size.height)
            caretView.layer.cornerRadius = minWidth / 2
        }
    }
    
    /// default is nil
    public var selectionRects: [TextSelectionRect]? {
        didSet {
            for view in markViews {
                view.removeFromSuperview()
            }
            markViews.removeAll()
            startGrabber.isHidden = true
            endGrabber.isHidden = true
            for selectionRect in selectionRects ?? [] {
                var rect: CGRect = selectionRect.rect
                rect = rect.standardized.roundFlattened()
                if selectionRect.containsStart || selectionRect.containsEnd {
                    rect = self._standardCaretRect(rect)
                    if selectionRect.containsStart {
                        self.startGrabber.isHidden = false
                        self.startGrabber.frame = rect
                    }
                    if selectionRect.containsEnd {
                        self.endGrabber.isHidden = false
                        self.endGrabber.frame = rect
                    }
                } else {
                    if (rect.size.width > 0) && (rect.size.height > 0) {
                        let mark = UIView(frame: rect)
                        mark.backgroundColor = self.color
                        mark.alpha = selectionMarkAlpha
                        self.insertSubview(mark, at: 0)
                        self.markViews.append(mark)
                    }
                }
            }
        }
    }
    
    public private(set) var caretView = UIView()
    public private(set) var startGrabber = SelectionGrabber()
    public private(set) var endGrabber = SelectionGrabber()
    
    private var caretTimer: Timer?
    private lazy var markViews: [UIView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = false
        
        caretView.isHidden = true
        startGrabber.dotDirection = TextDirection.top
        startGrabber.isHidden = true
        endGrabber.dotDirection = TextDirection.bottom
        endGrabber.isHidden = true
        addSubview(startGrabber)
        addSubview(endGrabber)
        addSubview(caretView)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func _startBlinks() {
        self.caretTimer?.invalidate()
        if self.isCaretVisible {
            let timer = Timer.scheduled(
                interval: selectionBlinkDuration,
                target: self,
                selector: #selector(_doBlink),
                repeats: true
            )
            self.caretTimer = timer
            RunLoop.current.add(timer, forMode: .default)
        } else {
            self.caretView.alpha = 1
        }
    }
    
    @objc
    private func _doBlink() {
        UIView.animate(withDuration: selectionBlinkFadeDuration, delay: 0, options: .curveEaseInOut, animations: {
            if self.caretView.alpha == 1 {
                self.caretView.alpha = 0
            } else {
                self.caretView.alpha = 1
            }
        })
    }
    
    private func _standardCaretRect(_ caretRect: CGRect) -> CGRect {
        var rect = caretRect.standardized
        if isVerticalForm {
            if rect.size.height == 0 {
                rect.size.height = selectionLineWidth
                rect.origin.y -= selectionLineWidth * 0.5
            }
            if rect.origin.y < 0 {
                rect.origin.y = 0
            } else if rect.origin.y + rect.size.height > bounds.size.height {
                rect.origin.y = bounds.size.height - rect.size.height
            }
        } else {
            if rect.size.width == 0 {
                rect.size.width = selectionLineWidth
                rect.origin.x -= selectionLineWidth * 0.5
            }
            if rect.origin.x < 0 {
                rect.origin.x = 0
            } else if rect.origin.x + rect.size.width > bounds.size.width {
                rect.origin.x = bounds.size.width - rect.size.width
            }
        }
        rect = rect.roundFlattened()
        if rect.origin.x.isNaN || rect.origin.x.isInfinite {
            rect.origin.x = 0
        }
        if rect.origin.y.isNaN || rect.origin.y.isInfinite {
            rect.origin.y = 0
        }
        if rect.size.width.isNaN || rect.size.width.isInfinite {
            rect.size.width = 0
        }
        if rect.size.height.isNaN || rect.size.height.isInfinite {
            rect.size.height = 0
        }
        return rect
    }
    
    public func isGrabberContains(_ point: CGPoint) -> Bool {
        return isStartGrabberContains(point) || isEndGrabberContains(point)
    }
    
    public func isStartGrabberContains(_ point: CGPoint) -> Bool {
        if startGrabber.isHidden {
            return false
        }
        let startRect: CGRect = startGrabber.touchRect()
        let endRect: CGRect = endGrabber.touchRect()
        if startRect.intersects(endRect) {
            let distStart = point.distance(toPoint: CGPoint(x: startRect.midX, y: startRect.midY))
            let distEnd = point.distance(toPoint: CGPoint(x: endRect.midX, y: endRect.midY))
            if distEnd <= distStart {
                return false
            }
        }
        return startRect.contains(point)
    }
    
    public func isEndGrabberContains(_ point: CGPoint) -> Bool {
        if endGrabber.isHidden {
            return false
        }
        let startRect: CGRect = startGrabber.touchRect()
        let endRect: CGRect = endGrabber.touchRect()
        if startRect.intersects(endRect) {
            let distStart = point.distance(toPoint: CGPoint(x: startRect.midX, y: startRect.midY))
            let distEnd = point.distance(toPoint: CGPoint(x: endRect.midX, y: endRect.midY))
            if distEnd > distStart {
                return false
            }
        }
        return endRect.contains(point)
    }
    
    public func isCaretContains(_ point: CGPoint) -> Bool {
        if isCaretVisible {
            let rect: CGRect = caretRect.insetBy(dx: -selectionTouchTestExtend, dy: -selectionTouchTestExtend)
            return rect.contains(point)
        }
        return false
    }
    
    public func isSelectionRectsContains(_ point: CGPoint) -> Bool {
        guard let selectionRects = selectionRects, !selectionRects.isEmpty else {
            return false
        }
        for selectionRect in selectionRects where selectionRect.rect.contains(point) {
            return true
        }
        return false
    }
    
    deinit {
        caretTimer?.invalidate()
    }
    
}
