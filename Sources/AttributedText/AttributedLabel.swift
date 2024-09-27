//
//  AttributedLabel.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreText

/// 长按手势时手指必须按住的时间(秒)
private let longPressMinimumDuration = 0.5
/// 长按失败前允许的最大移动点数
private let longPressAllowableMovement: Float = 9
/// 高亮淡出动画的时间(秒)
private let highlightFadeDuration = 0.15
/// 异步显示淡出动画的时间(秒)
private let asyncFadeDuration = 0.08

// swiftlint:disable file_length type_body_length
/// AttributedLabel 类实现了文本标签视图
///
/// 此类的 API 和行为与 UILabel 相似, 但提供了更多功能：
/// - 支持异步布局和渲染
/// - 扩展了 CoreText 属性以支持更多文本效果
/// - 允许添加 UIImage、UIView 和 CALayer 作为文本附件。
/// - 允许在某些文本范围内添加“高亮显示”, 以允许用户进行交互
/// - 允许添加 Path 来控制文本容器的形状
/// - 支持垂直表单布局来显示 CJK 文本
///
open class AttributedLabel: UIView, TextDebugTarget, TextAsyncLayerDelegate, NSSecureCoding {
    /// 页面状态
    private struct State {
        var isLayoutNeedUpdate: Bool = false
        var isShowingHighlight: Bool = false
        
        var isTrackingTouch: Bool = false
        var isSwallowTouch: Bool = false
        var isTouchMoved: Bool = false
        
        var hasTapAction: Bool = false
        var hasLongPressAction: Bool = false
        
        var isContentsNeedFade: Bool = false
    }
    
    /// 默认字体
    private static let defaultFont = UIFont.systemFont(ofSize: 17)
    
    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    override open class var layerClass: AnyClass {
        return TextAsyncLayer.self
    }
    
    // MARK: - 文本属性

    private var _text: String?
    /// 标签所显示的文本
    ///
    /// 默认为 nil
    ///
    /// 为这个属性设置一个新的值, 也会替换 `attributedText` 中的文本,
    /// 获取该值会返回 `attributedText` 中的纯文本
    open var text: String? {
        get {
            return _text
        }
        set {
            if _text == newValue {
                return
            }
            _text = newValue
            let isNeedAddAttributes = innerText.length == 0 && (text?.length ?? 0) > 0
            innerText.replaceCharacters(
                in: NSRange(location: 0, length: innerText.length),
                with: text ?? ""
            )
            innerText.removeDiscontinuousAttributes(in: NSRange(location: 0, length: innerText.length))
            if isNeedAddAttributes {
                innerText.setFont(font)
                innerText.setTextColor(textColor)
                innerText.setShadow(_shadowFromProperties())
                innerText.setAlignment(textAlignment)
                switch lineBreakMode {
                case .byCharWrapping, .byClipping, .byWordWrapping:
                    innerText.setLineBreakMode(lineBreakMode)
                case .byTruncatingHead, .byTruncatingMiddle, .byTruncatingTail:
                    innerText.setLineBreakMode(.byWordWrapping)
                default:
                    break
                }
            }
            if let parser = textParser, parser.parseText(innerText, selectedRange: nil) {
                _updateOuterTextProperties()
            }
            if !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private lazy var _font = AttributedLabel.defaultFont
    /// The font of the text. Default is 17-point system font.
    ///
    /// Set a new value to this property also causes the new font to be applied to the entire `attributedText`.
    /// Get the value returns the font at the head of `attributedText`.
    open var font: UIFont? {
        get {
            return _font
        }
        set {
            let newFont = newValue ?? Self.defaultFont
            if _font == newFont { return }
            _font = newFont
            innerText.setFont(_font)
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _textColor: UIColor = .black
    /// The color of the text. Default is black.
    ///
    /// Set a new value to this property also causes the new color to be applied to the entire `attributedText`.
    /// Get the value returns the color at the head of `attributedText`.
    open var textColor: UIColor {
        get {
            return _textColor
        }
        set {
            if _textColor == newValue {
                return
            }
            _textColor = newValue
            innerText.setTextColor(_textColor)
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    private var _shadowColor: UIColor?
    /// The shadow color of the text. Default is nil.
    ///
    /// Set a new value to this property also causes the shadow color to be applied to the entire `attributedText`.
    ///
    /// Get the value returns the shadow color at the head of `attributedText`.
    open var shadowColor: UIColor? {
        get {
            return _shadowColor
        }
        set {
            if _shadowColor == newValue {
                return
            }
            _shadowColor = newValue
            innerText.setShadow(_shadowFromProperties())
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    private var _shadowOffset = CGSize.zero
    /// The shadow offset of the text. Default is CGSize.zero.
    ///
    /// Set a new value to this property also causes the shadow offset to be applied to the entire `attributedText`.
    ///
    /// Get the value returns the shadow offset at the head of `attributedText`.
    open var shadowOffset: CGSize {
        get {
            return _shadowOffset
        }
        set {
            if _shadowOffset == newValue {
                return
            }
            _shadowOffset = newValue
            innerText.setShadow(_shadowFromProperties())
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    private var _shadowBlurRadius: CGFloat = 0
    /// The shadow blur of the text. Default is 0.
    ///
    /// Set a new value to this property also causes the shadow blur to be applied to the entire `attributedText`.
    ///
    /// Get the value returns the shadow blur at the head of `attributedText`.
    open var shadowBlurRadius: CGFloat {
        get {
            return _shadowBlurRadius
        }
        set {
            if _shadowBlurRadius == newValue {
                return
            }
            _shadowBlurRadius = newValue
            innerText.setShadow(_shadowFromProperties())
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
            }
        }
    }
    
    private var _textAlignment = NSTextAlignment.natural
    /// The technique to use for aligning the text. Default is NSTextAlignment.natural.
    /// Set a new value to this property also causes the new alignment to be applied to the entire `attributedText`.
    /// Get the value returns the alignment at the head of `attributedText`.
    open var textAlignment: NSTextAlignment {
        get {
            return _textAlignment
        }
        set {
            if _textAlignment == newValue {
                return
            }
            _textAlignment = newValue
            innerText.setAlignment(_textAlignment)
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// The text vertical aligmnent in container. Default is TextVerticalAlignment.center.
    open var textVerticalAlignment = TextVerticalAlignment.center {
        didSet {
            if textVerticalAlignment == oldValue {
                return
            }
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _attributedText: NSAttributedString?
    
    /// The styled text displayed by the label.
    /// Set a new value to this property also replaces the value of the `text`, `font`, `textColor`,
    /// `textAlignment` and other properties in label.
    /// It only support the attributes declared in CoreText and TextAttribute.
    /// See `NSAttributedString+AttributedText.swift` for more convenience methods to set the attributes.
    open var attributedText: NSAttributedString? {
        get {
            return _attributedText
        }
        set {
            if _attributedText == newValue {
                return
            }
            if let newText = newValue, newText.length > 0 {
                innerText = NSMutableAttributedString(attributedString: newText)
                switch lineBreakMode {
                case .byCharWrapping, .byClipping, .byWordWrapping:
                    innerText.setLineBreakMode(lineBreakMode)
                case .byTruncatingHead, .byTruncatingMiddle, .byTruncatingTail:
                    innerText.setLineBreakMode(.byWordWrapping)
                default:
                    break
                }
            } else {
                innerText = NSMutableAttributedString()
            }
            textParser?.parseText(innerText, selectedRange: nil)
            if !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _updateOuterTextProperties()
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _lineBreakMode = NSLineBreakMode.byTruncatingTail
    /// The technique to use for wrapping and truncating the label's text.
    ///
    /// Default is NSLineBreakMode.byTruncatingTail.
    open var lineBreakMode: NSLineBreakMode {
        get {
            return _lineBreakMode
        }
        set {
            if _lineBreakMode == newValue {
                return
            }
            _lineBreakMode = newValue
            innerText.setLineBreakMode(_lineBreakMode)
            // allow multi-line break
            switch _lineBreakMode {
            case .byCharWrapping, .byClipping, .byWordWrapping:
                innerContainer.truncationType = .none
                innerText.setLineBreakMode(_lineBreakMode)
            case .byTruncatingHead:
                innerContainer.truncationType = .start
                innerText.setLineBreakMode(.byWordWrapping)
            case .byTruncatingTail:
                innerContainer.truncationType = .end
                innerText.setLineBreakMode(.byWordWrapping)
            case .byTruncatingMiddle:
                innerContainer.truncationType = .middle
                innerText.setLineBreakMode(.byWordWrapping)
            default:
                break
            }
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _truncationToken: NSAttributedString?
    /// The truncation token string used when text is truncated. Default is nil.
    /// When the value is nil, the label use "…" as default truncation token.
    open var truncationToken: NSAttributedString? {
        get {
            return _truncationToken
        }
        set {
            if _truncationToken == newValue {
                return
            }
            _truncationToken = newValue
            innerContainer.truncationToken = _truncationToken
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _numberOfLines: Int = 1
    /// The maximum number of lines to use for rendering text. Default value is 1.
    /// 0 means no limit.
    open var numberOfLines: Int {
        get {
            return _numberOfLines
        }
        set {
            if _numberOfLines == newValue {
                return
            }
            _numberOfLines = newValue
            innerContainer.maximumNumberOfRows = _numberOfLines
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// When `text` or `attributedText` is changed, the parser will be called to modify the text.
    /// It can be used to add code highlighting or emoticon replacement to text view.
    ///
    /// The default value is nil.
    ///
    /// See `TextParser` protocol for more information.
    open var textParser: TextParser? {
        didSet {
            if self.textParser === oldValue {
                return
            }
            if self.textParser?.parseText(innerText, selectedRange: nil) ?? false {
                _updateOuterTextProperties()
                if !isCommonPropertiesIgnored {
                    if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                        _clearContents()
                    }
                    _setLayoutNeedUpdate()
                    _endTouch()
                    invalidateIntrinsicContentSize()
                }
            }
        }
    }
    
    /// The current text layout in text view. It can be used to query the text layout information.
    ///
    /// Set a new value to this property also replaces most properties in this label, such as `text`,
    /// `color`, `attributedText`, `lineBreakMode`, `textContainerPath`, `exclusionPaths` and so on.
    open var textLayout: TextLayout? {
        get {
            _updateIfNeeded()
            return innerLayout
        }
        set {
            innerLayout = newValue
            shrinkInnerLayout = nil
            
            if isCommonPropertiesIgnored {
                innerText = newValue?.text as? NSMutableAttributedString ?? NSMutableAttributedString()
                innerContainer = newValue?.container.copy() as? TextContainer ?? TextContainer()
            } else {
                if let newText = newValue?.text {
                    innerText = NSMutableAttributedString(attributedString: newText)
                } else {
                    innerText = NSMutableAttributedString()
                }
                _updateOuterTextProperties()
                if let container = newValue?.container.copy() as? TextContainer {
                    innerContainer = container
                } else {
                    innerContainer = TextContainer()
                    innerContainer.size = bounds.size
                    innerContainer.insets = textContainerInset
                }
                _updateOuterContainerProperties()
            }
            
            if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                _clearContents()
            }
            state.isLayoutNeedUpdate = false
            _setLayoutNeedRedraw()
            _endTouch()
            invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Configuring the Text Container

    private var _textContainerPath: UIBezierPath?
    /// A UIBezierPath object that specifies the shape of the text frame.
    ///
    /// Default value is nil.
    open var textContainerPath: UIBezierPath? {
        get {
            return _textContainerPath
        }
        set {
            if _textContainerPath == newValue { return }
            
            _textContainerPath = newValue
            innerContainer.path = _textContainerPath
            if textContainerPath == nil {
                innerContainer.size = bounds.size
                innerContainer.insets = textContainerInset
            }
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _exclusionPaths: [UIBezierPath]?
    ///  An array of UIBezierPath objects representing the exclusion paths inside the receiver's bounding rectangle.
    ///
    /// Default value is nil.
    open var exclusionPaths: [UIBezierPath]? {
        get {
            return _exclusionPaths
        }
        set {
            if _exclusionPaths == newValue { return }
            
            _exclusionPaths = newValue
            if let aPaths = _exclusionPaths {
                innerContainer.exclusionPaths = aPaths
            }
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _textContainerInset = UIEdgeInsets.zero
    /**
     The inset of the text container's layout area within the text view's content area.
     Default value is UIEdgeInsetsZero.
     */
    open var textContainerInset: UIEdgeInsets {
        get {
            return _textContainerInset
        }
        set {
            if _textContainerInset == newValue { return }
            
            _textContainerInset = newValue
            innerContainer.insets = _textContainerInset
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _verticalForm = false
    /// Whether the receiver's layout orientation is vertical form.
    ///
    /// Default is false.
    ///
    /// It may used to display CJK text.
    open var isVerticalForm: Bool {
        get {
            return _verticalForm
        }
        set {
            if _verticalForm == newValue { return }
            
            _verticalForm = newValue
            innerContainer.isVerticalForm = _verticalForm
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _linePositionModifier: TextLinePositionModifier?
    /// The text line position modifier used to modify the lines' position in layout.
    ///
    /// Default value is nil.
    ///
    /// See `TextLinePositionModifier` protocol for more information.
    open weak var linePositionModifier: TextLinePositionModifier? {
        get {
            return _linePositionModifier
        }
        set {
            if _linePositionModifier === newValue { return }
            
            _linePositionModifier = newValue
            innerContainer.linePositionModifier = _linePositionModifier
            if innerText.length != 0, !isCommonPropertiesIgnored {
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedUpdate()
                _endTouch()
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    private var _debugOption: TextDebugOption? = TextDebugOption.shared
    
    /// The debug option to display CoreText layout result.
    /// The default value is TextDebugOption.shared.
    open var debugOption: TextDebugOption? {
        get {
            return _debugOption
        }
        set {
            let needDraw = _debugOption?.needDrawDebug
            _debugOption = newValue?.copy() as? TextDebugOption
            if _debugOption?.needDrawDebug != needDraw {
                _setLayoutNeedRedraw()
            }
        }
    }

    // MARK: - Getting the Layout Constraints
    
    /// The preferred maximum width (in points) for a multiline label.
    ///
    /// This property affects the size of the label when layout constraints
    /// are applied to it. During layout, if the text extends beyond the width
    /// specified by this property, the additional text is flowed to one or more new
    /// lines, thereby increasing the height of the label. If the text is vertical
    /// form, this value will match to text height.
    open var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet {
            if self.preferredMaxLayoutWidth == oldValue {
                return
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    // MARK: - Interacting with Text Data
    
    /// When user tap the label, this action will be called (similar to tap gesture).
    ///
    /// The default value is nil.
    open var textTapAction: TextAction?
    
    /// 点击非响应区域，设置该属性后会占用textTapAction
    open var tapAround: (() -> Void)? {
        didSet {
            self.textTapAction = { [weak self] (_, text, range, _) in
                let highlight = text.attribute(for: TextAttribute.textHighlight, at: range.location)
                if range.location == NSNotFound || highlight == nil {
                    self?.tapAround?()
                }
            }
        }
    }
    
    /// When user long press the label, this action will be called (similar to long press gesture).
    ///
    /// The default value is nil.
    open var textLongPressAction: TextAction?
    
    /// When user tap the highlight range of text, this action will be called.
    ///
    /// The default value is nil.
    open var highlightTapAction: TextAction?
    
    /// When user long press the highlight range of text, this action will be called.
    ///
    /// The default value is nil.
    open var highlightLongPressAction: TextAction?
    
    // MARK: - Configuring the Display Mode
    
    /// A Boolean value indicating whether the layout and rendering codes are running
    /// asynchronously on background threads.
    ///
    /// The default value is `false`.
    open var isDisplaysAsynchronously = false {
        didSet {
            (layer as? TextAsyncLayer)?.isDisplaysAsynchronously = isDisplaysAsynchronously
        }
    }
    
    // swiftlint:disable identifier_name
    /// If the value is true, and the layer is rendered asynchronously, then it will
    /// set label.layer.contents to nil before display.
    ///
    /// The default value is `true`.
    ///
    /// When the asynchronously display is enabled, the layer's content will
    /// be updated after the background render process finished. If the render process
    /// can not finished in a vsync time (1/60 second), the old content will be still kept
    /// for display. You may manually clear the content by set the layer.contents to nil
    /// after you update the label's properties, or you can just set this property to true.
    open var isClearContentsBeforeAsynchronouslyDisplay = true
    // swiftlint:enable identifier_name
    
    /// If the value is true, and the layer is rendered asynchronously, then it will add
    /// a fade animation on layer when the contents of layer changed.
    ///
    /// The default value is `true`.
    open var isFadeOnAsynchronouslyDisplay = true
    
    /// If the value is true, then it will add a fade animation on layer when some range
    /// of text become highlighted.
    ///
    /// The default value is `true`.
    open var isFadeOnHighlight = true
    
    /// Ignore common properties (such as text, font, textColor, attributedText...) and
    /// only use "textLayout" to display content.
    ///
    /// The default value is `false`.
    ///
    /// If you control the label content only through "textLayout", then
    /// you may set this value to true for higher performance.
    open var isCommonPropertiesIgnored = false
    
    /// Tips:
    ///
    /// 1. If you only need a UILabel alternative to display rich text and receive link touch event,
    /// you do not need to adjust the display mode properties.
    ///
    /// 2. If you have performance issues, you may enable the asynchronous display mode
    /// by setting the `isDisplaysAsynchronously` to true.
    ///
    /// 3. If you want to get the highest performance, you should do text layout with
    /// `TextLayout` class in background thread. Here's an example:
    ///
    ///     let label = AttributedLabel()
    ///     label.isDisplaysAsynchronously = true
    ///     label.isCommonPropertiesIgnored = true
    ///
    ///     DispatchQueue.global().async(execute: {
    ///
    ///         // Create attributed string.
    ///         let text = NSMutableAttributedString.init(string: "Some Text")
    ///         text.ss.font = UIFont.systemFont(ofSize: 16)
    ///         text.ss.textColor = .gray
    ///         text.ss.set(color: .red, range: NSRange(location: 0, length: 4))
    ///
    ///         // Create text container
    ///         let container = TextContainer()
    ///         container.size = CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude)
    ///         container.maximumNumberOfRows = 0
    ///
    ///         // Generate a text layout.
    ///         let layout = TextLayout(container: container, text: text)
    ///
    ///         DispatchQueue.main.async(execute: {
    ///             label.size = layout.textBoundingSize
    ///             label.textLayout = layout
    ///         })
    ///     })
    ///
    private lazy var innerText = NSMutableAttributedString() /// nonnull
    private var innerLayout: TextLayout?
    private lazy var innerContainer = TextContainer() /// nonnull
    private lazy var attachmentViews = [UIView]()
    private lazy var attachmentLayers = [CALayer]()
    private lazy var highlightRange = NSRange(location: 0, length: 0) /// current highlight range
    private var highlight: TextHighlight? /// highlight attribute in `highlightRange`
    private var highlightLayout: TextLayout? /// when _state.showingHighlight=true, this layout should be displayed
    private var shrinkInnerLayout: TextLayout?
    private var shrinkHighlightLayout: TextLayout?
    private var longPressTimer: Timer?
    private var touchBeganPoint: CGPoint = .zero
    
    private lazy var state = State()

    override open var frame: CGRect {
        get {
            return super.frame
        }
        set {
            let oldSize: CGSize = bounds.size
            super.frame = newValue
            let newSize: CGSize = bounds.size
            if oldSize != newSize {
                innerContainer.size = bounds.size
                if !isCommonPropertiesIgnored {
                    state.isLayoutNeedUpdate = true
                }
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedRedraw()
            }
        }
    }
    
    override open var bounds: CGRect {
        get {
            return super.bounds
        }
        set {
            let oldSize: CGSize = self.bounds.size
            super.bounds = newValue
            let newSize: CGSize = self.bounds.size
            if oldSize != newSize {
                innerContainer.size = self.bounds.size
                if !isCommonPropertiesIgnored {
                    state.isLayoutNeedUpdate = true
                }
                if isDisplaysAsynchronously && isClearContentsBeforeAsynchronouslyDisplay {
                    _clearContents()
                }
                _setLayoutNeedRedraw()
            }
        }
    }
    
    // MARK: - AutoLayout

    override open var intrinsicContentSize: CGSize {
        if preferredMaxLayoutWidth == 0 {
            let container = innerContainer.copy() as? TextContainer
            container?.size = TextContainer.maxSize
            
            let layout = TextLayout(container: container, text: innerText)
            return layout?.textBoundingSize ?? .zero
        }
        
        var containerSize: CGSize = innerContainer.size
        if !isVerticalForm {
            containerSize.height = TextContainer.maxSize.height
            containerSize.width = preferredMaxLayoutWidth
            if containerSize.width == 0 {
                containerSize.width = bounds.size.width
            }
        } else {
            containerSize.width = TextContainer.maxSize.width
            containerSize.height = preferredMaxLayoutWidth
            if containerSize.height == 0 {
                containerSize.height = bounds.size.height
            }
        }
        
        let container = innerContainer.copy() as? TextContainer
        container?.size = containerSize
        
        let layout = TextLayout(container: container, text: innerText)
        return layout?.textBoundingSize ?? .zero
    }
    
    // MARK: - Override
    
    override public init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.clear
        isOpaque = false
        _initLabel()
        self.frame = frame
    }
    
    // MARK: - NSCoding

    /// Decode
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initLabel()
        
        if let innerContainer = aDecoder.decodeObject(forKey: "innerContainer") as? TextContainer {
            self.innerContainer = innerContainer
        } else {
            innerContainer.size = bounds.size
        }
        _updateOuterContainerProperties()
        self.attributedText = aDecoder.decodeObject(forKey: "attributedText") as? NSAttributedString
        _setLayoutNeedUpdate()
    }
    
    private static func _shrinkLayout(with layout: TextLayout?) -> TextLayout? {
        guard let layout = layout else {
            return nil
        }
        guard let text = layout.text, text.length > 0, layout.lines.isEmpty else {
            return nil
        }
        
        guard let container = layout.container.copy() as? TextContainer else {
            return nil
        }
        container.maximumNumberOfRows = 1
        var containerSize = container.size
        if container.isVerticalForm == false {
            containerSize.height = TextContainer.maxSize.height
        } else {
            containerSize.width = TextContainer.maxSize.width
        }
        container.size = containerSize
        return TextLayout(container: container, text: layout.text)
    }
    
    /// Encode
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(_attributedText, forKey: "attributedText")
        aCoder.encode(innerContainer, forKey: "innerContainer")
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        if isCommonPropertiesIgnored {
            return innerLayout?.textBoundingSize ?? .zero
        }
        
        if !isVerticalForm && size.width <= 0 {
            size.width = TextContainer.maxSize.width
        } else if isVerticalForm && size.height <= 0 {
            size.height = TextContainer.maxSize.height
        }
        
        if (!isVerticalForm && size.width == bounds.size.width) || (isVerticalForm && size.height == bounds.size.height) {
            _updateIfNeeded()
            let layout: TextLayout? = innerLayout
            var contains = false
            if layout?.container.maximumNumberOfRows == 0 {
                if layout?.truncatedLine == nil {
                    contains = true
                }
            } else {
                if layout?.rowCount ?? 0 <= (layout?.container.maximumNumberOfRows ?? 0) {
                    contains = true
                }
            }
            if contains {
                return layout?.textBoundingSize ?? .zero
            }
        }
        
        if !isVerticalForm {
            size.height = TextContainer.maxSize.height
        } else {
            size.width = TextContainer.maxSize.width
        }
        
        let container = innerContainer.copy() as? TextContainer
        container?.size = size
        
        let layout = TextLayout(container: container, text: innerText)
        return layout?.textBoundingSize ?? .zero
    }
    
    // MARK: - Touches

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _updateIfNeeded()
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: self)
        
        highlight = _getHighlight(at: point, range: &highlightRange)
        highlightLayout = nil
        shrinkHighlightLayout = nil
        state.hasTapAction = (textTapAction != nil)
        state.hasLongPressAction = (textLongPressAction != nil)
        
        if (highlight != nil) || (textTapAction != nil) || (textLongPressAction != nil) {
            touchBeganPoint = point
            state.isTrackingTouch = true
            state.isSwallowTouch = true
            state.isTouchMoved = false
            _startLongPressTimer()
            if highlight != nil {
                _showHighlight(animated: false)
            }
        } else {
            state.isTrackingTouch = false
            state.isSwallowTouch = false
            state.isTouchMoved = false
        }
        if !state.isSwallowTouch {
            super.touchesBegan(touches, with: event)
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        _updateIfNeeded()
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: self)
        
        if state.isTrackingTouch {
            if !state.isTouchMoved {
                let moveH = Float(point.x - touchBeganPoint.x)
                let moveV = Float(point.y - touchBeganPoint.y)
                if abs(moveH) > abs(moveV) {
                    if abs(moveH) > longPressAllowableMovement {
                        state.isTouchMoved = true
                    }
                } else {
                    if abs(moveV) > longPressAllowableMovement {
                        state.isTouchMoved = true
                    }
                }
                if state.isTouchMoved {
                    _endLongPressTimer()
                }
            }
            if state.isTouchMoved, highlight != nil {
                let highlight = _getHighlight(at: point, range: nil)
                if highlight == self.highlight {
                    _showHighlight(animated: isFadeOnHighlight)
                } else {
                    _hideHighlight(animated: isFadeOnHighlight)
                }
            }
        }
        
        if !state.isSwallowTouch {
            super.touchesMoved(touches, with: event)
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: self)
        
        if state.isTrackingTouch {
            _endLongPressTimer()
            if !state.isTouchMoved, textTapAction != nil {
                var range = NSRange(location: NSNotFound, length: 0)
                var rect = CGRect.null
                let point: CGPoint = _convertPoint(toLayout: touchBeganPoint)
                let textRange: TextRange? = innerLayout?.textRange(at: point)
                guard var textRect = innerLayout?.rect(for: textRange) else {
                    return
                }
                textRect = _convertRect(fromLayout: textRect)
                if textRange != nil {
                    if let nsRange = textRange?.nsRange {
                        range = nsRange
                    }
                    rect = textRect
                }
                textTapAction?(self, innerText, range, rect)
            }
            
            if let highlight = highlight {
                if !state.isTouchMoved || _getHighlight(at: point, range: nil) == highlight {
                    if let tapAction = highlight.tapAction != nil ? highlight.tapAction : highlightTapAction {
                        let start = TextPosition(offset: highlightRange.location)
                        let end = TextPosition(
                            offset: highlightRange.location + highlightRange.length,
                            affinity: .backward
                        )
                        let range = TextRange(start: start, end: end)
                        guard var rect: CGRect = innerLayout?.rect(for: range) else {
                            return
                        }
                        rect = _convertRect(fromLayout: rect)
                        tapAction(self, innerText, highlightRange, rect)
                    }
                }
                _removeHighlight(animated: isFadeOnHighlight)
            }
        }
        
        if !state.isSwallowTouch {
            super.touchesEnded(touches, with: event)
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        _endTouch()
        if !state.isSwallowTouch {
            super.touchesCancelled(touches, with: event)
        }
    }
    
    /// 无障碍标签
    public func accessibilityLabel() -> String? {
        return innerLayout?.text?.plainText(for: innerLayout?.text?.rangeOfAll ?? NSRange(location: 0, length: 0))
    }
    
    // MARK: - Private

    private func _updateIfNeeded() {
        if state.isLayoutNeedUpdate {
            state.isLayoutNeedUpdate = false
            _updateLayout()
            layer.setNeedsDisplay()
        }
    }
    
    private func _updateLayout() {
        innerLayout = TextLayout(container: innerContainer, text: innerText)
        shrinkInnerLayout = Self._shrinkLayout(with: innerLayout)
    }
    
    private func _setLayoutNeedUpdate() {
        state.isLayoutNeedUpdate = true
        _clearInnerLayout()
        _setLayoutNeedRedraw()
    }
    
    private func _setLayoutNeedRedraw() {
        layer.setNeedsDisplay()
    }
    
    private func _clearInnerLayout() {
        if innerLayout == nil {
            return
        }
        let layout: TextLayout? = innerLayout
        innerLayout = nil
        shrinkInnerLayout = nil
        DispatchQueue.global(qos: .default).async {
            let text: NSAttributedString? = layout?.text // capture to block and release in background
            if let attachments = layout?.attachments, !attachments.isEmpty {
                DispatchQueue.main.async {
                    // capture to block and release in main thread (maybe there's UIView/CALayer attachments).
                    _ = text?.length
                }
            }
        }
    }
    
    private func _innerLayout() -> TextLayout? {
        return (shrinkInnerLayout != nil) ? shrinkInnerLayout : innerLayout
    }
    
    private func _highlightLayout() -> TextLayout? {
        return (shrinkHighlightLayout != nil) ? shrinkHighlightLayout : highlightLayout
    }
    
    private func _startLongPressTimer() {
        longPressTimer?.invalidate()
        let timer = Timer.scheduled(
            interval: longPressMinimumDuration,
            target: self,
            selector: #selector(_trackDidLongPress),
            repeats: false
        )
        longPressTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func _endLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    @objc
    private func _trackDidLongPress() {
        _endLongPressTimer()
        if state.hasLongPressAction, textLongPressAction != nil {
            var range = NSRange(location: NSNotFound, length: 0)
            var rect = CGRect.null
            let point: CGPoint = _convertPoint(toLayout: touchBeganPoint)
            let textRange: TextRange? = innerLayout?.textRange(at: point)
            var textRect: CGRect = innerLayout?.rect(for: textRange) ?? CGRect.zero
            textRect = _convertRect(fromLayout: textRect)
            if textRange != nil {
                if let nsRange = textRange?.nsRange {
                    range = nsRange
                }
                rect = textRect
            }
            textLongPressAction?(self, innerText, range, rect)
        }
        if let highlight = highlight {
            let longPressAction = highlight.longPressAction ?? highlightLongPressAction
            if let action = longPressAction {
                let start = TextPosition(offset: highlightRange.location)
                let end = TextPosition(
                    offset: highlightRange.location + highlightRange.length,
                    affinity: .backward
                )
                let range = TextRange(start: start, end: end)
                guard var rect: CGRect = innerLayout?.rect(for: range) else {
                    return
                }
                rect = _convertRect(fromLayout: rect)
                action(self, innerText, highlightRange, rect)
                _removeHighlight(animated: true)
                state.isTrackingTouch = false
            }
        }
    }
    
    private func _getHighlight(at point: CGPoint, range: NSRangePointer?) -> TextHighlight? {
        var point = point
        
        guard let isContains = innerLayout?.containsHighlight, isContains else {
            return nil
        }
        point = _convertPoint(toLayout: point)
        
        guard let textRange = innerLayout?.textRange(at: point) else {
            return nil
        }
        
        var startIndex = textRange.start.offset
        if startIndex == innerText.length {
            if startIndex > 0 {
                startIndex -= 1
            }
        }
        let highlightRange = NSRangePointer.allocate(capacity: 1)
        defer {
            highlightRange.deallocate()
        }
        
        guard let highlight = innerText.attribute(
            TextAttribute.textHighlight,
            at: startIndex, longestEffectiveRange: highlightRange,
            in: NSRange(location: 0, length: innerText.length)
        ) as? TextHighlight else {
            return nil
        }
        
        range?.pointee = highlightRange.pointee
        return highlight
    }
    
    private func _showHighlight(animated: Bool) {
        guard let highlight = highlight else { return }
        if highlightLayout == nil {
            let highlightText = innerText.mutableCopy() as? NSMutableAttributedString
            let newAttrs = highlight.attributes
            for (key, value) in newAttrs {
                highlightText?.setAttribute(key, value: value, range: highlightRange)
            }
            highlightLayout = TextLayout(container: innerContainer, text: highlightText)
            shrinkHighlightLayout = Self._shrinkLayout(with: highlightLayout)
            if highlightLayout == nil {
                self.highlight = nil
            }
        }
        
        if highlightLayout != nil, !state.isShowingHighlight {
            state.isShowingHighlight = true
            state.isContentsNeedFade = animated
            _setLayoutNeedRedraw()
        }
    }
    
    private func _hideHighlight(animated: Bool) {
        if state.isShowingHighlight {
            state.isShowingHighlight = false
            state.isContentsNeedFade = animated
            _setLayoutNeedRedraw()
        }
    }
    
    private func _removeHighlight(animated: Bool) {
        _hideHighlight(animated: animated)
        highlight = nil
        highlightLayout = nil
        shrinkHighlightLayout = nil
    }
    
    private func _endTouch() {
        _endLongPressTimer()
        _removeHighlight(animated: true)
        state.isTrackingTouch = false
    }
    
    private func _convertPoint(toLayout point: CGPoint) -> CGPoint {
        guard let innerLayout = innerLayout else {
            return point
        }
        var newPoint = point
        let boundingSize = innerLayout.textBoundingSize
        if innerLayout.container.isVerticalForm {
            var width = innerLayout.textBoundingSize.width
            if width < bounds.size.width {
                width = bounds.size.width
            }
            newPoint.x += innerLayout.container.size.width - width
            if textVerticalAlignment == TextVerticalAlignment.center {
                newPoint.x += (bounds.size.width - boundingSize.width) * 0.5
            } else if textVerticalAlignment == TextVerticalAlignment.bottom {
                newPoint.x += bounds.size.width - boundingSize.width
            }
            return newPoint
        } else {
            if textVerticalAlignment == TextVerticalAlignment.center {
                newPoint.y -= (bounds.size.height - boundingSize.height) * 0.5
            } else if textVerticalAlignment == TextVerticalAlignment.bottom {
                newPoint.y -= bounds.size.height - boundingSize.height
            }
            return newPoint
        }
    }
    
    private func _convertPoint(fromLayout point: CGPoint) -> CGPoint {
        guard let innerLayout = innerLayout else {
            return point
        }
        var newPoint = point
        let boundingSize: CGSize = innerLayout.textBoundingSize
        if innerLayout.container.isVerticalForm {
            var width = innerLayout.textBoundingSize.width
            if width < bounds.size.width {
                width = bounds.size.width
            }
            newPoint.x -= innerLayout.container.size.width - width
            if boundingSize.width < bounds.size.width {
                if textVerticalAlignment == TextVerticalAlignment.center {
                    newPoint.x -= (bounds.size.width - boundingSize.width) * 0.5
                } else if textVerticalAlignment == TextVerticalAlignment.bottom {
                    newPoint.x -= bounds.size.width - boundingSize.width
                }
            }
            return newPoint
        } else {
            if boundingSize.height < bounds.size.height {
                if textVerticalAlignment == TextVerticalAlignment.center {
                    newPoint.y += (bounds.size.height - boundingSize.height) * 0.5
                } else if textVerticalAlignment == TextVerticalAlignment.bottom {
                    newPoint.y += bounds.size.height - boundingSize.height
                }
            }
            return newPoint
        }
    }
    
    private func _convertRect(toLayout rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin = _convertPoint(toLayout: rect.origin)
        return rect
    }
    
    private func _convertRect(fromLayout rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin = _convertPoint(fromLayout: rect.origin)
        return rect
    }
    
    private func _shadowFromProperties() -> NSShadow? {
        if !(shadowColor != nil) || shadowBlurRadius < 0 {
            return nil
        }
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor
#if !TARGET_INTERFACE_BUILDER
        shadow.shadowOffset = shadowOffset
#else
        shadow.shadowOffset = CGSize(width: shadowOffset.x, height: shadowOffset.y)
#endif
        shadow.shadowBlurRadius = shadowBlurRadius
        return shadow
    }
    
    private func _updateOuterLineBreakMode() {
        if innerContainer.truncationType != .none {
            switch innerContainer.truncationType {
            case .start:
                _lineBreakMode = NSLineBreakMode.byTruncatingHead
            case .end:
                _lineBreakMode = NSLineBreakMode.byTruncatingTail
            case .middle:
                _lineBreakMode = NSLineBreakMode.byTruncatingMiddle
            default:
                break
            }
        } else {
            _lineBreakMode = innerText.lineBreakMode
        }
    }
    
    private func _updateOuterTextProperties() {
        _text = innerText.plainText(for: NSRange(location: 0, length: innerText.length))
        _font = innerText.font ?? Self.defaultFont
        _textColor = innerText.textColor ?? UIColor.black
        
        _textAlignment = innerText.alignment
        _lineBreakMode = innerText.lineBreakMode
        let shadow: NSShadow? = innerText.shadow
        _shadowColor = shadow?.shadowColor as? UIColor
        // TARGET_INTERFACE_BUILDER
        _shadowOffset = shadow?.shadowOffset ?? .zero
        
        _shadowBlurRadius = shadow?.shadowBlurRadius ?? 0
        _attributedText = innerText
        _updateOuterLineBreakMode()
    }
    
    private func _updateOuterContainerProperties() {
        _truncationToken = innerContainer.truncationToken
        _numberOfLines = innerContainer.maximumNumberOfRows
        _textContainerPath = innerContainer.path
        _exclusionPaths = innerContainer.exclusionPaths
        _textContainerInset = innerContainer.insets
        _verticalForm = innerContainer.isVerticalForm
        _linePositionModifier = innerContainer.linePositionModifier
        _updateOuterLineBreakMode()
    }
    
    private func _clearContents() {
        // swiftlint:disable:next force_cast
        let image = layer.contents as! CGImage?
        layer.contents = nil
        if image != nil {
            DispatchQueue.global(qos: .default).async {
                _ = image
            }
        }
    }
    
    private func _initLabel() {
        (layer as? TextAsyncLayer)?.isDisplaysAsynchronously = false
        layer.contentsScale = UIScreen.main.scale
        contentMode = .redraw
        
        TextDebugOption.add(self)
        
        innerContainer.truncationType = .end
        innerContainer.maximumNumberOfRows = numberOfLines
        
        isAccessibilityElement = true
    }

    // MARK: - TextAsyncLayerDelegate
    // swiftlint:disable:next function_body_length
    public func newAsyncDisplayTask() -> TextAsyncLayerDisplayTask? {
        // capture current context
        let tmpContentsNeedFade = state.isContentsNeedFade
        var tmpText: NSAttributedString = innerText
        var tmpContainer: TextContainer? = innerContainer
        let tmpVerticalAlignment: TextVerticalAlignment = textVerticalAlignment
        let tmpDebugOption: TextDebugOption? = debugOption
        
        let tmpLayoutNeedUpdate = state.isLayoutNeedUpdate
        let tmpFadeForAsync: Bool = isDisplaysAsynchronously && isFadeOnAsynchronouslyDisplay
        var tmpLayout: TextLayout? = (state.isShowingHighlight && highlightLayout != nil) ?
            _highlightLayout() :
            _innerLayout()
        var tmpShrinkLayout: TextLayout?
        var tmpLayoutUpdated = false
        if tmpLayoutNeedUpdate {
            if let copy = tmpText.copy() as? NSAttributedString {
                tmpText = copy
            }
            tmpContainer = tmpContainer?.copy() as? TextContainer
        }
        
        // create display task
        let task = TextAsyncLayerDisplayTask()
        
        task.willDisplay = { layer in
            layer?.removeAnimation(forKey: "contents")
            
            // If the attachment is not in new layout, or we don't know the new layout currently,
            // the attachment should be removed.
            for view in self.attachmentViews {
                if tmpLayoutNeedUpdate || !(tmpLayout?.attachmentContentsSet?.contains(view) ?? false) {
                    if view.superview == self {
                        view.removeFromSuperview()
                    }
                }
            }
            for layer in self.attachmentLayers {
                if tmpLayoutNeedUpdate || !(tmpLayout?.attachmentContentsSet?.contains(layer) ?? false) {
                    if layer.superlayer == self.layer {
                        layer.removeFromSuperlayer()
                    }
                }
            }
            self.attachmentViews.removeAll()
            self.attachmentLayers.removeAll()
        }
        
        task.display = { context, size, isCancelled in
            if isCancelled() {
                return
            }
            guard tmpText.length > 0 else {
                return
            }
            
            var drawLayout: TextLayout? = tmpLayout
            if tmpLayoutNeedUpdate {
                tmpLayout = TextLayout(container: tmpContainer, text: tmpText)
                tmpShrinkLayout = Self._shrinkLayout(with: tmpLayout)
                if isCancelled() {
                    return
                }
                tmpLayoutUpdated = true
                drawLayout = (tmpShrinkLayout != nil) ? tmpShrinkLayout : tmpLayout
            }
            
            let boundingSize: CGSize = drawLayout?.textBoundingSize ?? .zero
            var point = CGPoint.zero
            if tmpVerticalAlignment == TextVerticalAlignment.center {
                if let isVertical = drawLayout?.container.isVerticalForm, isVertical {
                    point.x = -(size.width - boundingSize.width) * 0.5
                } else {
                    point.y = (size.height - boundingSize.height) * 0.5
                }
            } else if tmpVerticalAlignment == TextVerticalAlignment.bottom {
                if let isVertical = drawLayout?.container.isVerticalForm, isVertical {
                    point.x = -(size.width - boundingSize.width)
                } else {
                    point.y = size.height - boundingSize.height
                }
            }
            point = point.roundFlattened()
            drawLayout?.draw(
                in: context,
                size: size,
                point: point,
                view: nil,
                layer: nil,
                debug: tmpDebugOption,
                cancel: isCancelled
            )
        }
        
        task.didDisplay = { layer, finished in
            var drawLayout = tmpLayout
            if tmpLayoutUpdated, tmpShrinkLayout != nil {
                drawLayout = tmpShrinkLayout
            }
            if !finished {
                // If the display task is cancelled, we should clear the attachments.
                for attachment in drawLayout?.attachments ?? [] {
                    if let view = attachment.content as? UIView {
                        if view.superview === layer.delegate {
                            view.removeFromSuperview()
                        }
                    } else if let layer = attachment.content as? CALayer {
                        if layer.superlayer == layer {
                            layer.removeFromSuperlayer()
                        }
                    }
                }
                return
            }
            layer.removeAnimation(forKey: "contents")
            
            guard let view = layer.delegate as? AttributedLabel else {
                return
            }
            if view.state.isLayoutNeedUpdate, tmpLayoutUpdated {
                view.innerLayout = tmpLayout
                view.shrinkInnerLayout = tmpShrinkLayout
                view.state.isLayoutNeedUpdate = false
            }
            
            let size = layer.bounds.size
            let boundingSize: CGSize = drawLayout?.textBoundingSize ?? .zero
            var point = CGPoint.zero
            if tmpVerticalAlignment == TextVerticalAlignment.center {
                if let isVertical = drawLayout?.container.isVerticalForm, isVertical {
                    point.x = -(size.width - boundingSize.width) * 0.5
                } else {
                    point.y = (size.height - boundingSize.height) * 0.5
                }
            } else if tmpVerticalAlignment == TextVerticalAlignment.bottom {
                if let isVertical = drawLayout?.container.isVerticalForm, isVertical {
                    point.x = -(size.width - boundingSize.width)
                } else {
                    point.y = size.height - boundingSize.height
                }
            }
            point = point.roundFlattened()
            drawLayout?.draw(in: nil, size: size, point: point, view: view, layer: layer, debug: nil, cancel: nil)
            for attachment in drawLayout?.attachments ?? [] {
                if let view = attachment.content as? UIView {
                    self.attachmentViews.append(view)
                } else if let layer = attachment.content as? CALayer {
                    self.attachmentLayers.append(layer)
                }
            }
            
            if tmpContentsNeedFade {
                let transition = CATransition()
                transition.duration = highlightFadeDuration
                transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
                transition.type = .fade
                layer.add(transition, forKey: "contents")
            } else if tmpFadeForAsync {
                let transition = CATransition()
                transition.duration = asyncFadeDuration
                transition.timingFunction = CAMediaTimingFunction(name: .easeOut)
                transition.type = .fade
                layer.add(transition, forKey: "contents")
            }
        }
        
        return task
    }
    
    deinit {
        TextDebugOption.remove(self)
        longPressTimer?.invalidate()
    }
}
// swiftlint:enable type_body_length
