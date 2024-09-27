//
//  AttributedTextView.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

#if canImport(SDWebImage)
import SDWebImage
#endif

// swiftlint:disable file_length
/// AttributedTextViewDelegate 协议定义了一组可选的方法
///
/// 你可以用来接收 AttributedTextView 对象的编辑相关信息
///
/// 该 API 和行为与 UITextViewDelegate 类似, 更多信息请参见 UITextViewDelegate 的文档
///
@objc
public protocol AttributedTextViewDelegate: UIScrollViewDelegate {
    @objc
    optional func textViewShouldBeginEditing(
        _ textView: AttributedTextView
    ) -> Bool
    
    @objc
    optional func textViewShouldEndEditing(
        _ textView: AttributedTextView
    ) -> Bool
    
    @objc
    optional func textViewDidBeginEditing(
        _ textView: AttributedTextView
    )
    
    @objc
    optional func textViewDidEndEditing(
        _ textView: AttributedTextView
    )
    
    @objc
    optional func textView(
        _ textView: AttributedTextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool
    
    @objc
    optional func textViewDidChange(
        _ textView: AttributedTextView
    )
    
    @objc
    optional func textViewDidChangeSelection(
        _ textView: AttributedTextView
    )
    
    @objc
    optional func textView(
        _ textView: AttributedTextView,
        shouldTap highlight: TextHighlight,
        in characterRange: NSRange
    ) -> Bool
    
    @objc
    optional func textView(
        _ textView: AttributedTextView,
        didTap highlight: TextHighlight,
        in characterRange: NSRange,
        rect: CGRect
    )
    
    @objc
    optional func textView(
        _ textView: AttributedTextView,
        shouldLongPress highlight: TextHighlight,
        in characterRange: NSRange
    ) -> Bool
    
    @objc
    optional func textView(
        _ textView: AttributedTextView,
        didLongPress highlight: TextHighlight,
        in characterRange: NSRange,
        rect: CGRect
    )
}

/// 撤销层级限制
private let defaultUndoLevelLimited: Int = 20

/// 自动滚动最小时间
private let autoScrollMinimumDuration = 0.1
/// 长按触发时间
private let longPressMinimumDuration = 0.5
/// 长按允许移动的范围
private let longPressAllowableMovement: Float = 10.0

/// 放大镜修正值
private let magnifierRangedTrackFixValue: CGFloat = -6
/// 放大镜弹出三角偏移
private let magnifierRangedPopoverOffset: CGFloat = 4
/// 放大镜捕获内容偏移
private let magnifierRangedCaptureOffset: CGFloat = -6

/// 高亮渐隐时间
private let highlightFadeDuration: TimeInterval = 0.15

/// 容器默认缩进
private let containerDefaultInsets = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
/// 容器垂直布局的默认缩进
private let containerVerticalDefaultInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)

/// 文本抓取器方向
public enum TextGrabberDirection: UInt {
    case none = 0
    case start = 1
    case end = 2
}

/// 文本移动方向
public enum TextMoveDirection: UInt {
    case none = 0
    case left = 1
    case top = 2
    case right = 3
    case bottom = 4
}

/// An object that captures the state of the text view. Used for undo and redo.
private class TextViewUndoObject: NSObject {
    var text: NSAttributedString?
    var selectedRange: NSRange?
    
    override init() {
        super.init()
    }
    
    convenience init(text: NSAttributedString?, range: NSRange) {
        self.init()
        self.text = text ?? NSAttributedString()
        selectedRange = range
    }
}

// swiftlint:disable type_body_length
///  The AttributedTextView class implements the behavior for a scrollable, multiline text region.
///
///  The API and behavior is similar to UITextView, but provides more features:
///
///  * It extends the CoreText attributes to support more text effects.
///  * It allows to add UIImage, UIView and CALayer as text attachments.
///  * It allows to add 'highlight' link to some range of text to allow user interact with.
///  * It allows to add exclusion paths to control text container's shape.
///  * It supports vertical form layout to display and edit CJK text.
///  * It allows user to copy/paste image and attributed text from/to text view.
///  * It allows to set an attributed text as placeholder.
///
/// See `NSAttributedString+AttributedText.swift` for more convenience methods to set the attributes.
/// See TextAttribute.swift and TextLayout.swift for more information.
open class AttributedTextView: UIScrollView,
    UITextInput,
    UITextInputTraits,
    UIScrollViewDelegate,
    TextDebugTarget,
    TextKeyboardObserver,
    NSSecureCoding {
    
    public struct State {
        /// TextGrabberDirection, current tracking grabber
        public var trackingGrabber = TextGrabberDirection.none
        /// track the caret
        public var isTrackingCaret = false
        /// track pre-select
        public var isTrackingPreviousSelect = false
        /// is in touch phase
        public var isTrackingTouch = false
        /// don't forward event to next responder
        public var isSwallowTouch = false
        /// TextMoveDirection, move direction after touch began
        public var isTouchMoved = TextMoveDirection.none
        /// show selected range but not first responder
        public var isSelectedWithoutEdit = false
        /// delete a binding text range
        public var isDeleteConfirm = false
        /// ignore become first responder temporary
        public var isFirstResponderIgnored = false
        /// ignore begin tracking touch temporary
        public var isTouchBeganIgnored = false
        
        public var isShowingMagnifierCaret = false
        public var isShowingMenu = false
        public var isShowingHighlight = false
        
        /// apply the typing attributes once
        public var isTypingAttributesOnce = false
        /// suppress the typing attributes update
        public var isSuppressSetTypingAttributes = false
        /// select all once when become first responder
        public var isClearsOnInsertionOnce = false
        /// auto scroll did tick scroll at this timer period
        public var isAutoScrollTicked = false
        /// the selection grabber dot has displayed at least once
        public var isFirstShowDot = false
        /// the layout or selection view is 'dirty' and need update
        public var isNeedsUpdate = false
        /// the placeholder need update it's contents
        public var isPlaceholderNeedsUpdate = false
        
        public var isInsideUndoBlock = false
        public var isFirstResponderBeforeUndoAlert = false
    }
    
    /// 文本已开始编辑的通知
    public static let textViewTextDidBeginEditingNotification = Notification.Name("TextViewTextDidBeginEditing")
    /// 文本已改变的通知
    public static let textViewTextDidChangeNotification = Notification.Name("TextViewTextDidChange")
    /// 文本已结束编辑的通知
    public static let textViewTextDidEndEditingNotification = Notification.Name("TextViewTextDidEndEditing")
    
    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// 分词器
    public lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: UITextView())
    /// 标记的文本范围
    public var markedTextRange: UITextRange? { _markedTextRange }
    
    // MARK: - Accessing the Delegate

    override open weak var delegate: UIScrollViewDelegate? {
        get {
            return _outerDelegate
        }
        set {
            _outerDelegate = newValue as? AttributedTextViewDelegate
        }
    }
    
    // MARK: - Configuring the Text Attributes
    
    private var _text = ""
    /// The text displayed by the text view.
    /// Set a new value to this property also replaces the text in `attributedText`.
    /// Get the value returns the plain text in `attributedText`.
    public var text: String {
        get {
            return _text
        }
        set {
            if _text == newValue {
                return
            }
            _setText(newValue)
            
            state.isSelectedWithoutEdit = false
            state.isDeleteConfirm = false
            _endTouchTracking()
            _hideMenu()
            _resetUndoAndRedoStack()
            replace(TextRange(range: NSRange(location: 0, length: _innerText.length)), withText: _text)
        }
    }
    
    private lazy var _font: UIFont? = AttributedTextView._defaultFont
    /// The font of the text. Default is 12-point system font.
    /// Set a new value to this property also causes the new font to be applied to the entire `attributedText`.
    /// Get the value returns the font at the head of `attributedText`.
    public var font: UIFont? {
        get {
            return _font
        }
        set {
            if _font == newValue {
                return
            }
            _setFont(newValue)
            
            state.isTypingAttributesOnce = false
            _typingAttributesHolder.setFont(newValue)
            _innerText.setFont(newValue)
            _resetUndoAndRedoStack()
            _commitUpdate()
        }
    }
    
    private var _textColor: UIColor? = UIColor.black
    /// The color of the text. Default is black.
    /// Set a new value to this property also causes the new color to be applied to the entire `attributedText`.
    /// Get the value returns the color at the head of `attributedText`.
    public var textColor: UIColor? {
        get {
            return _textColor
        }
        set {
            if _textColor == newValue {
                return
            }
            _setTextColor(newValue)
            
            state.isTypingAttributesOnce = false
            _typingAttributesHolder.setTextColor(newValue)
            _innerText.setTextColor(newValue)
            _resetUndoAndRedoStack()
            _commitUpdate()
        }
    }
    
    private var _textAlignment = NSTextAlignment.natural
    /// The technique to use for aligning the text. Default is NSTextAlignmentNatural.
    /// Set a new value to this property also causes the new alignment to be applied to the entire `attributedText`.
    /// Get the value returns the alignment at the head of `attributedText`.
    public var textAlignment: NSTextAlignment {
        get {
            return _textAlignment
        }
        set {
            if _textAlignment == newValue {
                return
            }
            _setTextAlignment(newValue)
            
            _typingAttributesHolder.setAlignment(newValue)
            _innerText.setAlignment(newValue)
            _resetUndoAndRedoStack()
            _commitUpdate()
        }
    }
    
    private var _textVerticalAlignment = TextVerticalAlignment.top
    /// The text vertical aligmnent in container.
    ///
    /// Default is TextVerticalAlignment.top.
    public var textVerticalAlignment: TextVerticalAlignment {
        get {
            return _textVerticalAlignment
        }
        set {
            if _textVerticalAlignment == newValue {
                return
            }
            willChangeValue(forKey: "textVerticalAlignment")
            _textVerticalAlignment = newValue
            didChangeValue(forKey: "textVerticalAlignment")
            _containerView.textVerticalAlignment = newValue
            _commitUpdate()
        }
    }
    
    private var _dataDetectorTypes = UIDataDetectorTypes(rawValue: 0)
    /// The types of data converted to clickable URLs in the text view. Default is UIDataDetectorTypeNone.
    /// The tap or long press action should be handled by delegate.
    public var dataDetectorTypes: UIDataDetectorTypes {
        get {
            return _dataDetectorTypes
        }
        set {
            if _dataDetectorTypes == newValue {
                return
            }
            _setDataDetectorTypes(newValue)
            let type = TextUtilities.checkingType(from: newValue)
            _dataDetector = type.rawValue != 0 ? try? NSDataDetector(types: type.rawValue) : nil
            _resetUndoAndRedoStack()
            _commitUpdate()
        }
    }
    
    private var _linkTextAttributes: [NSAttributedString.Key: Any]?
    /// The attributes to apply to links at normal state. Default is light blue color.
    /// When a range of text is detected by the `dataDetectorTypes`, this value would be
    /// used to modify the original attributes in the range.
    public var linkTextAttributes: [NSAttributedString.Key: Any]? {
        get {
            return _linkTextAttributes
        }
        set {
            // swiftlint:disable:next legacy_objc_type
            let dic1 = _linkTextAttributes as NSDictionary?
            // swiftlint:disable:next legacy_objc_type
            let dic2 = newValue as NSDictionary?
            if dic1 == dic2 || dic1?.isEqual(dic2) ?? false {
                return
            }
            _setLinkTextAttributes(newValue)
            if _dataDetector != nil {
                _commitUpdate()
            }
        }
    }
    
    private var _highlightTextAttributes: [NSAttributedString.Key: Any]?
    /// The attributes to apply to links at highlight state. Default is a gray border.
    /// When a range of text is detected by the `dataDetectorTypes` and the range was touched by user,
    /// this value would be used to modify the original attributes in the range.
    public var highlightTextAttributes: [NSAttributedString.Key: Any]? {
        get {
            return _highlightTextAttributes
        }
        set {
            // swiftlint:disable:next legacy_objc_type
            let dic1 = _highlightTextAttributes as NSDictionary?
            // swiftlint:disable:next legacy_objc_type
            let dic2 = newValue as NSDictionary?
            if dic1 == dic2 || dic1?.isEqual(dic2) ?? false {
                return
            }
            _setHighlightTextAttributes(newValue)
            if _dataDetector != nil {
                _commitUpdate()
            }
        }
    }
    
    private var _typingAttributes: [NSAttributedString.Key: Any]?
    /// The attributes to apply to new text being entered by the user.
    /// When the text view's selection changes, this value is reset automatically.
    public var typingAttributes: [NSAttributedString.Key: Any]? {
        get {
            return _typingAttributes
        }
        set {
            state.isSuppressSetTypingAttributes = false
            _setTypingAttributes(newValue)
            state.isSuppressSetTypingAttributes = true
            state.isTypingAttributesOnce = true
            for (key, obj) in newValue ?? [:] {
                _typingAttributesHolder.setAttribute(key, value: obj)
            }
            _commitUpdate()
        }
    }
    
    private var _attributedText = NSAttributedString()
    /// The styled text displayed by the text view.
    /// Set a new value to this property also replaces the value of the `text`, `font`, `textColor`,
    /// `textAlignment` and other properties in text view.
    ///
    /// It only support the attributes declared in CoreText and TextAttribute.
    /// See `NSAttributedString+AttributedText.swift` for more convenience methods to set the attributes.
    public var attributedText: NSAttributedString? {
        get {
            return _attributedText
        }
        set {
            guard _attributedText != newValue else {
                return
            }
            _setAttributedText(newValue)
            state.isTypingAttributesOnce = false
            
            guard let text = _attributedText.mutableCopy() as? NSMutableAttributedString, text.length > 0 else {
                replace(TextRange(range: NSRange(location: 0, length: _innerText.length)), withText: "")
                return
            }
            if let should = _outerDelegate?.textView?(
                self,
                shouldChangeTextIn: NSRange(location: 0, length: _innerText.length),
                replacementText: text.string
            ) {
                if !should {
                    return
                }
            }
            
            state.isSelectedWithoutEdit = false
            state.isDeleteConfirm = false
            _endTouchTracking()
            _hideMenu()
            
            _inputDelegate?.selectionWillChange(self)
            _inputDelegate?.textWillChange(self)
            _innerText = text
            _parseText()
            _selectedTextRange = TextRange(range: NSRange(location: 0, length: _innerText.length))
            _inputDelegate?.textDidChange(self)
            _inputDelegate?.selectionDidChange(self)
            
            _setAttributedText(text)
            if _innerText.length > 0 {
                _typingAttributesHolder.setAttributes([:], range: _typingAttributesHolder.rangeOfAll)
                if let attrs = _innerText.attributes(at: _innerText.length - 1) {
                    for attr in attrs {
                        _typingAttributesHolder.setAttribute(attr.key, value: attr.value)
                    }
                }
            }
            
            _updateOuterProperties()
            _updateLayout()
            _updateSelectionView()
            
            if isFirstResponder {
                _scrollRangeToVisible(_selectedTextRange)
            }
            
            _outerDelegate?.textViewDidChange?(self)
            
            NotificationCenter.default.post(name: Self.textViewTextDidChangeNotification, object: self)
            
            if !state.isInsideUndoBlock {
                _resetUndoAndRedoStack()
            }
        }
    }
    
    private var _textParser: TextParser?
    /// When `text` or `attributedText` is changed, the parser will be called to modify the text.
    /// It can be used to add code highlighting or emoticon replacement to text view.
    ///
    /// The default value is nil.
    ///
    /// See `TextParser` protocol for more information.
    public var textParser: TextParser? {
        get {
            return _textParser
        }
        set {
            if _textParser === newValue || _textParser?.isEqual(newValue) ?? false {
                return
            }
            _setTextParser(newValue)
            if textParser != nil, !text.isEmpty {
                replace(TextRange(range: NSRange(location: 0, length: text.length)), withText: text)
            }
            _resetUndoAndRedoStack()
            _commitUpdate()
        }
    }
    
    /// The current text layout in text view (readonly).
    /// It can be used to query the text layout information.
    public var textLayout: TextLayout? {
        _updateIfNeeded()
        return _innerLayout
    }
    
    // MARK: - Configuring the Placeholde
    
    private var _placeholderText: String?
    /// The placeholder text displayed by the text view (when the text view is empty).
    /// Set a new value to this property also replaces the text in `placeholderAttributedText`.
    /// Get the value returns the plain text in `placeholderAttributedText`.
    public var placeholderText: String? {
        get {
            return _placeholderText
        }
        set {
            if let placeholder = _placeholderAttributedText, placeholder.length > 0 {
                (placeholder as? NSMutableAttributedString)?.replaceCharacters(
                    in: NSRange(location: 0, length: placeholder.length),
                    with: newValue ?? ""
                )
                
                (_placeholderAttributedText as? NSMutableAttributedString)?.setFont(placeholderFont)
                (_placeholderAttributedText as? NSMutableAttributedString)?.setTextColor(placeholderTextColor)
            } else {
                if let newValue = newValue, newValue.length > 0 {
                    let attributed = NSMutableAttributedString(string: newValue)
                    if _placeholderFont == nil {
                        _placeholderFont = _font ?? Self._defaultFont
                    }
                    if _placeholderTextColor == nil {
                        _placeholderTextColor = Self._defaultPlaceholderColor
                    }
                    attributed.setFont(_placeholderFont)
                    attributed.setTextColor(_placeholderTextColor)
                    _placeholderAttributedText = attributed
                }
            }
            _placeholderText = _placeholderAttributedText?.plainText(
                for: NSRange(location: 0, length: _placeholderAttributedText?.length ?? 0)
            )
            _commitPlaceholderUpdate()
        }
    }
    
    private var _placeholderFont: UIFont?
    /// The font of the placeholder text. Default is same as `font` property.
    /// Set a new value to this property also causes the new font to be applied to the entire `placeholderAttributedText`.
    /// Get the value returns the font at the head of `placeholderAttributedText`.
    public var placeholderFont: UIFont? {
        get {
            return _placeholderFont
        }
        set {
            _placeholderFont = newValue
            (_placeholderAttributedText as? NSMutableAttributedString)?.setFont(_placeholderFont)
            _commitPlaceholderUpdate()
        }
    }
    
    private var _placeholderTextColor: UIColor?
    /// The color of the placeholder text. Default is gray.
    /// Set a new value to this property also causes the new color to be applied to the entire `placeholderAttributedText`.
    /// Get the value returns the color at the head of `placeholderAttributedText`.
    public var placeholderTextColor: UIColor? {
        get {
            return _placeholderTextColor
        }
        set {
            _placeholderTextColor = newValue
            (_placeholderAttributedText as? NSMutableAttributedString)?.setTextColor(_placeholderTextColor)
            _commitPlaceholderUpdate()
        }
    }
    
    private var _placeholderAttributedText: NSAttributedString?
    /// The styled placeholder text displayed by the text view (when the text view is empty).
    /// Set a new value to this property also replaces the value of the `placeholderText`,
    /// `placeholderFont`, `placeholderTextColor`.
    ///
    /// It only support the attributes declared in CoreText and TextAttribute.
    /// See `NSAttributedString+AttributedText.swift` for more convenience methods to set the attributes.
    public var placeholderAttributedText: NSAttributedString? {
        get {
            return _placeholderAttributedText
        }
        set {
            _placeholderAttributedText = newValue?.mutableCopy() as? NSAttributedString
            _placeholderText = placeholderAttributedText?.plainText(
                for: NSRange(location: 0, length: newValue?.length ?? 0)
            )
            _placeholderFont = _placeholderAttributedText?.font
            _placeholderTextColor = _placeholderAttributedText?.textColor
            _commitPlaceholderUpdate()
        }
    }
    
    // MARK: - Configuring the Text Container
    
    private var _textContainerInset = containerDefaultInsets
    /// The inset of the text container's layout area within the text view's content area.
    public var textContainerInset: UIEdgeInsets {
        get {
            return _textContainerInset
        }
        set {
            if _textContainerInset == newValue {
                return
            }
            _setTextContainerInset(newValue)
            _innerContainer.insets = newValue
            _commitUpdate()
        }
    }
    
    private var _exclusionPaths: [UIBezierPath]?
    /// An array of UIBezierPath objects representing the exclusion paths inside the
    /// receiver's bounding rectangle. Default value is nil.
    public var exclusionPaths: [UIBezierPath]? {
        get {
            return _exclusionPaths
        }
        set {
            if _exclusionPaths == newValue {
                return
            }
            _setExclusionPaths(newValue)
            _innerContainer.exclusionPaths = newValue
            
            if _innerContainer.isVerticalForm {
                let trans = CGAffineTransform(translationX: _innerContainer.size.width - bounds.size.width, y: 0)
                for path in _innerContainer.exclusionPaths ?? [] {
                    path.apply(trans)
                }
            }
            _commitUpdate()
        }
    }
    
    private var _verticalForm = false
    /// Whether the receiver's layout orientation is vertical form.
    ///
    /// Default is `false`.
    /// It may used to edit/display CJK text.
    public var isVerticalForm: Bool {
        get {
            return _verticalForm
        }
        set {
            if _verticalForm == newValue {
                return
            }
            _setVerticalForm(newValue)
            _innerContainer.isVerticalForm = newValue
            _selectionView.isVerticalForm = newValue
            
            _updateInnerContainerSize()
            
            if isVerticalForm {
                if _innerContainer.insets == containerDefaultInsets {
                    _innerContainer.insets = containerVerticalDefaultInsets
                    _setTextContainerInset(containerVerticalDefaultInsets)
                }
            } else {
                if _innerContainer.insets == containerVerticalDefaultInsets {
                    _innerContainer.insets = containerDefaultInsets
                    _setTextContainerInset(containerDefaultInsets)
                }
            }
            
            _innerContainer.exclusionPaths = exclusionPaths
            if newValue {
                let trans = CGAffineTransform(translationX: _innerContainer.size.width - bounds.size.width, y: 0)
                for path in _innerContainer.exclusionPaths ?? [] {
                    path.apply(trans)
                }
            }
            
            _keyboardChanged()
            _commitUpdate()
        }
    }
    
    private var _linePositionModifier: TextLinePositionModifier?
    /// The text line position modifier used to modify the lines' position in layout.
    /// See `TextLinePositionModifier` protocol for more information.
    public weak var linePositionModifier: TextLinePositionModifier? {
        get {
            return _linePositionModifier
        }
        set {
            if _linePositionModifier === newValue || _linePositionModifier?.isEqual(newValue) ?? false {
                return
            }
            _setLinePositionModifier(newValue)
            _innerContainer.linePositionModifier = newValue
            _commitUpdate()
        }
    }
    
    /// The debug option to display CoreText layout result.
    /// The default value is [TextDebugOption sharedDebugOption].
    public var debugOption: TextDebugOption? {
        get {
            return _containerView.debugOption
        }
        set {
            _containerView.debugOption = newValue
        }
    }
    
    private var _selectedRange = NSRange(location: 0, length: 0)
    /// The current selection range of the receiver.
    public var selectedRange: NSRange {
        get {
            return _selectedRange
        }
        set {
            if NSEqualRanges(_selectedRange, newValue) {
                return
            }
            if _markedTextRange != nil {
                return
            }
            state.isTypingAttributesOnce = false
            
            var range = TextRange(range: newValue)
            guard let fixedRange = _correctedTextRange(range) else {
                return
            }
            range = fixedRange
            _endTouchTracking()
            _selectedTextRange = range
            _updateSelectionView()
            
            _setSelectedRange(range.nsRange)
            
            if !state.isInsideUndoBlock {
                _resetUndoAndRedoStack()
            }
        }
    }
    
    /// A Boolean value indicating whether inserting text replaces the previous contents.
    ///
    /// The default value is `false`.
    public var isClearsOnInsertion = false {
        didSet {
            if isClearsOnInsertion == oldValue {
                return
            }
            if isClearsOnInsertion {
                if isFirstResponder {
                    selectedRange = NSRange(location: 0, length: _attributedText.length)
                } else {
                    state.isClearsOnInsertionOnce = true
                }
            }
        }
    }
    
    /// A Boolean value indicating whether the receiver is isSelectable.
    ///
    /// Default is `true`.
    ///
    /// When the value of this property is `false`, user cannot select content or edit text.
    public var isSelectable = true {
        didSet {
            if isSelectable == oldValue {
                return
            }
            if !isSelectable {
                if isFirstResponder {
                    resignFirstResponder()
                } else {
                    state.isSelectedWithoutEdit = false
                    _endTouchTracking()
                    _hideMenu()
                    _updateSelectionView()
                }
            }
        }
    }
    
    /// A Boolean value indicating whether the receiver is isHighlightable.
    ///
    /// Default is `true`.
    ///
    /// When the value of this property is `false`, user cannot interact with the highlight range of text.
    public var isHighlightable = true {
        didSet {
            if isHighlightable == oldValue {
                return
            }
            _commitUpdate()
        }
    }
    
    /// A Boolean value indicating whether the receiver is isEditable.
    ///
    /// Default is `true`.
    ///
    /// When the value of this property is `false`, user cannot edit text.
    public var isEditable = true {
        didSet {
            if isEditable == oldValue {
                return
            }
            if !isEditable {
                resignFirstResponder()
            }
        }
    }
    
    /// A Boolean value indicating whether the receiver can paste image from pasteboard.
    ///
    /// Default is `false`.
    ///
    /// When the value of this property is `true`, user can paste image from pasteboard via "paste" menu.
    public var isAllowsPasteImage = false
    
    /// A Boolean value indicating whether the receiver can paste attributed text from pasteboard.
    ///
    /// Default is `false`.
    ///
    /// When the value of this property is `true`, user can paste attributed text from pasteboard via "paste" menu.
    public var isAllowsPasteAttributedString = false
    
    /// A Boolean value indicating whether the receiver can copy attributed text to pasteboard.
    ///
    /// Default is `true`.
    /// When the value of this property is `true`, user can copy attributed text (with attachment image)
    /// from text view to pasteboard via "copy" menu.
    public var isAllowsCopyAttributedString = true
    
    /// A callback when the availability of the pan gesture changes
    public var panGestureEnabledCallback: ((Bool) -> Void)?
    
    // MARK: - Manage the undo and redo

    /// A Boolean value indicating whether the receiver can undo and redo typing with shake gesture.
    ///
    /// The default value is `true`.
    public var isAllowsUndoAndRedo = true
    
    /// The maximum undo/redo level.
    ///
    /// The default value is 20.
    public var maximumUndoLevel: Int = defaultUndoLevelLimited
    
    // MARK: - Replacing the System Input Views
    
    private var _inputView: UIView?
    /// The custom input view to display when the text view becomes the first responder.
    /// It can be used to replace system keyboard.
     
    /// If set the value while first responder, it will not take effect until
    /// 'reloadInputViews' is called.
    override open var inputView: UIView? { // kind of UIView
        get {
            return _inputView
        }
        set {
            _inputView = newValue
        }
    }
    
    private var _inputAccessoryView: UIView?
    /// The custom accessory view to display when the text view becomes the first responder.
    /// It can be used to add a toolbar at the top of keyboard.
    ///
    /// If set the value while first responder, it will not take effect until
    /// 'reloadInputViews' is called.
    override open var inputAccessoryView: UIView? { // kind of UIView
        get {
            return _inputAccessoryView
        }
        set {
            _inputAccessoryView = newValue
        }
    }
    
    /// If you use an custom accessory view without "inputAccessoryView" property,
    /// you may set the accessory view's height. It may used by auto scroll calculation.
    public var extraAccessoryViewHeight: CGFloat = 0
    
    private lazy var _selectedTextRange = TextRange.default() /// nonnull
    private var _markedTextRange: TextRange?
    
    private weak var _outerDelegate: AttributedTextViewDelegate?
    
    private var _placeHolderView = UIImageView()
    
    private lazy var _innerText = NSMutableAttributedString() /// nonnull, inner attributed text
    private var _delectedText: NSMutableAttributedString? /// detected text for display
    private lazy var _innerContainer = TextContainer() /// nonnull, inner text container
    /// inner text layout, the text in this layout is longer than `innerText` by appending '\n'
    private var _innerLayout: TextLayout?
    
    private lazy var _containerView = TextContainerView() /// nonnull
    private lazy var _selectionView = TextSelectionView() /// nonnull
    private lazy var _magnifierCaret = TextMagnifier() /// nonnull
    
    private lazy var _typingAttributesHolder = NSMutableAttributedString(string: " ") /// nonnull, typing attributes
    private var _dataDetector: NSDataDetector?
    private var _magnifierCaretOffset: CGFloat = 0
    
    private lazy var _highlightRange = NSRange(location: 0, length: 0) /// current highlight range
    private var _highlight: TextHighlight? /// highlight attribute in `highlightRange`
    private var _highlightLayout: TextLayout? /// when _state.showingHighlight=true, this layout should be displayed
    private var _trackingRange: TextRange? /// the range in _innerLayout, may out of _innerText.
    
    private var _insetModifiedByKeyboard = false /// text is covered by keyboard, and the contentInset is modified
    private var _originalContentInset = UIEdgeInsets.zero /// the original contentInset before modified
    /// the original verticalScrollIndicatorInsets before modified
    private var _originalVerticalScrollIndicatorInsets: UIEdgeInsets = .zero
    /// the original horizontalScrollIndicatorInsets before modified
    private var _originalHorizontalScrollIndicatorInsets: UIEdgeInsets = .zero
    
    private var _longPressTimer: Timer?
    private var _autoScrollTimer: Timer?
    private var _autoScrollOffset: CGFloat = 0 /// current auto scroll offset which shoud add to scroll view
    private var _autoScrollAcceleration: Int = 0 /// an acceleration coefficient for auto scroll
    private var _selectionDotFixTimer: Timer? /// fix the selection dot in window if the view is moved by parents
    private var _previousOriginInWindow = CGPoint.zero
    
    private var _touchBeganPoint = CGPoint.zero
    private var _trackingPoint = CGPoint.zero
    private var _touchBeganTime: TimeInterval = 0
    private var _trackingTime: TimeInterval = 0
    private lazy var _undoStack: [TextViewUndoObject] = []
    private lazy var _redoStack: [TextViewUndoObject] = []
    private var _lastTypeRange: NSRange?
    
    public private(set) lazy var state = State()
    
    // UITextInputTraits
    public var autocapitalizationType = UITextAutocapitalizationType.sentences
    public var autocorrectionType = UITextAutocorrectionType.default
    public var spellCheckingType = UITextSpellCheckingType.default
    public var keyboardType = UIKeyboardType.default
    public var keyboardAppearance = UIKeyboardAppearance.default
    public var returnKeyType = UIReturnKeyType.default
    public var enablesReturnKeyAutomatically = false
    public var isSecureTextEntry = false
    
    /// 是否包含文本
    public var hasText: Bool {
        return _innerText.length > 0
    }
    
    private weak var _inputDelegate: UITextInputDelegate?
    /// UITextInputDelegate
    public weak var inputDelegate: UITextInputDelegate? {
        get {
            return _inputDelegate
        }
        set {
            _inputDelegate = newValue
        }
    }
    
    /// The Text Selected Range
    public var selectedTextRange: UITextRange? {
        get {
            return _selectedTextRange
        }
        set {
            guard var newRange = newValue as? TextRange else {
                return
            }
            if let fixedRange = _correctedTextRange(newRange) {
                newRange = fixedRange
            }
            if _selectedTextRange == newRange {
                return
            }
            _updateIfNeeded()
            _endTouchTracking()
            _hideMenu()
            state.isDeleteConfirm = false
            state.isTypingAttributesOnce = false
            
            _inputDelegate?.selectionWillChange(self)
            _selectedTextRange = newRange
            _lastTypeRange = _selectedTextRange.nsRange
            _inputDelegate?.selectionDidChange(self)
            
            _updateOuterProperties()
            _updateSelectionView()
            
            if isFirstResponder {
                _scrollRangeToVisible(_selectedTextRange)
            }
        }
    }
    
    /// 选中样式
    public var markedTextStyle: [NSAttributedString.Key: Any]?
    
    /// 文档开始位置
    public var beginningOfDocument: UITextPosition {
        return TextPosition(offset: 0)
    }
    
    /// 文档结束位置
    public var endOfDocument: UITextPosition {
        return TextPosition(offset: _innerText.length)
    }
    
    /// 选中的亲和性
    public var selectionAffinity: UITextStorageDirection {
        get {
            if _selectedTextRange.end.affinity == TextAffinity.forward {
                return .forward
            } else {
                return .backward
            }
        }
        set {
            _selectedTextRange = TextRange(
                range: _selectedTextRange.nsRange,
                affinity: newValue == .forward ? .forward : .backward
            )
            _updateSelectionView()
        }
    }
    
    // MARK: - Override For Protect
    
    override open var isMultipleTouchEnabled: Bool {
        get {
            return super.isMultipleTouchEnabled
        }
        set {
            _ = newValue
            super.isMultipleTouchEnabled = false // must not enabled
        }
    }
    
    override open var contentInset: UIEdgeInsets {
        get {
            return super.contentInset
        }
        set {
            let oldInsets = self.contentInset
            if _insetModifiedByKeyboard {
                _originalContentInset = newValue
            } else {
                super.contentInset = newValue
                if oldInsets != newValue { // changed
                    _updateInnerContainerSize()
                    _commitUpdate()
                    _commitPlaceholderUpdate()
                }
            }
        }
    }
    
    override open var verticalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return super.verticalScrollIndicatorInsets
        }
        set {
            if _insetModifiedByKeyboard {
                _originalVerticalScrollIndicatorInsets = newValue
            } else {
                super.verticalScrollIndicatorInsets = newValue
            }
        }
    }
    
    override open var horizontalScrollIndicatorInsets: UIEdgeInsets {
        get {
            return super.horizontalScrollIndicatorInsets
        }
        set {
            if _insetModifiedByKeyboard {
                _originalHorizontalScrollIndicatorInsets = newValue
            } else {
                super.horizontalScrollIndicatorInsets = newValue
            }
        }
    }
    
    override open var frame: CGRect {
        get {
            return super.frame
        }
        set {
            let oldSize: CGSize = bounds.size
            super.frame = newValue
            let newSize: CGSize = bounds.size
            let hasChanged: Bool = _innerContainer.isVerticalForm ?
            oldSize.height != newSize.height :
            oldSize.width != newSize.width
            if hasChanged {
                _updateInnerContainerSize()
                _commitUpdate()
            }
            if !oldSize.equalTo(newSize) {
                _commitPlaceholderUpdate()
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
            let changed: Bool = _innerContainer.isVerticalForm ?
            oldSize.height != newSize.height :
            oldSize.width != newSize.width
            if changed {
                _updateInnerContainerSize()
                _commitUpdate()
            }
            if !oldSize.equalTo(newSize) {
                _commitPlaceholderUpdate()
            }
        }
    }
    
    override open var canResignFirstResponder: Bool {
        if !isFirstResponder {
            return true
        }
        if let should = _outerDelegate?.textViewShouldEndEditing?(self) {
            return !should
        }
        return true
    }
    
    override open var canBecomeFirstResponder: Bool {
        if !isSelectable {
            return false
        }
        if !isEditable {
            return false
        }
        if state.isFirstResponderIgnored {
            return false
        }
        if let should = _outerDelegate?.textViewShouldBeginEditing?(self) {
            if !should {
                return false
            }
        }
        return true
    }
    
    // MARK: - Public

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tokenizer = UITextInputStringTokenizer(textInput: self)
        _initTextView()
    }
    
    // MARK: - NSCoding

    /// Decode
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initTextView()
        attributedText = aDecoder.decodeObject(forKey: "attributedText") as? NSAttributedString
        if let range = (aDecoder.decodeObject(forKey: "selectedRange") as? NSValue)?.rangeValue {
            selectedRange = range
        }
        if let alignment = TextVerticalAlignment(rawValue: aDecoder.decodeInteger(
            forKey: "textVerticalAlignment")
        ) {
            textVerticalAlignment = alignment
        }
        dataDetectorTypes = UIDataDetectorTypes(rawValue: UInt(aDecoder.decodeInteger(forKey: "dataDetectorTypes")))
        textContainerInset = aDecoder.decodeUIEdgeInsets(forKey: "textContainerInset")
        if let decode = aDecoder.decodeObject(forKey: "exclusionPaths") as? [UIBezierPath] {
            exclusionPaths = decode
        }
        isVerticalForm = aDecoder.decodeBool(forKey: "isVerticalForm")
    }
    
    override open class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        if automaticallyNotifiesObserversKeys.contains(key) {
            return false
        }
        return super.automaticallyNotifiesObservers(forKey: key)
    }
    
    /// Encode
    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(attributedText, forKey: "attributedText")
        aCoder.encode(NSValue(range: selectedRange), forKey: "selectedRange")
        aCoder.encode(textVerticalAlignment, forKey: "textVerticalAlignment")
        aCoder.encode(dataDetectorTypes.rawValue, forKey: "dataDetectorTypes")
        aCoder.encode(textContainerInset, forKey: "textContainerInset")
        aCoder.encode(exclusionPaths, forKey: "exclusionPaths")
        aCoder.encode(isVerticalForm, forKey: "isVerticalForm")
    }
    
    // MARK: - Private
    
    /// Update layout and selection before runloop sleep/end.
    private func _commitUpdate() {
        #if !TARGET_INTERFACE_BUILDER
        state.isNeedsUpdate = true
        TextTransaction(target: self, selector: #selector(_updateIfNeeded)).commit()
        #else
        _update()
        #endif
    }
    
    /// Update layout and selection view if needed.
    @objc
    private func _updateIfNeeded() {
        if state.isNeedsUpdate {
            _update()
        }
    }
    
    /// Update layout and selection view immediately.
    private func _update() {
        state.isNeedsUpdate = false
        _updateLayout()
        _updateSelectionView()
    }
    
    /// Update layout immediately.
    private func _updateLayout() {
        guard let text = _innerText.mutableCopy() as? NSMutableAttributedString else {
            return
        }
        _placeHolderView.isHidden = (text.length > 0)
        if _detectText(text) {
            _delectedText = text
        } else {
            _delectedText = nil
        }
        text.replaceCharacters(in: NSRange(location: text.length, length: 0), with: "\r") // add for nextline caret
        text.removeDiscontinuousAttributes(in: NSRange(location: _innerText.length, length: 1))
        text.removeAttribute(TextAttribute.textBorder, range: NSRange(location: _innerText.length, length: 1))
        text.removeAttribute(TextAttribute.textBackgroundBorder, range: NSRange(location: _innerText.length, length: 1))
        if _innerText.length == 0 {
            text.setAttributes([:], range: text.rangeOfAll)
            if let attrs = _typingAttributesHolder.attributes {
                // add for empty text caret
                for attr in attrs {
                    text.setAttribute(attr.key, value: attr.value)
                }
            }
        }
        if _selectedTextRange.end.offset == _innerText.length {
            for (key, value) in _typingAttributesHolder.attributes ?? [:] {
                text.setAttribute(key, value: value, range: NSRange(location: _innerText.length, length: 1))
            }
        }
        willChangeValue(forKey: "textLayout")
        _innerLayout = TextLayout(container: _innerContainer, text: text)
        didChangeValue(forKey: "textLayout")
        var size: CGSize = _innerLayout?.textBoundingSize ?? .zero
        let visibleSize: CGSize = _getVisibleSize()
        if _innerContainer.isVerticalForm {
            size.height = visibleSize.height
            if size.width < visibleSize.width {
                size.width = visibleSize.width
            }
        } else {
            size.width = visibleSize.width
        }
        
        _containerView.set(layout: _innerLayout, with: 0)
        _containerView.frame = CGRect()
        _containerView.frame.size = size
        state.isShowingHighlight = false
        contentSize = size
    }
    
    /// Update selection view immediately.
    /// This method should be called after "layout update" finished.
    private func _updateSelectionView() {
        _selectionView.frame = _containerView.frame
        _selectionView.isCaretBlinks = false
        _selectionView.isCaretVisible = false
        _selectionView.selectionRects = nil
        TextEffectWindow.shared?.hide(selectionDot: _selectionView)
        if _innerLayout == nil {
            return
        }
        
        var allRects = [TextSelectionRect]()
        var containsDot = false
        
        var selectedRange = _selectedTextRange
        if state.isTrackingTouch, let range = _trackingRange {
            selectedRange = range
        }
        
        if let marked = _markedTextRange {
            var rects = _innerLayout?.selectionRectsWithoutStartAndEnd(for: marked)
            if let aRects = rects {
                allRects.append(contentsOf: aRects)
            }
            if selectedRange.nsRange.length > 0 {
                rects = _innerLayout?.selectionRectsWithOnlyStartAndEnd(for: selectedRange)
                if let aRects = rects {
                    allRects.append(contentsOf: aRects)
                    containsDot = !aRects.isEmpty
                }
            } else {
                if let rect = _innerLayout?.caretRect(for: selectedRange.end) {
                    _selectionView.caretRect = _convertRect(fromLayout: rect)
                }
                _selectionView.isCaretVisible = true
                _selectionView.isCaretBlinks = true
            }
        } else {
            if selectedRange.nsRange.length == 0 {
                // only caret
                if isFirstResponder || state.isTrackingPreviousSelect {
                    if let rect: CGRect = _innerLayout?.caretRect(for: selectedRange.end) {
                        _selectionView.caretRect = _convertRect(fromLayout: rect)
                    }
                    _selectionView.isCaretVisible = true
                    if !state.isTrackingCaret && !state.isTrackingPreviousSelect {
                        _selectionView.isCaretBlinks = true
                    }
                }
            } else {
                // range selected
                if (isFirstResponder && !state.isDeleteConfirm) || (!isFirstResponder && state.isSelectedWithoutEdit) {
                    if let rects = _innerLayout?.selectionRects(for: selectedRange) {
                        allRects.append(contentsOf: rects)
                        containsDot = !rects.isEmpty
                    }
                } else if (!isFirstResponder && state.isTrackingPreviousSelect) || (isFirstResponder && state.isDeleteConfirm) {
                    if let rects = _innerLayout?.selectionRectsWithoutStartAndEnd(for: selectedRange) {
                        allRects.append(contentsOf: rects)
                    }
                }
            }
        }
        for rect in allRects {
            rect.rect = _convertRect(fromLayout: rect.rect)
        }
        _selectionView.selectionRects = allRects
        if !state.isFirstShowDot, containsDot {
            state.isFirstShowDot = true
            // The dot position may be wrong at the first time displayed.
            // I can't find the reason. Here's a workaround.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.02) {
                TextEffectWindow.shared?.show(selectionDot: self._selectionView)
            }
        }
        TextEffectWindow.shared?.show(selectionDot: _selectionView)
        
        if containsDot {
            _startSelectionDotFixTimer()
        } else {
            _endSelectionDotFixTimer()
        }
    }
    
    /// Update inner contains's size.
    private func _updateInnerContainerSize() {
        var size: CGSize = _getVisibleSize()
        if _innerContainer.isVerticalForm {
            size.width = CGFloat.greatestFiniteMagnitude
        } else {
            size.height = CGFloat.greatestFiniteMagnitude
        }
        _innerContainer.size = size
    }
    
    /// Update placeholder before runloop sleep/end.
    private func _commitPlaceholderUpdate() {
        #if !TARGET_INTERFACE_BUILDER
        state.isPlaceholderNeedsUpdate = true
        TextTransaction(target: self, selector: #selector(_updatePlaceholderIfNeeded)).commit()
        #else
        _updatePlaceholder()
        #endif
    }
    
    /// Update placeholder if needed.
    @objc
    private func _updatePlaceholderIfNeeded() {
        if state.isPlaceholderNeedsUpdate {
            state.isPlaceholderNeedsUpdate = false
            _updatePlaceholder()
        }
    }
    
    /// Update placeholder immediately.
    private func _updatePlaceholder() {
        var frame = CGRect.zero
        _placeHolderView.image = nil
        _placeHolderView.frame = frame
        if let placeholder = placeholderAttributedText,
            placeholder.length > 0,
            let container = _innerContainer.copy() as? TextContainer {
            container.size = bounds.size
            container.truncationType = TextTruncationType.end
            container.truncationToken = nil
            if let layout = TextLayout(container: container, text: placeholderAttributedText) {
                let size: CGSize = layout.textBoundingSize
                let needDraw: Bool = size.width > 1 && size.height > 1
                if needDraw {
                    let format = UIGraphicsImageRendererFormat()
                    format.scale = 0
                    let renderer = UIGraphicsImageRenderer(size: size, format: format)
                    let image = renderer.image { [weak self] context in
                        guard let self else { return }
                        layout.draw(in: context.cgContext, size: size, debug: self.debugOption)
                    }
                    _placeHolderView.image = image
                    frame.size = image.size
                    if container.isVerticalForm {
                        frame.origin.x = bounds.size.width - image.size.width
                    } else {
                        frame.origin = .zero
                    }
                    _placeHolderView.frame = frame
                }
            }
        }
    }
    
    /// Update the `_selectedTextRange` to a single position by `_trackingPoint`.
    private func _updateTextRangeByTrackingCaret() {
        if !state.isTrackingTouch {
            return
        }
        
        let trackingPoint = _convertPoint(toLayout: _trackingPoint)
        
        if var newPos = _innerLayout?.closestPosition(to: trackingPoint) {
            if let pos = _correctedTextPosition(newPos) {
                newPos = pos
            }
            if let marked = _markedTextRange {
                if newPos.compare(marked.start) == .orderedAscending {
                    newPos = marked.start
                } else if newPos.compare(marked.end) == .orderedDescending {
                    newPos = marked.end
                }
            }
            _trackingRange = TextRange(range: NSRange(location: newPos.offset, length: 0), affinity: newPos.affinity)
        }
    }
    
    /// Update the `_selectedTextRange` to a new range by `_trackingPoint` and `_state.trackingGrabber`.
    private func _updateTextRangeByTrackingGrabber() {
        if !state.isTrackingTouch || state.trackingGrabber == .none {
            return
        }
        
        let isStart = state.trackingGrabber == .start
        var magPoint = _trackingPoint
        magPoint.y += magnifierRangedTrackFixValue
        magPoint = _convertPoint(toLayout: magPoint)
        var position: TextPosition? = _innerLayout?.position(
            for: magPoint,
            oldPosition: isStart ? _selectedTextRange.start : _selectedTextRange.end,
            otherPosition: isStart ? _selectedTextRange.end : _selectedTextRange.start
        )
        if let newPosition = position {
            position = _correctedTextPosition(newPosition)
            if newPosition.offset > _innerText.length {
                position = TextPosition(offset: _innerText.length)
            }
            _trackingRange = TextRange(
                start: isStart ? newPosition : _selectedTextRange.start,
                end: isStart ? _selectedTextRange.end : newPosition
            )
        }
    }
    
    /// Update the `_selectedTextRange` to a new range/position by `_trackingPoint`.
    private func _updateTextRangeByTrackingPreSelect() {
        if !state.isTrackingTouch {
            return
        }
        _trackingRange = _getClosestTokenRange(at: _trackingPoint)
    }
    
    /// Show or update `_magnifierCaret` based on `_trackingPoint`, and hide `_magnifierRange`.
    private func _showMagnifierCaret() {
        if TextUtilities.isAppExtension {
            return
        }
        
        var selectedRange = _selectedTextRange
        if state.isTrackingTouch, let range = _trackingRange {
            selectedRange = range
        }
        
        var caretRect: CGRect = .zero
        if let rects = _selectionView.selectionRects, let firstRect = rects.first {
            caretRect = firstRect.rect
        } else {
            caretRect = _selectionView.caretRect
            if selectedRange.nsRange.length == 0 || state.trackingGrabber == .none {
                // only caret
                if isFirstResponder || state.isTrackingPreviousSelect {
                    caretRect = _selectionView.caretRect
                }
            } else {
                // range selected
                let isStart = state.trackingGrabber == .start
                if let rect = _innerLayout?.caretRect(for: isStart ? selectedRange.start : selectedRange.end) {
                    caretRect = _convertRect(fromLayout: rect)
                }
            }
        }
        let deltaOffsetX = _magnifierCaret.fitSize.width / 2
        var fixedX = _trackingPoint.x
        if fixedX < deltaOffsetX {
            fixedX = deltaOffsetX
        }
        if fixedX > _containerView.bounds.width - deltaOffsetX {
            fixedX = _containerView.bounds.width - deltaOffsetX
        }
        
        var fixedY = _trackingPoint.y
        if fixedY < caretRect.midY {
            fixedY = caretRect.midY
        }
        if fixedY > _containerView.bounds.maxY {
            fixedY = _containerView.bounds.maxY
        }
        let capturePoint = CGPoint(x: fixedX, y: fixedY)
        
        _magnifierCaret.hostPopoverCenter = capturePoint
        _magnifierCaret.hostCaptureCenter = capturePoint
        if !state.isShowingMagnifierCaret {
            state.isShowingMagnifierCaret = true
            TextEffectWindow.shared?.show(_magnifierCaret)
        } else {
            TextEffectWindow.shared?.move(_magnifierCaret)
        }
    }
    
    /// Update the showing magnifier.
    private func _updateMagnifier() {
        if TextUtilities.isAppExtension {
            return
        }
        
        if state.isShowingMagnifierCaret {
            TextEffectWindow.shared?.move(_magnifierCaret)
        }
    }
    
    /// Hide the `_magnifierCaret`
    private func _hideMagnifier() {
        if TextUtilities.isAppExtension {
            return
        }
        
        if state.isShowingMagnifierCaret {
            // disable touch began temporary to ignore caret animation overlap
            state.isTouchBeganIgnored = true
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.15) {
                self.state.isTouchBeganIgnored = false
            }
        }
        
        if state.isShowingMagnifierCaret {
            state.isShowingMagnifierCaret = false
            TextEffectWindow.shared?.hide(_magnifierCaret)
        }
    }
    
    /// Show and update the UIMenuController.
    private func _showMenu() {
        var rect: CGRect
        if _selectionView.isCaretVisible {
            rect = _selectionView.caretView.frame
        } else if let rects = _selectionView.selectionRects, !rects.isEmpty, var firstRect = rects.first {
            rect = firstRect.rect
            for index in 1 ..< rects.count {
                firstRect = rects[index]
                rect = rect.union(firstRect.rect)
            }
            
            let inter: CGRect = rect.intersection(bounds)
            if !inter.isNull, inter.size.height > 1 {
                rect = inter // clip to bounds
            } else {
                if rect.minY < bounds.minY {
                    rect.size.height = 1
                    rect.origin.y = bounds.minY
                } else {
                    rect.size.height = 1
                    rect.origin.y = bounds.maxY
                }
            }
            
            let mgr = TextKeyboardManager.default
            if mgr.keyboardVisible {
                let kbRect = mgr.convert(mgr.keyboardFrame, to: self)
                let kbInter: CGRect = rect.intersection(kbRect)
                if !kbInter.isNull, kbInter.size.height > 1, kbInter.size.width > 1 {
                    // self is covered by keyboard
                    if kbInter.minY > rect.minY {
                        // keyboard at bottom
                        rect.size.height -= kbInter.size.height
                    } else if kbInter.maxY < rect.maxY {
                        // keyboard at top
                        rect.origin.y += kbInter.size.height
                        rect.size.height -= kbInter.size.height
                    }
                }
            }
        } else {
            rect = _selectionView.bounds
        }
        
        if !isFirstResponder {
            if !_containerView.isFirstResponder {
                _containerView.becomeFirstResponder()
            }
        }
        
        if isFirstResponder || _containerView.isFirstResponder {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
                    let menu = UIMenuController.shared
                    menu.update()
                    if !self.state.isShowingMenu || !menu.isMenuVisible {
                        self.state.isShowingMenu = true
                        menu.showMenu(from: self._selectionView, rect: rect.standardized)
                    }
            }
        }
    }
    
    /// Hide the UIMenuController.
    private func _hideMenu() {
        if state.isShowingMenu {
            state.isShowingMenu = false
            let menu = UIMenuController.shared
            menu.hideMenu()
        }
        if _containerView.isFirstResponder {
            state.isFirstResponderIgnored = true
            _containerView.resignFirstResponder() // it will call [self becomeFirstResponder], ignore it temporary.
            state.isFirstResponderIgnored = false
        }
    }
    
    /// Show highlight layout based on `_highlight` and `_highlightRange`
    /// If the `_highlightLayout` is nil, try to create.
    private func _showHighlight(animated: Bool) {
        let fadeDuration: TimeInterval = animated ? highlightFadeDuration : 0
        if _highlight == nil {
            return
        }
        if _highlightLayout == nil {
            let highlightText = (_delectedText ?? _innerText).mutableCopy() as? NSMutableAttributedString
            let newAttrs = _highlight?.attributes
            for (key, value) in newAttrs ?? [:] {
                highlightText?.setAttribute(key, value: value, range: _highlightRange)
            }
            _highlightLayout = TextLayout(container: _innerContainer, text: highlightText)
            if _highlightLayout == nil {
                _highlight = nil
            }
        }
        
        if _highlightLayout != nil, !state.isShowingHighlight {
            state.isShowingHighlight = true
            _containerView.set(layout: _highlightLayout, with: fadeDuration)
        }
    }
    
    /// Show `_innerLayout` instead of `_highlightLayout`.
    /// It does not destory the `_highlightLayout`.
    private func _hideHighlight(animated: Bool) {
        let fadeDuration: TimeInterval = animated ? highlightFadeDuration : 0
        if state.isShowingHighlight {
            state.isShowingHighlight = false
            _containerView.set(layout: _innerLayout, with: fadeDuration)
        }
    }
    
    /// Show `_innerLayout` and destory the `_highlight` and `_highlightLayout`.
    private func _removeHighlight(animated: Bool) {
        _hideHighlight(animated: animated)
        _highlight = nil
        _highlightLayout = nil
    }
    
    /// Scroll current selected range to visible.
    @objc
    private func _scrollSelectedRangeToVisible() {
        _scrollRangeToVisible(_selectedTextRange)
    }
    
    /// Scroll range to visible, take account into keyboard and insets.
    private func _scrollRangeToVisible(_ range: TextRange?) {
        guard let range = range,
              var rect = _innerLayout?.rect(for: range) else {
            return
        }
        if rect.isNull {
            return
        }
        rect = _convertRect(fromLayout: rect)
        rect = _containerView.convert(rect, to: self)
        
        if rect.size.width < 1 {
            rect.size.width = 1
        }
        if rect.size.height < 1 {
            rect.size.height = 1
        }
        let extend: CGFloat = 3
        
        var insetModified = false
        let mgr = TextKeyboardManager.default
        
        if mgr.keyboardVisible, window != nil, superview != nil, isFirstResponder, !isVerticalForm {
            var bounds: CGRect = self.bounds
            bounds.origin = CGPoint.zero
            var kbRect = mgr.convert(mgr.keyboardFrame, to: self)
            kbRect.origin.y -= extraAccessoryViewHeight
            kbRect.size.height += extraAccessoryViewHeight
            
            kbRect.origin.x -= contentOffset.x
            kbRect.origin.y -= contentOffset.y
            let inter: CGRect = bounds.intersection(kbRect)
            if !inter.isNull, inter.size.height > 1, inter.size.width > extend {
                // self is covered by keyboard
                if inter.minY > bounds.minY {
                    // keyboard below self.top
                    
                    var originalContentInset = contentInset
                    var originalHorizontalIndicatorInsets = horizontalScrollIndicatorInsets
                    var originalVerticalIndicatorInsets = verticalScrollIndicatorInsets
                    if _insetModifiedByKeyboard {
                        originalContentInset = _originalContentInset
                        originalHorizontalIndicatorInsets = _originalHorizontalScrollIndicatorInsets
                        originalVerticalIndicatorInsets = _originalVerticalScrollIndicatorInsets
                    }
                    
                    if originalContentInset.bottom < inter.size.height + extend {
                        insetModified = true
                        if !_insetModifiedByKeyboard {
                            _insetModifiedByKeyboard = true
                            originalContentInset = contentInset
                            originalHorizontalIndicatorInsets = horizontalScrollIndicatorInsets
                            originalVerticalIndicatorInsets = verticalScrollIndicatorInsets
                        }
                        var newInset: UIEdgeInsets = originalContentInset
                        var newHorizontalIndicatorInsets: UIEdgeInsets = originalHorizontalIndicatorInsets
                        var newVerticalIndicatorInsets: UIEdgeInsets = originalVerticalIndicatorInsets
                        newInset.bottom = inter.size.height + extend
                        newHorizontalIndicatorInsets.right = newInset.right
                        newVerticalIndicatorInsets.bottom = newInset.bottom
                        
                        let curve = UIView.AnimationOptions(rawValue: 7 << 16)
                        
                        UIView.animate(
                            withDuration: 0.25,
                            delay: 0,
                            options: [.beginFromCurrentState, .allowUserInteraction, curve],
                            animations: {
                                super.contentInset = newInset
                                super.horizontalScrollIndicatorInsets = newHorizontalIndicatorInsets
                                super.verticalScrollIndicatorInsets = newVerticalIndicatorInsets
                                self.scrollRectToVisible(rect.insetBy(dx: -extend, dy: -extend), animated: false)
                            }
                        )
                    }
                }
            }
        }
        
        if !insetModified {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut],
                animations: {
                    self._restoreInsets(animated: false)
                    self.scrollRectToVisible(rect.insetBy(dx: -extend, dy: -extend), animated: false)
                }
            )
        }
    }
    
    /// Restore contents insets if modified by keyboard.
    private func _restoreInsets(animated: Bool) {
        if _insetModifiedByKeyboard {
            _insetModifiedByKeyboard = false
            if animated {
                UIView.animate(
                    withDuration: 0.25,
                    delay: 0,
                    options: [.beginFromCurrentState, .allowUserInteraction, .curveEaseOut],
                    animations: {
                        super.contentInset = self._originalContentInset
                        super.horizontalScrollIndicatorInsets = self._originalHorizontalScrollIndicatorInsets
                        super.verticalScrollIndicatorInsets = self._originalHorizontalScrollIndicatorInsets
                    }
                )
            } else {
                super.contentInset = _originalContentInset
                super.horizontalScrollIndicatorInsets = _originalHorizontalScrollIndicatorInsets
                super.verticalScrollIndicatorInsets = _originalHorizontalScrollIndicatorInsets
            }
        }
    }
    
    /// Keyboard frame changed, scroll the caret to visible range, or modify the content insets.
    private func _keyboardChanged() {
        if !isFirstResponder {
            return
        }
        DispatchQueue.main.async {
            if TextKeyboardManager.default.keyboardVisible {
                self._scrollRangeToVisible(self._selectedTextRange)
            } else {
                self._restoreInsets(animated: true)
            }
            self._updateMagnifier()
            if self.state.isShowingMenu {
                self._showMenu()
            }
        }
    }
    
    /// Start long press timer, used for 'highlight' range text action.
    private func _startLongPressTimer() {
        _longPressTimer?.invalidate()
        let timer = Timer.scheduled(
            interval: longPressMinimumDuration,
            target: self,
            selector: #selector(_trackDidLongPress),
            repeats: false
        )
        _longPressTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    /// Invalidate the long press timer.
    private func _endLongPressTimer() {
        _longPressTimer?.invalidate()
        _longPressTimer = nil
    }
    
    /// Long press detected.
    @objc
    private func _trackDidLongPress() {
        _endLongPressTimer()
        
        var dealLongPressAction = false
        if state.isShowingHighlight {
            _hideMenu()
            
            if let action = _highlight?.longPressAction {
                dealLongPressAction = true
                if var rect: CGRect = _innerLayout?.rect(for: TextRange(range: _highlightRange)) {
                    rect = _convertRect(fromLayout: rect)
                    action(self, _innerText, _highlightRange, rect)
                }
                _endTouchTracking()
            } else {
                var shouldHighlight = true
                if let delegate = _outerDelegate, let highlight = _highlight {
                    if let should = delegate.textView?(self, shouldLongPress: highlight, in: _highlightRange) {
                        shouldHighlight = should
                    }
                    if shouldHighlight,
                       var rect: CGRect = _innerLayout?.rect(for: TextRange(range: _highlightRange)) {
                        dealLongPressAction = true
                        rect = _convertRect(fromLayout: rect)
                        delegate.textView?(self, didLongPress: highlight, in: _highlightRange, rect: rect)
                        _endTouchTracking()
                    }
                }
            }
        }
        
        if !dealLongPressAction {
            _removeHighlight(animated: false)
            if state.isTrackingTouch {
                if state.trackingGrabber != .none {
                    panGestureRecognizer.isEnabled = false
                    self.panGestureEnabledCallback?(false)
                    _hideMenu()
                    _showMagnifierCaret()
                } else if isFirstResponder {
                    panGestureRecognizer.isEnabled = false
                    self.panGestureEnabledCallback?(false)
                    _selectionView.isCaretBlinks = false
                    state.isTrackingCaret = true
                    let trackingPoint: CGPoint = _convertPoint(toLayout: _trackingPoint)
                    var fixedPos = _innerLayout?.closestPosition(to: trackingPoint)
                    fixedPos = _correctedTextPosition(fixedPos)
                    if var fixedPos = fixedPos {
                        if let marked = _markedTextRange {
                            if fixedPos.compare(marked.start) != .orderedDescending {
                                fixedPos = marked.start
                            } else if fixedPos.compare(marked.end) != .orderedAscending {
                                fixedPos = marked.end
                            }
                        }
                        _trackingRange = TextRange(
                            range: NSRange(location: fixedPos.offset, length: 0),
                            affinity: fixedPos.affinity
                        )
                        _updateSelectionView()
                    }
                    _hideMenu()
                    _showMagnifierCaret()
                } else if isSelectable {
                    panGestureRecognizer.isEnabled = false
                    self.panGestureEnabledCallback?(false)
                    state.isTrackingPreviousSelect = true
                    state.isSelectedWithoutEdit = false
                    _updateTextRangeByTrackingPreSelect()
                    _updateSelectionView()
                    _showMagnifierCaret()
                }
            }
        }
    }
    
    /// Start auto scroll timer, used for auto scroll tick.
    private func _startAutoScrollTimer() {
        if _autoScrollTimer == nil {
            let timer = Timer.scheduled(
                interval: autoScrollMinimumDuration,
                target: self,
                selector: #selector(_trackDidTickAutoScroll),
                repeats: true
            )
            _autoScrollTimer = timer
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Invalidate the auto scroll, and restore the text view state.
    private func _endAutoScrollTimer() {
        if state.isAutoScrollTicked {
            flashScrollIndicators()
        }
        _autoScrollTimer?.invalidate()
        _autoScrollTimer = nil
        _autoScrollOffset = 0
        _autoScrollAcceleration = 0
        state.isAutoScrollTicked = false
        
        if _magnifierCaret.isCaptureDisabled {
            _magnifierCaret.isCaptureDisabled = false
            if state.isShowingMagnifierCaret {
                _showMagnifierCaret()
            }
        }
    }
    
    /// Auto scroll ticked by timer.
    @objc
    private func _trackDidTickAutoScroll() {
        if _autoScrollOffset != 0 {
            _magnifierCaret.isCaptureDisabled = true
            
            var offset: CGPoint = contentOffset
            if isVerticalForm {
                offset.x += _autoScrollOffset
                
                if _autoScrollAcceleration > 0 {
                    let offsetX = (_autoScrollOffset > 0 ? 1 : -1) *
                    CGFloat(_autoScrollAcceleration) *
                    CGFloat(_autoScrollAcceleration) * CGFloat(0.5)
                    offset.x += offsetX
                }
                _autoScrollAcceleration += 1
                offset.x = CGFloat(round(Double(offset.x)))
                if _autoScrollOffset < 0 {
                    if offset.x < -contentInset.left {
                        offset.x = -contentInset.left
                    }
                } else {
                    let maxOffsetX: CGFloat = contentSize.width - bounds.size.width + contentInset.right
                    if offset.x > maxOffsetX {
                        offset.x = maxOffsetX
                    }
                }
                if offset.x < -contentInset.left {
                    offset.x = -contentInset.left
                }
            } else {
                offset.y += _autoScrollOffset
                if _autoScrollAcceleration > 0 {
                    let offsetY = (_autoScrollOffset > 0 ? 1 : -1) *
                    CGFloat(_autoScrollAcceleration) *
                    CGFloat(_autoScrollAcceleration) *
                    CGFloat(0.5)
                    offset.y += offsetY
                }
                _autoScrollAcceleration += 1
                offset.y = CGFloat(round(Double(offset.y)))
                if _autoScrollOffset < 0 {
                    if offset.y < -contentInset.top {
                        offset.y = -contentInset.top
                    }
                } else {
                    let maxOffsetY: CGFloat = contentSize.height - bounds.size.height + contentInset.bottom
                    if offset.y > maxOffsetY {
                        offset.y = maxOffsetY
                    }
                }
                if offset.y < -contentInset.top {
                    offset.y = -contentInset.top
                }
            }
            
            var shouldScroll: Bool
            if isVerticalForm {
                shouldScroll = abs(Float(offset.x - contentOffset.x)) > 0.5
            } else {
                shouldScroll = abs(Float(offset.y - contentOffset.y)) > 0.5
            }
            
            if shouldScroll {
                state.isAutoScrollTicked = true
                _trackingPoint.x += offset.x - contentOffset.x
                _trackingPoint.y += offset.y - contentOffset.y
                UIView.animate(
                    withDuration: autoScrollMinimumDuration,
                    delay: 0,
                    options: [.beginFromCurrentState, .allowUserInteraction, .curveLinear],
                    animations: {
                        self.contentOffset = offset
                    },
                    completion: { _ in
                        if self.state.isTrackingTouch {
                            if self.state.trackingGrabber != .none {
                                self._showMagnifierCaret()
                                self._updateTextRangeByTrackingGrabber()
                            } else if self.state.isTrackingPreviousSelect {
                                self._showMagnifierCaret()
                                self._updateTextRangeByTrackingPreSelect()
                            } else if self.state.isTrackingCaret {
                                self._showMagnifierCaret()
                                self._updateTextRangeByTrackingCaret()
                            }
                            self._updateSelectionView()
                        }
                    }
                )
            } else {
                _endAutoScrollTimer()
            }
        } else {
            _endAutoScrollTimer()
        }
    }
    
    /// End current touch tracking (if is tracking now), and update the state.
    private func _endTouchTracking() {
        if !state.isTrackingTouch {
            return
        }
        
        state.isTrackingTouch = false
        state.trackingGrabber = .none
        state.isTrackingCaret = false
        state.isTrackingPreviousSelect = false
        state.isTouchMoved = .none
        state.isDeleteConfirm = false
        state.isClearsOnInsertionOnce = false
        _trackingRange = nil
        _selectionView.isCaretBlinks = true
        
        _removeHighlight(animated: true)
        _hideMagnifier()
        _endLongPressTimer()
        _endAutoScrollTimer()
        _updateSelectionView()
        
        panGestureRecognizer.isEnabled = isScrollEnabled
        self.panGestureEnabledCallback?(true)
    }
    
    /// Start a timer to fix the selection dot.
    private func _startSelectionDotFixTimer() {
        _selectionDotFixTimer?.invalidate()
        let timer = Timer.scheduled(
            interval: 1.0 / 15.0,
            target: self,
            selector: #selector(_fixSelectionDot),
            repeats: false
        )
        _longPressTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    /// End the timer.
    private func _endSelectionDotFixTimer() {
        _selectionDotFixTimer?.invalidate()
        _selectionDotFixTimer = nil
    }
    
    /// If it shows selection grabber and this view was moved by super view,
    /// update the selection dot in window.
    @objc
    private func _fixSelectionDot() {
        if TextUtilities.isAppExtension {
            return
        }
        let origin = self._convert(CGPoint.zero, to: TextEffectWindow.shared)
        if !origin.equalTo(_previousOriginInWindow) {
            _previousOriginInWindow = origin
            TextEffectWindow.shared?.hide(selectionDot: _selectionView)
            TextEffectWindow.shared?.show(selectionDot: _selectionView)
        }
    }
    
    /// Try to get the character range/position with word granularity from the tokenizer.
    private func _getClosestTokenRange(at position: TextPosition?) -> TextRange? {
        guard let position = _correctedTextPosition(position) else {
            return nil
        }
        var range = tokenizer.rangeEnclosingPosition(
            position,
            with: .word,
            inDirection: UITextDirection(rawValue: UITextStorageDirection.forward.rawValue)
        ) as? TextRange
        if range?.nsRange.length == 0 {
            range = tokenizer.rangeEnclosingPosition(
                position,
                with: .word,
                inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)
            ) as? TextRange
        }
        
        if range == nil || range?.nsRange.length == 0 {
            range = _innerLayout?.textRange(byExtending: position, in: UITextLayoutDirection.right, offset: 1)
            range = _correctedTextRange(range)
            if range?.nsRange.length == 0 {
                range = _innerLayout?.textRange(byExtending: position, in: UITextLayoutDirection.left, offset: 1)
                range = _correctedTextRange(range)
            }
        } else {
            let extStart: TextRange? = _innerLayout?.textRange(byExtending: range?.start)
            let extEnd: TextRange? = _innerLayout?.textRange(byExtending: range?.end)
            if let es = extStart, let ee = extEnd {
                // swiftlint:disable:next legacy_objc_type
                let nsRanges = ([es.start, es.end, ee.start, ee.end] as NSArray)
                    .sortedArray(using: #selector(es.start.compare(_:)))
                if let ranges = nsRanges as? [TextPosition],
                    let first = ranges.first,
                   let last = ranges.last {
                    range = TextRange(start: first, end: last)
                }
            }
        }
        
        range = _correctedTextRange(range)
        if range?.nsRange.length == 0 {
            range = TextRange(range: NSRange(location: 0, length: _innerText.length))
        }
        
        return _correctedTextRange(range)
    }
    
    /// Try to get the character range/position with word granularity from the tokenizer.
    private func _getClosestTokenRange(at point: CGPoint) -> TextRange? {
        let newPoint = _convertPoint(toLayout: point)
        var touchRange: TextRange? = _innerLayout?.closestTextRange(at: newPoint)
        touchRange = _correctedTextRange(touchRange)
        guard let someTouchRange = touchRange else {
            return nil
        }
        // tokenizer
        let encloseEnd = tokenizer.rangeEnclosingPosition(
            someTouchRange.end,
            with: .word,
            inDirection: UITextDirection(rawValue: UITextStorageDirection.backward.rawValue)
        ) as? TextRange
        let encloseStart = tokenizer.rangeEnclosingPosition(
            someTouchRange.start,
            with: .word,
            inDirection: UITextDirection(rawValue: UITextStorageDirection.forward.rawValue)
        ) as? TextRange
        
        if let encloseStart, let encloseEnd {
            // swiftlint:disable:next legacy_objc_type
            let nsRanges = ([encloseStart.start, encloseStart.end, encloseEnd.start, encloseEnd.end] as NSArray)
                .sortedArray(using: #selector(encloseStart.start.compare(_:)))
            if let ranges = nsRanges as? [TextPosition],
               let first = ranges.first,
               let last = ranges.last {
                touchRange = TextRange(start: first, end: last)
            }
        }
        
        if let someTouchRange = touchRange {
            let extStart: TextRange? = _innerLayout?.textRange(byExtending: someTouchRange.start)
            let extEnd: TextRange? = _innerLayout?.textRange(byExtending: someTouchRange.end)
            if let extStart, let extEnd {
                // swiftlint:disable:next legacy_objc_type
                let nsRanges = ([extStart.start, extStart.end, extEnd.start, extEnd.end] as NSArray)
                    .sortedArray(using: #selector(extStart.start.compare(_:)))
                if let ranges = nsRanges as? [TextPosition],
                   let first = ranges.first,
                   let last = ranges.last {
                    touchRange = TextRange(start: first, end: last)
                }
            }
        }
        
        if touchRange == nil {
            touchRange = TextRange()
        }
        
        if _innerText.length > 0, let range = touchRange?.nsRange, range.length == 0 {
            touchRange = TextRange(range: NSRange(location: 0, length: _innerText.length))
        }
        return touchRange
    }
    
    /// Try to get the highlight property. If exist, the range will be returnd by the range pointer.
    /// If the delegate ignore the highlight, returns nil.
    private func _getHighlight(at point: CGPoint, range: NSRangePointer?) -> TextHighlight? {
        var newPoint = point
        if !isHighlightable || _innerLayout?.containsHighlight == nil {
            return nil
        }
        newPoint = _convertPoint(toLayout: newPoint)
        var textRange: TextRange? = _innerLayout?.textRange(at: newPoint)
        textRange = _correctedTextRange(textRange)
        if textRange == nil {
            return nil
        }
        var startIndex = textRange?.start.offset ?? 0
        if startIndex == _innerText.length {
            if startIndex == 0 {
                return nil
            } else {
                startIndex -= 1
            }
        }
        let highlightRange = NSRangePointer.allocate(capacity: 1)
        defer {
            highlightRange.deallocate()
        }
        let text = _delectedText ?? _innerText
        guard let highlight = text.attribute(
            TextAttribute.textHighlight,
            at: startIndex,
            longestEffectiveRange: highlightRange,
            in: NSRange(location: 0, length: _innerText.length)
        ) as? TextHighlight else {
            return nil
        }
        
        var shouldTap = true
        var shouldLongPress = true
        if highlight.tapAction == nil, highlight.longPressAction == nil {
            if let delegate = _outerDelegate {
                if let tap = delegate.textView?(self, shouldTap: highlight, in: highlightRange.pointee) {
                    shouldTap = tap
                }
                if let longPress = delegate.textView?(self, shouldLongPress: highlight, in: highlightRange.pointee) {
                    shouldLongPress = longPress
                }
            }
        }
        if !shouldTap, !shouldLongPress {
            return nil
        }
        
        range?.pointee = highlightRange.pointee
        
        return highlight
    }
    
    /// Return the ranged magnifier popover offset from the baseline, base on `_trackingPoint`.
    private func _getMagnifierCaretOffset() -> CGFloat {
        var magPoint: CGPoint = _trackingPoint
        magPoint = _convertPoint(toLayout: magPoint)
        if isVerticalForm {
            magPoint.x += magnifierRangedTrackFixValue
        } else {
            magPoint.y += magnifierRangedTrackFixValue
        }
        let position = _innerLayout?.closestPosition(to: magPoint)
        let lineIndex = _innerLayout?.lineIndex(for: position) ?? 0
        if lineIndex >= 0, lineIndex < (_innerLayout?.lines.count ?? 0),
           let line = _innerLayout?.lines[lineIndex] {
            if isVerticalForm {
                magPoint.x = TextUtilities.clamp(x: magPoint.x, low: line.left, high: line.right)
                return magPoint.x - line.position.x + magnifierRangedPopoverOffset
            } else {
                magPoint.y = TextUtilities.clamp(x: magPoint.y, low: line.top, high: line.bottom)
                return magPoint.y - line.position.y + magnifierRangedPopoverOffset
            }
        } else {
            return 0
        }
    }
    
    /// Return a TextMoveDirection from `_touchBeganPoint` to `_trackingPoint`.
    private func _getMoveDirection() -> TextMoveDirection {
        let moveH = _trackingPoint.x - _touchBeganPoint.x
        let moveV = _trackingPoint.y - _touchBeganPoint.y
        if abs(Float(moveH)) > abs(Float(moveV)) {
            if abs(Float(moveH)) > longPressAllowableMovement {
                return moveH > 0 ? TextMoveDirection.right : TextMoveDirection.left
            }
        } else {
            if abs(Float(moveV)) > longPressAllowableMovement {
                return moveV > 0 ? TextMoveDirection.bottom : TextMoveDirection.top
            }
        }
        return .none
    }
    
    /// Get the auto scroll offset in one tick time.
    private func _getAutoscrollOffset() -> CGFloat {
        if !state.isTrackingTouch {
            return 0
        }
        
        var bounds: CGRect = self.bounds
        bounds.origin = CGPoint.zero
        let mgr = TextKeyboardManager.default
        if mgr.keyboardVisible, window != nil, superview != nil, isFirstResponder, !isVerticalForm {
            var kbRect = mgr.convert(mgr.keyboardFrame, to: self)
            kbRect.origin.y -= extraAccessoryViewHeight
            kbRect.size.height += extraAccessoryViewHeight
            
            kbRect.origin.x -= contentOffset.x
            kbRect.origin.y -= contentOffset.y
            let inter: CGRect = bounds.intersection(kbRect)
            if !inter.isNull, inter.size.height > 1, inter.size.width > 1 {
                if inter.minY > bounds.minY {
                    bounds.size.height -= inter.size.height
                }
            }
        }
        
        var point = _trackingPoint
        point.x -= contentOffset.x
        point.y -= contentOffset.y
        
        let maxOfs: CGFloat = 32 // a good value ~
        var ofs: CGFloat = 0
        if isVerticalForm {
            if point.x < contentInset.left {
                ofs = (point.x - contentInset.left - 5) * 0.5
                if ofs < -maxOfs {
                    ofs = -maxOfs
                }
            } else if point.x > bounds.size.width {
                ofs = ((point.x - bounds.size.width) + 5) * 0.5
                if ofs > maxOfs {
                    ofs = maxOfs
                }
            }
        } else {
            if point.y < contentInset.top {
                ofs = (point.y - contentInset.top - 5) * 0.5
                if ofs < -maxOfs {
                    ofs = -maxOfs
                }
            } else if point.y > bounds.size.height {
                ofs = ((point.y - bounds.size.height) + 5) * 0.5
                if ofs > maxOfs {
                    ofs = maxOfs
                }
            }
        }
        return ofs
    }
    
    /// Visible size based on bounds and insets
    private func _getVisibleSize() -> CGSize {
        var visibleSize: CGSize = bounds.size
        visibleSize.width -= contentInset.left - contentInset.right
        visibleSize.height -= contentInset.top - contentInset.bottom
        if visibleSize.width < 0 {
            visibleSize.width = 0
        }
        if visibleSize.height < 0 {
            visibleSize.height = 0
        }
        return visibleSize
    }
    
    /// Returns whether the text view can paste data from pastboard.
    private func _isPasteboardContainsValidValue() -> Bool {
        let pasteboard = UIPasteboard.general
        if (pasteboard.string?.length ?? 0) > 0 {
            return true
        }
        if let attributed = pasteboard.attributedString, attributed.length > 0 {
            if isAllowsPasteAttributedString {
                return true
            }
        }
        if pasteboard.image != nil || (pasteboard.imageData?.count ?? 0) > 0 {
            if isAllowsPasteImage {
                return true
            }
        }
        return false
    }
    
    /// Save current selected attributed text to pasteboard.
    private func _copySelectedTextToPasteboard() {
        if isAllowsCopyAttributedString,
           let copied = _innerText.mutableCopy() as? NSMutableAttributedString {
            let fixedLocation = max(_selectedTextRange.nsRange.location, copied.rangeOfAll.location)
            let fixedLength = min(_selectedTextRange.nsRange.length, copied.rangeOfAll.length)
            let fixedRange = NSRange(location: fixedLocation, length: fixedLength)
            let text: NSAttributedString = copied.attributedSubstring(from: fixedRange)
            if text.length > 0 {
                UIPasteboard.general.attributedString = text
            }
        } else {
            let string = _innerText.plainText(for: _selectedTextRange.nsRange)
            if (string?.length ?? 0) > 0 {
                UIPasteboard.general.string = string
            }
        }
    }
    
    /// Update the text view state when pasteboard changed.
    @objc
    private func _pasteboardChanged() {
        if state.isShowingMenu {
            let menu = UIMenuController.shared
            menu.update()
        }
    }
    
    /// Whether the position is valid (not out of bounds).
    private func _isTextPositionValid(_ position: TextPosition?) -> Bool {
        guard let position = position else {
            return false
        }
        if position.offset < 0 {
            return false
        }
        if position.offset > _innerText.length {
            return false
        }
        if position.offset == 0, position.affinity == TextAffinity.backward {
            return false
        }
        if position.offset == _innerText.length, position.affinity == TextAffinity.backward {
            return false
        }
        return true
    }
    
    /// Whether the range is valid (not out of bounds).
    private func _isTextRangeValid(_ range: TextRange?) -> Bool {
        if !_isTextPositionValid(range?.start) {
            return false
        }
        if !_isTextPositionValid(range?.end) {
            return false
        }
        return true
    }
    
    /// Correct the position if it out of bounds.
    private func _correctedTextPosition(_ position: TextPosition?) -> TextPosition? {
        guard let position = position else {
            return nil
        }
        if _isTextPositionValid(position) {
            return position
        }
        if position.offset < 0 {
            return TextPosition(offset: 0)
        }
        if position.offset > _innerText.length {
            return TextPosition(offset: _innerText.length)
        }
        if position.offset == 0, position.affinity == TextAffinity.backward {
            return TextPosition(offset: position.offset)
        }
        if position.offset == _innerText.length, position.affinity == TextAffinity.backward {
            return TextPosition(offset: position.offset)
        }
        return position
    }
    
    /// Correct the range if it out of bounds.
    private func _correctedTextRange(_ range: TextRange?) -> TextRange? {
        guard let range = range else {
            return nil
        }
        if _isTextRangeValid(range) {
            return range
        }
        guard let start = _correctedTextPosition(range.start) else {
            return nil
        }
        guard let end = _correctedTextPosition(range.end) else {
            return nil
        }
        return TextRange(start: start, end: end)
    }
    
    /// Convert the point from this view to text layout.
    private func _convertPoint(toLayout point: CGPoint) -> CGPoint {
        var newPoint = point
        guard let innerLayout = _innerLayout else {
            return newPoint
        }
        let boundingSize: CGSize = innerLayout.textBoundingSize
        if innerLayout.container.isVerticalForm {
            var width = innerLayout.textBoundingSize.width
            if width < bounds.size.width {
                width = bounds.size.width
            }
            newPoint.x += innerLayout.container.size.width - width
            if boundingSize.width < bounds.size.width {
                if textVerticalAlignment == TextVerticalAlignment.center {
                    newPoint.x += (bounds.size.width - boundingSize.width) * 0.5
                } else if textVerticalAlignment == TextVerticalAlignment.bottom {
                    newPoint.x += bounds.size.width - boundingSize.width
                }
            }
            return newPoint
        } else {
            if boundingSize.height < bounds.size.height {
                if textVerticalAlignment == TextVerticalAlignment.center {
                    newPoint.y -= (bounds.size.height - boundingSize.height) * 0.5
                } else if textVerticalAlignment == TextVerticalAlignment.bottom {
                    newPoint.y -= bounds.size.height - boundingSize.height
                }
            }
            return newPoint
        }
    }
    
    /// Convert the point from text layout to this view.
    private func _convertPoint(fromLayout point: CGPoint) -> CGPoint {
        var newPoint = point
        guard let innerLayout = _innerLayout else {
            return newPoint
        }
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
    
    /// Convert the rect from this view to text layout.
    private func _convertRect(toLayout rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin = _convertPoint(toLayout: rect.origin)
        return rect
    }
    
    /// Convert the rect from text layout to this view.
    private func _convertRect(fromLayout rect: CGRect) -> CGRect {
        var newRect = rect
        newRect.origin = _convertPoint(fromLayout: newRect.origin)
        return newRect
    }
    
    /// Replace the range with the text, and change the `_selectTextRange`.
    /// The caller should make sure the `range` and `text` are valid before call this method.
    private func _replace(_ range: TextRange, withText text: String, notifyToDelegate notify: Bool) {
        if notify {
            _inputDelegate?.textWillChange(self)
        }
        let newRange = NSRange(location: range.nsRange.location, length: text.length)
        _innerText.replaceCharacters(in: range.nsRange, with: text)
        _innerText.removeDiscontinuousAttributes(in: newRange)

        if notify {
            _inputDelegate?.textDidChange(self)
        }
        
        if NSEqualRanges(range.nsRange, _selectedTextRange.nsRange) {
            if notify {
                _inputDelegate?.selectionWillChange(self)
            }
            var newRange = NSRange(location: 0, length: 0)
            // FIXBUG: 连续输入 Emoji 时出现的乱码的问题
            // 原因：NSString 中 Emoji 表情的 length 等于 2, 而 Swift 中 Emoji 的 Count 等于1
            // innerText 继承于 NSString, 所以此处用 (text as NSString).length
            // now use text.utf16.count replace (text as NSString).length
            newRange.location = _selectedTextRange.start.offset + text.length
            _selectedTextRange = TextRange(range: newRange)
            if notify {
                _inputDelegate?.selectionDidChange(self)
            }
        } else {
            if range.nsRange.length != text.length {
                if notify {
                    _inputDelegate?.selectionWillChange(self)
                }
                let unionRange: NSRange = NSIntersectionRange(_selectedTextRange.nsRange, range.nsRange)
                if unionRange.length == 0 {
                    // no intersection
                    if range.end.offset <= _selectedTextRange.start.offset {
                        let ofs = text.length - range.nsRange.length
                        var newRange = _selectedTextRange.nsRange
                        newRange.location += ofs
                        _selectedTextRange = TextRange(range: newRange)
                    }
                } else if unionRange.length == _selectedTextRange.nsRange.length {
                    // target range contains selected range
                    _selectedTextRange = TextRange(
                        range: NSRange(location: range.start.offset + text.length, length: 0)
                    )
                } else if range.start.offset >= _selectedTextRange.start.offset,
                          range.end.offset <= _selectedTextRange.end.offset {
                    // target range inside selected range
                    let ofs = text.length - range.nsRange.length
                    var newRange: NSRange = _selectedTextRange.nsRange
                    newRange.length += ofs
                    _selectedTextRange = TextRange(range: newRange)
                } else {
                    // interleaving
                    if range.start.offset < _selectedTextRange.start.offset {
                        var newRange: NSRange = _selectedTextRange.nsRange
                        newRange.location = range.start.offset + text.length
                        newRange.length -= unionRange.length
                        _selectedTextRange = TextRange(range: newRange)
                    } else {
                        var newRange: NSRange = _selectedTextRange.nsRange
                        newRange.length -= unionRange.length
                        _selectedTextRange = TextRange(range: newRange)
                    }
                }
                if let range = _correctedTextRange(_selectedTextRange) {
                    _selectedTextRange = range
                }
                if notify {
                    _inputDelegate?.selectionDidChange(self)
                }
            }
        }
    }
    
    /// Save current typing attributes to the attributes holder.
    private func _updateAttributesHolder() {
        if _innerText.length > 0 {
            let index: Int = _selectedTextRange.end.offset == 0 ? 0 : _selectedTextRange.end.offset - 1
            let attributes = _innerText.attributes(at: index) ?? [:]
            
            _typingAttributesHolder.setAttributes([:], range: _typingAttributesHolder.rangeOfAll)
            for attr in attributes {
                _typingAttributesHolder.setAttribute(attr.key, value: attr.value)
            }
            _typingAttributesHolder.removeDiscontinuousAttributes(
                in: NSRange(location: 0, length: _typingAttributesHolder.length)
            )
            _typingAttributesHolder.removeAttribute(
                TextAttribute.textBorder,
                range: NSRange(location: 0, length: _typingAttributesHolder.length)
            )
            _typingAttributesHolder.removeAttribute(
                TextAttribute.textBackgroundBorder,
                range: NSRange(location: 0, length: _typingAttributesHolder.length)
            )
        }
    }
    
    /// Update outer properties from current inner data.
    private func _updateOuterProperties() {
        _updateAttributesHolder()
        let style: NSParagraphStyle = _innerText.paragraphStyle ??
        _typingAttributesHolder.paragraphStyle ??
        .default
        
        let font: UIFont = _innerText.font ??
        _typingAttributesHolder.font ??
        Self._defaultFont
        
        let color: UIColor = _innerText.textColor ??
        _typingAttributesHolder.textColor ??
        .black
        
        _setText(_innerText.plainText(for: NSRange(location: 0, length: _innerText.length)))
        _setFont(font)
        _setTextColor(color)
        _setTextAlignment(style.alignment)
        _setSelectedRange(_selectedTextRange.nsRange)
        if state.isSuppressSetTypingAttributes == false {
            _setTypingAttributes(_typingAttributesHolder.attributes)
        }
        _setAttributedText(_innerText)
    }
    
    /// Parse text with `textParser` and update the _selectedTextRange.
    ///
    /// - Returns: Whether changed (text or selection)
    @discardableResult
    private func _parseText() -> Bool {
        if let textParser = self.textParser {
            let oldTextRange = _selectedTextRange
            var newRange = _selectedTextRange.nsRange
            
            _inputDelegate?.textWillChange(self)
            let textChanged = textParser.parseText(_innerText, selectedRange: &newRange)
            _inputDelegate?.textDidChange(self)
            
            var newTextRange = TextRange(range: newRange)
            if let fixedRange = _correctedTextRange(newTextRange) {
                newTextRange = fixedRange
            }
            
            if oldTextRange != newTextRange {
                _inputDelegate?.selectionWillChange(self)
                _selectedTextRange = newTextRange
                _inputDelegate?.selectionDidChange(self)
            }
            return textChanged
        }
        return false
    }
    
    /// Returns whether the text should be detected by the data detector.
    private func _shouldDetectText() -> Bool {
        if _dataDetector == nil {
            return false
        }
        if !isHighlightable {
            return false
        }
        if _linkTextAttributes?.count ?? 0 == 0 && _highlightTextAttributes?.count ?? 0 == 0 {
            return false
        }
        if isFirstResponder || _containerView.isFirstResponder {
            return false
        }
        return true
    }
    
    /// Detect the data in text and add highlight to the data range.
    /// @return Whether detected.
    private func _detectText(_ text: NSMutableAttributedString?) -> Bool {
        guard let text = text, text.length > 0 else {
            return false
        }
        if !_shouldDetectText() {
            return false
        }
        
        var detected = false
        _dataDetector?.enumerateMatches(
            in: text.string,
            options: [],
            range: NSRange(location: 0, length: text.length),
            using: { result, _, _ in
                guard let result = result else {
                    return
                }
                switch result.resultType {
                case .address, .date, .link, .phoneNumber:
                    detected = true
                    if let highlightAttributes = self.highlightTextAttributes, !highlightAttributes.isEmpty {
                        let highlight = TextHighlight(attributes: self.highlightTextAttributes)
                        text.setTextHighlight(highlight, range: result.range)
                    }
                    if let linkAttributes = self.linkTextAttributes, !linkAttributes.isEmpty {
                        for (key, obj) in linkAttributes {
                            text.setAttribute(key, value: obj, range: result.range)
                        }
                    }
                default:
                    break
                }
            }
        )
        return detected
    }
    
    /// Returns the `root` view controller (returns nil if not found).
    private func _getRootViewController() -> UIViewController? {
        var controller: UIViewController?
        if controller == nil {
            controller = TextUtilities.keyWindow?.rootViewController
        }
        if controller == nil {
            controller = TextUtilities.windowScene?.windows.first?.rootViewController
        }
        if controller == nil {
            controller = _viewController()
        }
        if controller == nil {
            return nil
        }
        while controller?.view.window == nil, controller?.presentedViewController != nil {
            controller = controller?.presentedViewController
        }
        guard controller?.view.window != nil else {
            return nil
        }
        return controller
    }
    
    /// Clear the undo and redo stack, and capture current state to undo stack.
    private func _resetUndoAndRedoStack() {
        _undoStack.removeAll()
        _redoStack.removeAll()
        let object = TextViewUndoObject(
            text: _innerText.copy() as? NSAttributedString,
            range: _selectedTextRange.nsRange
        )
        _lastTypeRange = _selectedTextRange.nsRange
        
        _undoStack.append(object)
    }
    
    /// Clear the redo stack.
    private func _resetRedoStack() {
        _redoStack.removeAll()
    }
    
    /// Capture current state to undo stack.
    private func _saveToUndoStack() {
        if !isAllowsUndoAndRedo {
            return
        }
        if let text = attributedText, let lastText = _undoStack.last?.text {
            if lastText.isEqual(to: text) {
                return
            }
        }
        
        if let copy = _innerText.copy() as? NSAttributedString {
            let object = TextViewUndoObject(text: copy, range: _selectedTextRange.nsRange)
            _lastTypeRange = _selectedTextRange.nsRange
            _undoStack.append(object)
            while _undoStack.count > maximumUndoLevel {
                _undoStack.remove(at: 0)
            }
        }
    }
    
    /// Capture current state to redo stack.
    private func _saveToRedoStack() {
        if !isAllowsUndoAndRedo {
            return
        }
        let lastObject = _redoStack.last
        if let text = attributedText {
            if lastObject?.text?.isEqual(to: text) ?? false {
                return
            }
        }
        
        if let copy = _innerText.copy() as? NSAttributedString {
            let object = TextViewUndoObject(text: copy, range: _selectedTextRange.nsRange)
            _redoStack.append(object)
            while _redoStack.count > maximumUndoLevel {
                _redoStack.remove(at: 0)
            }
        }
    }
    
    private func _canUndo() -> Bool {
        guard !_undoStack.isEmpty else {
            return false
        }
        let object = _undoStack.last
        if object?.text?.isEqual(to: _innerText) ?? false {
            return false
        }
        return true
    }
    
    private func _canRedo() -> Bool {
        guard !_redoStack.isEmpty else {
            return false
        }
        let object = _undoStack.last
        if object?.text?.isEqual(to: _innerText) ?? false {
            return false
        }
        return true
    }
    
    private func _undo() {
        if !_canUndo() {
            return
        }
        _saveToRedoStack()
        let object = _undoStack.last
        _undoStack.removeLast()
        
        state.isInsideUndoBlock = true
        if let text = object?.text {
            _attributedText = text
        }
        if let range = object?.selectedRange {
            _selectedRange = range
        }
        state.isInsideUndoBlock = false
    }
    
    private func _redo() {
        if !_canRedo() {
            return
        }
        _saveToUndoStack()
        let object = _redoStack.last
        _redoStack.removeLast()
        
        state.isInsideUndoBlock = true
        if let text = object?.text {
            _attributedText = text
        }
        if let range = object?.selectedRange {
            _selectedRange = range
        }
        state.isInsideUndoBlock = false
    }
    
    private func _restoreFirstResponderAfterUndoAlert() {
        if state.isFirstResponderBeforeUndoAlert {
            perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0)
        }
    }
    
    /// Show undo alert if it can undo or redo.
    private func _showUndoRedoAlert() {
        #if os(iOS)
        state.isFirstResponderBeforeUndoAlert = isFirstResponder
        let strings = _localizedUndoStrings()
        let canUndo = _canUndo()
        let canRedo = _canRedo()
        
        let controller: UIViewController? = _getRootViewController()
        
        if canUndo, canRedo {
            let alert = UIAlertController(title: strings[4], message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: strings[3], style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self._undo()
                self._restoreFirstResponderAfterUndoAlert()
            }))
            alert.addAction(UIAlertAction(title: strings[2], style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self._redo()
                self._restoreFirstResponderAfterUndoAlert()
            }))
            alert.addAction(UIAlertAction(title: strings[0], style: .cancel, handler: { [weak self] _ in
                guard let self else { return }
                self._restoreFirstResponderAfterUndoAlert()
            }))
            controller?.present(alert, animated: true)
        } else if canUndo {
            let alert = UIAlertController(title: strings[4], message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: strings[3], style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self._undo()
                self._restoreFirstResponderAfterUndoAlert()
            }))
            alert.addAction(UIAlertAction(title: strings[0], style: .cancel, handler: { [weak self] _ in
                guard let self else { return }
                self._restoreFirstResponderAfterUndoAlert()
            }))
            controller?.present(alert, animated: true)
        } else if canRedo {
            let alert = UIAlertController(title: strings[2], message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: strings[1], style: .default, handler: { [weak self] _ in
                guard let self else { return }
                self._redo()
                self._restoreFirstResponderAfterUndoAlert()
            }))
            alert.addAction(UIAlertAction(title: strings[0], style: .cancel, handler: { [weak self] _ in
                guard let self else { return }
                self._restoreFirstResponderAfterUndoAlert()
            }))
            controller?.present(alert, animated: true)
        }
        #endif
    }
    
    // MARK: - Private Setter
    
    private func _setText(_ text: String?) {
        if _text == text {
            return
        }
        willChangeValue(forKey: "text")
        _text = text ?? ""
        didChangeValue(forKey: "text")
        accessibilityLabel = _text
    }
    
    private func _setFont(_ font: UIFont?) {
        if _font == font {
            return
        }
        willChangeValue(forKey: "font")
        _font = font ?? Self._defaultFont
        didChangeValue(forKey: "font")
    }
    
    private func _setTextColor(_ textColor: UIColor?) {
        if _textColor === textColor {
            return
        }
        if let current = _textColor, let new = textColor {
            if CFGetTypeID(current.cgColor) == CFGetTypeID(new.cgColor),
                CFGetTypeID(current.cgColor) == CGColor.typeID {
                if _textColor == textColor {
                    return
                }
            }
        }
        willChangeValue(forKey: "textColor")
        _textColor = textColor
        didChangeValue(forKey: "textColor")
    }
    
    private func _setTextAlignment(_ textAlignment: NSTextAlignment) {
        if _textAlignment == textAlignment {
            return
        }
        willChangeValue(forKey: "textAlignment")
        _textAlignment = textAlignment
        didChangeValue(forKey: "textAlignment")
    }
    
    private func _setDataDetectorTypes(_ dataDetectorTypes: UIDataDetectorTypes) {
        if _dataDetectorTypes == dataDetectorTypes {
            return
        }
        willChangeValue(forKey: "dataDetectorTypes")
        _dataDetectorTypes = dataDetectorTypes
        didChangeValue(forKey: "dataDetectorTypes")
    }
    
    private func _setLinkTextAttributes(_ linkTextAttributes: [NSAttributedString.Key: Any]?) {
        // swiftlint:disable legacy_objc_type
        let current = _linkTextAttributes as NSDictionary?
        let new = linkTextAttributes as NSDictionary?
        // swiftlint:enable legacy_objc_type
        if current == new || current?.isEqual(new) ?? false {
            return
        }
        willChangeValue(forKey: "linkTextAttributes")
        _linkTextAttributes = linkTextAttributes
        didChangeValue(forKey: "linkTextAttributes")
    }
    
    private func _setHighlightTextAttributes(_ highlightTextAttributes: [NSAttributedString.Key: Any]?) {
        // swiftlint:disable legacy_objc_type
        let current = _highlightTextAttributes as NSDictionary?
        let new = highlightTextAttributes as NSDictionary?
        // swiftlint:enable legacy_objc_type
        if current == new || current?.isEqual(new) ?? false {
            return
        }
        willChangeValue(forKey: "highlightTextAttributes")
        _highlightTextAttributes = highlightTextAttributes
        didChangeValue(forKey: "highlightTextAttributes")
    }
    
    private func _setTextParser(_ textParser: TextParser?) {
        if _textParser === textParser || _textParser?.isEqual(textParser) ?? false {
            return
        }
        willChangeValue(forKey: "textParser")
        _textParser = textParser
        didChangeValue(forKey: "textParser")
    }
    
    private func _setAttributedText(_ attributedText: NSAttributedString?) {
        if _attributedText == attributedText {
            return
        }
        willChangeValue(forKey: "attributedText")
        _attributedText = (attributedText?.copy() as? NSAttributedString) ?? NSAttributedString()
        didChangeValue(forKey: "attributedText")
    }
    
    private func _setTextContainerInset(_ textContainerInset: UIEdgeInsets) {
        if _textContainerInset == textContainerInset {
            return
        }
        willChangeValue(forKey: "textContainerInset")
        _textContainerInset = textContainerInset
        didChangeValue(forKey: "textContainerInset")
    }
    
    private func _setExclusionPaths(_ exclusionPaths: [UIBezierPath]?) {
        if _exclusionPaths == exclusionPaths {
            return
        }
        willChangeValue(forKey: "exclusionPaths")
        _exclusionPaths = exclusionPaths
        didChangeValue(forKey: "exclusionPaths")
    }
    
    private func _setVerticalForm(_ verticalForm: Bool) {
        if _verticalForm == verticalForm {
            return
        }
        willChangeValue(forKey: "isVerticalForm")
        _verticalForm = verticalForm
        didChangeValue(forKey: "isVerticalForm")
    }
    
    private func _setLinePositionModifier(_ linePositionModifier: TextLinePositionModifier?) {
        if _linePositionModifier === linePositionModifier {
            return
        }
        willChangeValue(forKey: "linePositionModifier")
        _linePositionModifier = linePositionModifier
        didChangeValue(forKey: "linePositionModifier")
    }
    
    private func _setSelectedRange(_ selectedRange: NSRange) {
        if NSEqualRanges(_selectedRange, selectedRange) {
            return
        }
        willChangeValue(forKey: "selectedRange")
        _selectedRange = selectedRange
        didChangeValue(forKey: "selectedRange")
        
        _outerDelegate?.textViewDidChangeSelection?(self)
    }
    
    private func _setTypingAttributes(_ typingAttributes: [NSAttributedString.Key: Any]?) {
        // swiftlint:disable legacy_objc_type
        let current = _typingAttributes as NSDictionary?
        let new = typingAttributes as NSDictionary?
        // swiftlint:enable legacy_objc_type
        if current == new || current?.isEqual(new) ?? false {
            return
        }
        willChangeValue(forKey: "typingAttributes")
        _typingAttributes = typingAttributes
        didChangeValue(forKey: "typingAttributes")
    }
    
    // MARK: - Private Init

    private func _initTextView() {
        delaysContentTouches = false
        canCancelContentTouches = true
        clipsToBounds = true
        tintColor = Self._defaultTintColor
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        super.delegate = self
        
        _markedTextRange = nil
        _innerContainer.insets = containerDefaultInsets
        
        let foregroundColor = NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String)
        let cgColor = Self._defaultTintColor.cgColor
        _linkTextAttributes = [
            .foregroundColor: Self._defaultTintColor,
            foregroundColor: cgColor
        ]
        
        let highlight = TextHighlight()
        let border = TextBorder()
        border.insets = UIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2)
        border.fillColor = UIColor(white: 0.1, alpha: 0.2)
        border.cornerRadius = 3
        highlight.border = border
        _highlightTextAttributes = highlight.attributes
        
        _placeHolderView.isUserInteractionEnabled = false
        _placeHolderView.isHidden = true
        
        _containerView = TextContainerView()
        _containerView.hostView = self
        
        _selectionView = TextSelectionView()
        _selectionView.isUserInteractionEnabled = false
        _selectionView.hostView = self
        _selectionView.color = Self._defaultTintColor
        
        _magnifierCaret = TextMagnifier()
        _magnifierCaret.hostView = _containerView
        
        addSubview(_placeHolderView)
        addSubview(_containerView)
        addSubview(_selectionView)
        
        debugOption = TextDebugOption.shared
        TextDebugOption.add(self)
        
        _updateInnerContainerSize()
        _update()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_pasteboardChanged),
            name: UIPasteboard.changedNotification,
            object: nil
        )
        TextKeyboardManager.default.add(observer: self)
        
        isAccessibilityElement = true
    }
    
    // MARK: - Working with the Selection and Menu

    /// Scrolls the receiver until the text in the specified range is visible.
    public func scrollRangeToVisible(_ range: NSRange) {
        var textRange = TextRange(range: range)
        if let range = _correctedTextRange(textRange) {
            textRange = range
        }
        _scrollRangeToVisible(textRange)
    }
    
    override open func tintColorDidChange() {
        if responds(to: #selector(setter: tintColor)) {
            let color: UIColor? = tintColor
            var attrs = _highlightTextAttributes
            var linkAttrs = _linkTextAttributes ?? [NSAttributedString.Key: Any]()
            
            if color == nil {
                attrs?.removeValue(forKey: .foregroundColor)
                attrs?.removeValue(forKey: NSAttributedString.Key(kCTForegroundColorAttributeName as String))
                linkAttrs[.foregroundColor] = Self._defaultTintColor
                let foregroundColor = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
                linkAttrs[foregroundColor] = Self._defaultTintColor.cgColor
            } else {
                attrs?[.foregroundColor] = color
                attrs?[NSAttributedString.Key(kCTForegroundColorAttributeName as String)] = color?.cgColor
                linkAttrs[.foregroundColor] = color
                linkAttrs[NSAttributedString.Key(kCTForegroundColorAttributeName as String)] = color?.cgColor
            }
            highlightTextAttributes = attrs
            _selectionView.color = color ?? Self._defaultTintColor
            linkTextAttributes = linkAttrs
            _commitUpdate()
        }
    }
    
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = size
        if !isVerticalForm && size.width <= 0 {
            size.width = TextContainer.maxSize.width
        }
        if isVerticalForm && size.height <= 0 {
            size.height = TextContainer.maxSize.height
        }
        
        if (!isVerticalForm && size.width == bounds.size.width) ||
            (isVerticalForm && size.height == bounds.size.height) {
            _updateIfNeeded()
            if !isVerticalForm {
                if _containerView.bounds.size.height <= size.height {
                    return _containerView.bounds.size
                }
            } else {
                if _containerView.bounds.size.width <= size.width {
                    return _containerView.bounds.size
                }
            }
        }
        
        if !isVerticalForm {
            size.height = TextContainer.maxSize.height
        } else {
            size.width = TextContainer.maxSize.width
        }
        
        let container: TextContainer? = _innerContainer.copy() as? TextContainer
        container?.size = size
        
        let layout = TextLayout(container: container, text: _innerText)
        return layout?.textBoundingSize ?? .zero
    }
    
    // MARK: - Override UIResponder
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        _updateIfNeeded()
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: _containerView)
        
        _trackingTime = touch.timestamp
        _touchBeganTime = _trackingTime
        _trackingPoint = point
        _touchBeganPoint = _trackingPoint
        _trackingRange = _selectedTextRange
        
        state.trackingGrabber = .none
        state.isTrackingCaret = false
        state.isTrackingPreviousSelect = false
        state.isTrackingTouch = true
        state.isSwallowTouch = true
        state.isTouchMoved = .none
        
        if !isFirstResponder && !state.isSelectedWithoutEdit && isHighlightable {
            _highlight = _getHighlight(at: point, range: &_highlightRange)
            _highlightLayout = nil
        }
        
        if (!isSelectable && _highlight == nil) || state.isTouchBeganIgnored {
            state.isSwallowTouch = false
            state.isTrackingTouch = false
        }
        
        if state.isTrackingTouch {
            _startLongPressTimer()
            if _highlight != nil {
                _showHighlight(animated: false)
            } else {
                if _selectionView.isGrabberContains(point) {
                    // track grabber
                    panGestureRecognizer.isEnabled = false // disable scroll view
                    self.panGestureEnabledCallback?(false)
                    _hideMenu()
                    state.trackingGrabber = _selectionView.isStartGrabberContains(point) ? .start : .end
                    _magnifierCaretOffset = _getMagnifierCaretOffset()
                } else {
                    if _selectedTextRange.nsRange.length == 0, isFirstResponder {
                        if _selectionView.isCaretContains(point) {
                            // track caret
                            state.isTrackingCaret = true
                            panGestureRecognizer.isEnabled = false // disable scroll view
                            self.panGestureEnabledCallback?(false)
                        }
                    }
                }
            }
            _updateSelectionView()
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
        let point = touch.location(in: _containerView)
        
        _trackingTime = touch.timestamp
        _trackingPoint = point
        
        if state.isTouchMoved == .none {
            state.isTouchMoved = _getMoveDirection()
            if state.isTouchMoved != .none {
                _endLongPressTimer()
            }
        }
        state.isClearsOnInsertionOnce = false
        
        if state.isTrackingTouch {
            var showMagnifierCaret = false
            
            if _highlight != nil {
                let highlight = _getHighlight(at: _trackingPoint, range: nil)
                if highlight == _highlight {
                    _showHighlight(animated: true)
                } else {
                    _hideHighlight(animated: true)
                }
            } else {
                _trackingRange = _selectedTextRange
                if state.trackingGrabber != .none {
                    panGestureRecognizer.isEnabled = false
                    self.panGestureEnabledCallback?(false)
                    _hideMenu()
                    _updateTextRangeByTrackingGrabber()
                    showMagnifierCaret = true
                } else if state.isTrackingPreviousSelect {
                    _updateTextRangeByTrackingPreSelect()
                    showMagnifierCaret = true
                } else if state.isTrackingCaret || (_markedTextRange != nil) || isFirstResponder {
                    if state.isTrackingCaret || state.isTouchMoved != .none {
                        state.isTrackingCaret = true
                        _hideMenu()
                        if isVerticalForm {
                            if state.isTouchMoved == .top || state.isTouchMoved == .bottom {
                                panGestureRecognizer.isEnabled = false
                                self.panGestureEnabledCallback?(false)
                            }
                        } else {
                            if state.isTouchMoved == .left || state.isTouchMoved == .right {
                                panGestureRecognizer.isEnabled = false
                                self.panGestureEnabledCallback?(false)
                            }
                        }
                        _updateTextRangeByTrackingCaret()
                        showMagnifierCaret = true
                    }
                }
            }
            _updateSelectionView()
            if showMagnifierCaret {
                _showMagnifierCaret()
            }
        }
        
        let autoScrollOffset: CGFloat = _getAutoscrollOffset()
        if autoScrollOffset != _autoScrollOffset {
            if abs(Float(autoScrollOffset)) < abs(Float(_autoScrollOffset)) {
                _autoScrollAcceleration /= 2
            }
            _autoScrollOffset = autoScrollOffset
            if _autoScrollOffset != 0 && state.isTouchMoved != .none {
                _startAutoScrollTimer()
            }
        }
        
        if !state.isSwallowTouch {
            super.touchesMoved(touches, with: event)
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        _updateIfNeeded()
        guard let touch = touches.first else {
            return
        }
        let point = touch.location(in: _containerView)
        
        _trackingTime = touch.timestamp
        _trackingPoint = point
        
        if state.isTouchMoved == .none {
            state.isTouchMoved = _getMoveDirection()
        }
        if state.isTrackingTouch {
            _hideMagnifier()
            
            if let highlight = _highlight, let innerLayout = _innerLayout {
                if state.isShowingHighlight {
                    if let tapAction = highlight.tapAction {
                        var rect: CGRect = innerLayout.rect(for: TextRange(range: _highlightRange))
                        rect = _convertRect(fromLayout: rect)
                        tapAction(self, _innerText, _highlightRange, rect)
                    } else {
                        var shouldTap = true
                        if let tap = _outerDelegate?.textView?(self, shouldTap: highlight, in: _highlightRange) {
                            shouldTap = tap
                        }
                        if shouldTap {
                            var rect = innerLayout.rect(for: TextRange(range: _highlightRange))
                            rect = _convertRect(fromLayout: rect)
                            _outerDelegate?.textView?(self, didTap: highlight, in: _highlightRange, rect: rect)
                        }
                    }
                    _removeHighlight(animated: true)
                }
            } else {
                if state.isTrackingCaret {
                    if state.isTouchMoved != .none {
                        _updateTextRangeByTrackingCaret()
                        _showMenu()
                    } else {
                        if state.isShowingMenu {
                            _hideMenu()
                        } else {
                            _showMenu()
                        }
                    }
                } else if state.trackingGrabber != .none {
                    _updateTextRangeByTrackingGrabber()
                    _showMenu()
                } else if state.isTrackingPreviousSelect {
                    _updateTextRangeByTrackingPreSelect()
                    if let trackingRange = _trackingRange, trackingRange.nsRange.length > 0 {
                        state.isSelectedWithoutEdit = true
                        _showMenu()
                    } else {
                        perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0)
                    }
                } else if state.isDeleteConfirm || _markedTextRange != nil {
                    _updateTextRangeByTrackingCaret()
                    _hideMenu()
                } else {
                    if state.isTouchMoved == .none {
                        if state.isSelectedWithoutEdit {
                            state.isSelectedWithoutEdit = false
                            _hideMenu()
                        } else {
                            if isFirstResponder {
                                let oldRange = _trackingRange
                                _updateTextRangeByTrackingCaret()
                                if oldRange == _trackingRange {
                                    if state.isShowingMenu {
                                        _hideMenu()
                                    } else {
                                        _showMenu()
                                    }
                                } else {
                                    _hideMenu()
                                }
                            } else {
                                _hideMenu()
                                if state.isClearsOnInsertionOnce {
                                    state.isClearsOnInsertionOnce = false
                                    _selectedTextRange = TextRange(range: NSRange(location: 0, length: _innerText.length))
                                    _setSelectedRange(_selectedTextRange.nsRange)
                                } else {
                                    _updateTextRangeByTrackingCaret()
                                }
                                perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0)
                            }
                        }
                    }
                }
            }
            
            if (_trackingRange != nil) && (_trackingRange != _selectedTextRange || state.isTrackingPreviousSelect) {
                if _trackingRange != _selectedTextRange {
                    _inputDelegate?.selectionWillChange(self)
                    if let range = _trackingRange {
                        _selectedTextRange = range
                    }
                    _inputDelegate?.selectionDidChange(self)
                    _updateAttributesHolder()
                    _updateOuterProperties()
                }
                
                if state.trackingGrabber == .none && !state.isTrackingPreviousSelect {
                    _scrollRangeToVisible(_selectedTextRange)
                }
            }
            
            _endTouchTracking()
        }
        if !state.isSwallowTouch {
            super.touchesEnded(touches, with: event)
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        _endTouchTracking()
        _hideMenu()
        
        if !state.isSwallowTouch {
            super.touchesCancelled(touches, with: event)
        }
    }
    
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake, isAllowsUndoAndRedo {
            if !TextUtilities.isAppExtension {
                _showUndoRedoAlert()
            }
        } else {
            super.motionEnded(motion, with: event)
        }
    }
    
    @discardableResult
    override open func becomeFirstResponder() -> Bool {
        let isFirstResponder: Bool = self.isFirstResponder
        if isFirstResponder {
            return true
        }
        let shouldDetectData = _shouldDetectText()
        let become: Bool = super.becomeFirstResponder()
        if !isFirstResponder && become {
            _endTouchTracking()
            _hideMenu()
            
            state.isSelectedWithoutEdit = false
            if shouldDetectData != _shouldDetectText() {
                _update()
            }
            _updateIfNeeded()
            _updateSelectionView()
            perform(#selector(_scrollSelectedRangeToVisible), with: nil, afterDelay: 0)
            
            _outerDelegate?.textViewDidBeginEditing?(self)
                
            NotificationCenter.default.post(name: Self.textViewTextDidBeginEditingNotification, object: self)
        }
        return become
    }
    
    @discardableResult
    override open func resignFirstResponder() -> Bool {
        let isFirstResponder: Bool = self.isFirstResponder
        if !isFirstResponder {
            return true
        }
        let resign: Bool = super.resignFirstResponder()
        if resign {
            if _markedTextRange != nil {
                _markedTextRange = nil
                _parseText()
                _setText(_innerText.plainText(for: NSRange(location: 0, length: _innerText.length)))
            }
            state.isSelectedWithoutEdit = false
            if _shouldDetectText() {
                _update()
            }
            _endTouchTracking()
            _hideMenu()
            _updateIfNeeded()
            _updateSelectionView()
            _restoreInsets(animated: true)
            
            _outerDelegate?.textViewDidEndEditing?(self)
            
            NotificationCenter.default.post(name: Self.textViewTextDidEndEditingNotification, object: self)
        }
        return resign
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        // Default menu actions list:
        //
        // cut:                                   剪切
        // copy:                                  拷贝
        // paste:                                 粘贴
        // select:                                选择
        // delete:                                删除
        // selectAll:                             全选
        // _promptForReplace:                     替换...
        // _transliterateChinese:                 简⇄繁
        // _insertDrawing:                        插入绘图
        // captureTextFromCamera:                 从相机中捕获文本
        // _showTextFormattingOptions:            显示文本格式选项
        // _findSelected:                         查找所选
        // _showTextStyleOptions:                 𝐁𝐼𝐔
        // _define:                               定义
        // _translate:                            翻译
        // _addShortcut:                          添加捷径
        // _accessibilitySpeak:                   说话
        // _accessibilitySpeakLanguageSelection:  语言选择
        // _accessibilityPauseSpeaking:           暂停说话
        // makeTextWritingDirectionRightToLeft:   使文字书写方向从右到左
        // makeTextWritingDirectionLeftToRight:   使文字书写方向从左到右
        // _share:                                分享
        //
        //
        // Default attribute modifier list:
        //
        // toggleBoldface:                        切换粗体
        // toggleItalics:                         切换斜体
        // toggleUnderline:                       切换下划线
        // increaseSize:                          增加字号
        // decreaseSize:                          缩小字号
        
        if _selectedTextRange.nsRange.length == 0 {
            if action == #selector(select(_:)) || action == #selector(selectAll(_:)) {
                return _innerText.length > 0
            }
            if action == #selector(paste(_:)) {
                return _isPasteboardContainsValidValue()
            }
        } else {
            if action == #selector(cut(_:)) {
                return isFirstResponder && isEditable
            }
            if action == #selector(copy(_:)) {
                return true
            }
            if action == #selector(selectAll(_:)) {
                return _selectedTextRange.nsRange.length < _innerText.length
            }
            if action == #selector(paste(_:)) {
                return isFirstResponder && isEditable && _isPasteboardContainsValidValue()
            }
            let selString = NSStringFromSelector(action)
            if selString.hasSuffix("define:"), selString.hasPrefix("_") {
                return _getRootViewController() != nil
            }
        }
        if #available(iOS 15.0, *) {
            if action == #selector(captureTextFromCamera(_:)) {
                return true
            }
        }
        return false
    }
    
    override open func reloadInputViews() {
        super.reloadInputViews()
        if _markedTextRange != nil {
            unmarkText()
        }
    }
    
    // MARK: - Override NSObject(UIResponderStandardEditActions)
    
    override open func cut(_ sender: Any?) {
        _endTouchTracking()
        if _selectedTextRange.nsRange.length == 0 {
            return
        }
        
        _copySelectedTextToPasteboard()
        _saveToUndoStack()
        _resetRedoStack()
        replace(_selectedTextRange, withText: "")
    }
    
    override open func copy(_ sender: Any?) {
        _endTouchTracking()
        _copySelectedTextToPasteboard()
    }
    
    override open func paste(_ sender: Any?) {
        _endTouchTracking()
        let pasteboard = UIPasteboard.general
        var attributedString: NSAttributedString?
        
        if isAllowsPasteAttributedString {
            attributedString = pasteboard.attributedString
            if (attributedString?.length ?? 0) == 0 {
                attributedString = nil
            }
        }
        if attributedString == nil, isAllowsPasteImage {
            var image: UIImage?
            
            let scale: CGFloat = TextUtilities.screenScale
            #if canImport(SDWebImage)
            if let data = pasteboard.gifData {
                image = SDAnimatedImage(data: data, scale: scale)
            }
            if image == nil, let data = pasteboard.pngData {
                image = UIImage(data: data, scale: scale)
            }
            if image == nil, let data = pasteboard.jpgData {
                image = UIImage(data: data, scale: scale)
            }
            #endif
            
            if image == nil {
                image = pasteboard.image
            }
            
            if image == nil, let data = pasteboard.imageData {
                image = UIImage(data: data, scale: scale)
            }
            
            if let tmpImage = image, tmpImage.size.width > 1, tmpImage.size.height > 1 {
                var content: Any = tmpImage
                
                #if canImport(SDWebImage)
                if let tmpImage = tmpImage as? SDAnimatedImage {
                    let frameCount = tmpImage.animatedImageFrameCount
                    if frameCount > 1 {
                        let imageView = SDAnimatedImageView()
                        imageView.image = tmpImage
                        imageView.frame = CGRect(x: 0, y: 0, width: tmpImage.size.width, height: tmpImage.size.height)
                        content = imageView
                    }
                }
                #endif
                
                if tmpImage.images?.count ?? 0 > 1 {
                    let imgView = UIImageView()
                    imgView.image = image
                    imgView.frame = CGRect(x: 0, y: 0, width: tmpImage.size.width, height: tmpImage.size.height)
                    content = imgView
                }
                
                let attachmentText = NSAttributedString.attachmentString(
                    content: content,
                    contentMode: .scaleToFill,
                    width: tmpImage.size.width,
                    ascent: tmpImage.size.height,
                    descent: 0
                )
                
                if let attrs = _typingAttributesHolder.attributes {
                    attachmentText.addAttributes(attrs, range: NSRange(location: 0, length: attachmentText.length))
                }
                attributedString = attachmentText
            }
        }
        if let attributed = attributedString {
            let endPosition: Int = _selectedTextRange.start.offset + attributed.length
            guard let text = _innerText.mutableCopy() as? NSMutableAttributedString else {
                return
            }
            text.replaceCharacters(in: _selectedTextRange.nsRange, with: attributed)
            self.attributedText = text
            let pos = _correctedTextPosition(TextPosition(offset: endPosition))
            let range = _innerLayout?.textRange(byExtending: pos)
            if let range = _correctedTextRange(range) {
                selectedRange = NSRange(location: range.end.offset, length: 0)
            }
        } else {
            let string = pasteboard.string
            if let text = string, !text.isEmpty {
                _saveToUndoStack()
                _resetRedoStack()
                replace(_selectedTextRange, withText: text)
            }
        }
    }
    
    override open func select(_ sender: Any?) {
        _endTouchTracking()
        
        if _selectedTextRange.nsRange.length > 0 || _innerText.length == 0 {
            return
        }
        
        if let newRange = _getClosestTokenRange(at: _selectedTextRange.start), newRange.nsRange.length > 0 {
            _inputDelegate?.selectionWillChange(self)
            _selectedTextRange = newRange
            _inputDelegate?.selectionDidChange(self)
        }
        
        _updateIfNeeded()
        _updateOuterProperties()
        _updateSelectionView()
        _hideMenu()
        _showMenu()
    }
    
    override open func selectAll(_ sender: Any?) {
        _trackingRange = nil
        _inputDelegate?.selectionWillChange(self)
        _selectedTextRange = TextRange(range: NSRange(location: 0, length: _innerText.length))
        _inputDelegate?.selectionDidChange(self)
        
        _updateIfNeeded()
        _updateOuterProperties()
        _updateSelectionView()
        _hideMenu()
        _showMenu()
    }
    
    private func _define(_ sender: Any?) {
        _hideMenu()
        
        guard let string = _innerText.plainText(for: _selectedTextRange.nsRange), !string.isEmpty else {
            return
        }
        let resign: Bool = resignFirstResponder()
        if !resign {
            return
        }
        
        let ref = UIReferenceLibraryViewController(term: string)
        ref.view.backgroundColor = UIColor.white
        _getRootViewController()?.present(ref, animated: true) {}
    }
   
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        TextEffectWindow.shared?.hide(selectionDot: _selectionView)
        
        _outerDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        _outerDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _outerDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillEndDragging(_
                                          scrollView: UIScrollView,
                                          withVelocity velocity: CGPoint,
                                          targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        _outerDelegate?.scrollViewWillEndDragging?(
            scrollView,
            withVelocity: velocity,
            targetContentOffset: targetContentOffset
        )
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            TextEffectWindow.shared?.show(selectionDot: _selectionView)
        }
        
        _outerDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        _outerDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        TextEffectWindow.shared?.show(selectionDot: _selectionView)
        
        _outerDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _outerDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return _outerDelegate?.viewForZooming?(in: scrollView)
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        _outerDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        _outerDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }
    
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return _outerDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }
    
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        _outerDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
    
    // MARK: - TextKeyboardObserver
    
    public func keyboardChanged(with transition: TextKeyboardTransition) {
        _keyboardChanged()
    }
    
    // MARK: - UIKeyInput
    
    /// 插入文本
    public func insertText(_ text: String) {
        if text.isEmpty {
            return
        }
        if _lastTypeRange != _selectedTextRange.nsRange {
            _saveToUndoStack()
            _resetRedoStack()
        }
        replace(_selectedTextRange, withText: text)
    }
    
    /// 回删
    public func deleteBackward() {
        _updateIfNeeded()
        var range: NSRange = _selectedTextRange.nsRange
        if range.location == 0, range.length == 0 {
            return
        }
        state.isTypingAttributesOnce = false
        
        // test if there's 'TextBinding' before the caret
        if !state.isDeleteConfirm, range.length == 0, range.location > 0 {
            var effectiveRange = NSRange(location: 0, length: 0)
            let binding = _innerText.attribute(
                TextAttribute.textBinding,
                at: range.location - 1,
                longestEffectiveRange: &effectiveRange,
                in: NSRange(location: 0, length: _innerText.length)
            ) as? TextBinding
            if binding != nil, binding?.isDeleteConfirm != nil {
                state.isDeleteConfirm = true
                _inputDelegate?.selectionWillChange(self)
                _selectedTextRange = TextRange(range: effectiveRange)
                if let fixedRange = _correctedTextRange(_selectedTextRange) {
                    _selectedTextRange = fixedRange
                }
                _inputDelegate?.selectionDidChange(self)
                
                _updateOuterProperties()
                _updateSelectionView()
                return
            }
        }
        
        state.isDeleteConfirm = false
        if range.length == 0 {
            let extendRange = _innerLayout?.textRange(
                byExtending: _selectedTextRange.end,
                in: .left,
                offset: 1
            )
            if let extendRange = extendRange, _isTextRangeValid(extendRange) {
                range = extendRange.nsRange
            }
        }
        if _lastTypeRange != _selectedTextRange.nsRange {
            _saveToUndoStack()
            _resetRedoStack()
        }
        replace(TextRange(range: range), withText: "")
    }
    
    // MARK: - UITextInput
    
    /// Replace current markedText with the new markedText
    ///
    /// - Parameters:
    ///     - markedText: New marked text.
    ///     - selectedRange: The range from the '_markedTextRange'
    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        let markedText = markedText ?? ""
        _updateIfNeeded()
        _endTouchTracking()
        _hideMenu()
        
        if let delegate = _outerDelegate {
            let range = _markedTextRange
            let someRange = range?.nsRange ?? NSRange(location: _selectedTextRange.end.offset, length: 0)
            if let should = delegate.textView?(
                self,
                shouldChangeTextIn: someRange,
                replacementText: markedText
            ), should == false {
                return
            }
        }
        
        if _lastTypeRange != _selectedTextRange.nsRange {
            _saveToUndoStack()
            _resetRedoStack()
        }
        
        var needApplyTypingAttribute = false
        if _innerText.length > 0 && _markedTextRange != nil {
            _updateAttributesHolder()
        } else {
            needApplyTypingAttribute = true
        }
        
        if _selectedTextRange.nsRange.length > 0 {
            replace(_selectedTextRange, withText: "")
        }
        
        _inputDelegate?.textWillChange(self)
        _inputDelegate?.selectionWillChange(self)
        
        if _markedTextRange == nil {
            _markedTextRange = TextRange(
                range: NSRange(location: _selectedTextRange.end.offset, length: markedText.length)
            )
            let subRange = NSRange(location: _selectedTextRange.end.offset, length: 0)
            _innerText.replaceCharacters(in: subRange, with: markedText)
            _selectedTextRange = TextRange(
                range: NSRange(
                    location: _selectedTextRange.start.offset + selectedRange.location,
                    length: selectedRange.length
                )
            )
        } else {
            if let fixedMarked = _correctedTextRange(_markedTextRange) {
                _markedTextRange = fixedMarked
            }
            guard let marked = _markedTextRange else {
                return
            }
            _innerText.replaceCharacters(in: marked.nsRange, with: markedText)
            _markedTextRange = TextRange(
                range: NSRange(location: marked.start.offset, length: markedText.length)
            )
            _selectedTextRange = TextRange(
                range: NSRange(
                    location: marked.start.offset + selectedRange.location,
                    length: selectedRange.length
                )
            )
        }
        
        if let selected = _correctedTextRange(_selectedTextRange) {
            _selectedTextRange = selected
        }
        guard var marked = _markedTextRange else {
            return
        }
        if let fixedMarked = _correctedTextRange(marked) {
            marked = fixedMarked
        }
        _markedTextRange = marked
        if marked.nsRange.length == 0 {
            _markedTextRange = nil
        } else {
            if needApplyTypingAttribute {
                _innerText.setAttributes(_typingAttributes, range: marked.nsRange)
            }
            _innerText.removeDiscontinuousAttributes(in: marked.nsRange)
        }
        
        _inputDelegate?.selectionDidChange(self)
        _inputDelegate?.textDidChange(self)
        
        _updateOuterProperties()
        _updateLayout()
        _updateSelectionView()
        _scrollRangeToVisible(_selectedTextRange)
        
        _outerDelegate?.textViewDidChange?(self)
        
        NotificationCenter.default.post(name: Self.textViewTextDidChangeNotification, object: self)
        
        _lastTypeRange = _selectedTextRange.nsRange
    }
    
    /// 文本取消 mark
    public func unmarkText() {
        _markedTextRange = nil
        _endTouchTracking()
        _hideMenu()
        if _parseText() {
            state.isNeedsUpdate = true
        }
        
        _updateIfNeeded()
        _updateOuterProperties()
        _updateSelectionView()
        _scrollRangeToVisible(_selectedTextRange)
    }
    
    /// 在指定范围内替换给定的文本
    public func replace(_ range: UITextRange, withText text: String) {
        guard var range = range as? TextRange else {
            return
        }
        let newText = text
        
        if range.nsRange.length == 0, newText.isEmpty {
            return
        }
        if let fixedRange = _correctedTextRange(range) {
            range = fixedRange
        }
        
        if let delegate = _outerDelegate {
            if let should = delegate.textView?(
                self,
                shouldChangeTextIn: range.nsRange,
                replacementText: newText
            ), should == false {
                return
            }
        }
        
        var useInnerAttributes = false
        if _innerText.length > 0 {
            if range.start.offset == 0, range.end.offset == _innerText.length {
                if newText.isEmpty {
                    var attrs = _innerText.attributes(at: 0)
                    for key in NSMutableAttributedString.allDiscontinuousAttributeKeys() {
                        attrs?.removeValue(forKey: key)
                    }
                    _typingAttributesHolder.setAttributes([:], range: _typingAttributesHolder.rangeOfAll)
                    if let attrs {
                        for attr in attrs {
                            _typingAttributesHolder.setAttribute(attr.key, value: attr.value)
                        }
                    }
                }
            }
        } else {
            // no text
            useInnerAttributes = true
        }
        var applyTypingAttributes = false
        if state.isTypingAttributesOnce {
            state.isTypingAttributesOnce = false
            if !useInnerAttributes {
                if range.nsRange.length == 0, !newText.isEmpty {
                    applyTypingAttributes = true
                }
            }
        }
        
        state.isSelectedWithoutEdit = false
        state.isDeleteConfirm = false
        _endTouchTracking()
        _hideMenu()
        
        _replace(range, withText: newText, notifyToDelegate: true)
        if useInnerAttributes {
            _innerText.setAttributes([:], range: _innerText.rangeOfAll)
            if let attrs = _typingAttributesHolder.attributes {
                for attr in attrs {
                    _innerText.setAttribute(attr.key, value: attr.value)
                }
            }
        } else if applyTypingAttributes {
            let newRange = NSRange(location: range.nsRange.location, length: newText.length)
            for (key, obj) in _typingAttributesHolder.attributes ?? [:] {
                _innerText.setAttribute(key, value: obj, range: newRange)
            }
        }
        _parseText()
        _updateOuterProperties()
        _update()
        
        if isFirstResponder {
            _scrollRangeToVisible(_selectedTextRange)
        }
        
        _outerDelegate?.textViewDidChange?(self)
        
        NotificationCenter.default.post(name: Self.textViewTextDidChangeNotification, object: self)
        
        _lastTypeRange = _selectedTextRange.nsRange
    }
    
    /// 设置基础的书写方向
    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        guard var range = range as? TextRange else {
            return
        }
        if let fixedRange = _correctedTextRange(range) {
            range = fixedRange
        }
        _innerText.setBaseWritingDirection(writingDirection, range: range.nsRange)
        _commitUpdate()
    }
    
    /// 获取给定范围的文本
    public func text(in range: UITextRange) -> String? {
        guard var range = range as? TextRange else {
            return ""
        }
        guard let fixedRange = _correctedTextRange(range) else {
            return ""
        }
        range = fixedRange
        return _innerText.attributedSubstring(from: range.nsRange).string
    }
    
    /// 获取基础书写方向
    public func baseWritingDirection(
        for position: UITextPosition,
        in direction: UITextStorageDirection
    ) -> NSWritingDirection {
        guard var position = position as? TextPosition else {
            return .natural
        }
        _updateIfNeeded()
        
        guard let fixedPosition = _correctedTextPosition(position) else {
            return .natural
        }
        position = fixedPosition
        
        if _innerText.length == 0 {
            return .natural
        }
        var idx = position.offset
        if idx == _innerText.length {
            idx -= 1
        }
        
        guard let attrs = _innerText.attributes(at: idx) else {
            return .natural
        }
        // swiftlint:disable:next force_cast
        let paragraphStyle = attrs[NSAttributedString.Key.paragraphStyle] as! CTParagraphStyle?
        if let paragraphStyle {
            let baseWritingDirection = UnsafeMutablePointer<CTWritingDirection>.allocate(capacity: 1)
            defer {
                baseWritingDirection.deallocate()
            }
            if CTParagraphStyleGetValueForSpecifier(
                paragraphStyle,
                CTParagraphStyleSpecifier.baseWritingDirection,
                MemoryLayout<CTWritingDirection>.size,
                baseWritingDirection
            ) {
                return .init(rawValue: Int(baseWritingDirection.pointee.rawValue)) ?? .natural
            }
        }
        
        return .natural
    }
    
    /// 根据偏移量获取偏移后的文档位置
    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard offset != 0, let position = position as? TextPosition else {
            return position
        }
        
        let location = position.offset
        var newLocation: Int = location + offset
        if newLocation < 0 || newLocation > _innerText.length {
            return nil
        }
        
        if newLocation != 0 && newLocation != _innerText.length {
            // fix emoji
            _updateIfNeeded()
            let extendRange: TextRange? = _innerLayout?.textRange(byExtending: TextPosition(offset: newLocation))
            if extendRange?.nsRange.length ?? 0 > 0 {
                if offset < 0 {
                    newLocation = extendRange?.start.offset ?? 0
                } else {
                    newLocation = extendRange?.end.offset ?? 0
                }
            }
        }
        
        let textPosition = TextPosition(offset: newLocation)
        return _correctedTextPosition(textPosition)
    }
    
    /// 根据书写方向和偏移量获取偏移后的文档位置
    public func position(
        from position: UITextPosition,
        in direction: UITextLayoutDirection,
        offset: Int
    ) -> UITextPosition? {
        _updateIfNeeded()
        let range: TextRange? = _innerLayout?.textRange(
            byExtending: position as? TextPosition,
            in: direction,
            offset: offset
        )
        
        var forward: Bool
        if _innerContainer.isVerticalForm {
            forward = direction == .left || direction == .down
        } else {
            forward = direction == .down || direction == .right
        }
        if !forward, offset < 0 {
            forward = !forward
        }
        
        var newPosition: TextPosition? = forward ? range?.end : range?.start
        if let offset = newPosition?.offset {
            if offset > _innerText.length {
                newPosition = TextPosition(offset: _innerText.length, affinity: .backward)
            }
        }
        return _correctedTextPosition(newPosition)
    }
    
    /// 获取文本范围
    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let start = fromPosition as? TextPosition, let end = toPosition as? TextPosition else {
            return nil
        }
        return TextRange(start: start, end: end)
    }
    
    /// 对比两个文本位置
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        return (position as? TextPosition)?.compare(other as? TextPosition) ?? .orderedAscending
    }
    
    /// 获取两个文本位置的偏移量
    public func offset(from: UITextPosition, to: UITextPosition) -> Int {
        guard let from = from as? TextPosition, let to = to as? TextPosition else {
            return 0
        }
        return to.offset - from.offset
    }
    
    /// 根据文本范围和最远方向获取文本位置
    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        guard let range = range as? TextRange else {
            return nil
        }
        if direction == .left || direction == .up {
            return TextPosition(offset: range.nsRange.location)
        } else {
            return TextPosition(offset: range.nsRange.location + range.nsRange.length, affinity: .backward)
        }
    }
    
    /// 获取字符范围
    public func characterRange(
        byExtending position: UITextPosition,
        in direction: UITextLayoutDirection
    ) -> UITextRange? {
        _updateIfNeeded()
        let range = _innerLayout?.textRange(byExtending: position as? TextPosition, in: direction, offset: 1)
        return _correctedTextRange(range)
    }
    
    /// 根据 point 获取最接近的文本位置
    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        let newPoint = _convertPoint(toLayout: point)
        _updateIfNeeded()
        let position = _innerLayout?.closestPosition(to: newPoint)
        return _correctedTextPosition(position)
    }
    
    /// 根据 point 和 range 获取最接近的文本位置
    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        guard var range = range as? TextRange else {
            return nil
        }
        
        guard var pos = closestPosition(to: point) as? TextPosition else {
            return nil
        }
        
        if let fixedRange = _correctedTextRange(range) {
            range = fixedRange
        }
        if pos.compare(range.start) == .orderedAscending {
            pos = range.start
        } else if pos.compare(range.end) == .orderedDescending {
            pos = range.end
        }
        return pos
    }
    
    /// 根据 point 获取字符的文本范围
    public func characterRange(at point: CGPoint) -> UITextRange? {
        var newPosint = point
        _updateIfNeeded()
        newPosint = _convertPoint(toLayout: newPosint)
        let range = _innerLayout?.closestTextRange(at: newPosint)
        return _correctedTextRange(range)
    }
    
    /// 根据 range 获取第一个 CGRect
    public func firstRect(for range: UITextRange) -> CGRect {
        _updateIfNeeded()
        guard let range = range as? TextRange else {
            return .zero
        }
        guard let rect = _innerLayout?.firstRect(for: range), !rect.isNull else {
            return .zero
        }
        return _convertRect(fromLayout: rect)
    }
    
    /// 根据文本位置获取相应的 CGRect
    public func caretRect(for position: UITextPosition) -> CGRect {
        _updateIfNeeded()
        guard let innerLayout = self._innerLayout, let position = position as? TextPosition else {
            return .zero
        }
        var caretRect: CGRect = innerLayout.caretRect(for: position)
        if !caretRect.isNull {
            caretRect = _convertRect(fromLayout: caretRect)
            caretRect = caretRect.standardized
            if isVerticalForm {
                if caretRect.size.height == 0 {
                    caretRect.size.height = 2
                    caretRect.origin.y -= 2 * 0.5
                }
                if caretRect.origin.y < 0 {
                    caretRect.origin.y = 0
                } else if caretRect.origin.y + caretRect.size.height > bounds.size.height {
                    caretRect.origin.y = bounds.size.height - caretRect.size.height
                }
            } else {
                if caretRect.size.width == 0 {
                    caretRect.size.width = 2
                    caretRect.origin.x -= 2 * 0.5
                }
                if caretRect.origin.x < 0 {
                    caretRect.origin.x = 0
                } else if caretRect.origin.x + caretRect.size.width > bounds.size.width {
                    caretRect.origin.x = bounds.size.width - caretRect.size.width
                }
            }
            return caretRect.roundFlattened()
        }
        return .zero
    }
    
    /// 根据文本范围获取相应的 [UITextSelectionRect]
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        _updateIfNeeded()
        guard let range = range as? TextRange else {
            return []
        }
        let rects = _innerLayout?.selectionRects(for: range)
        for rect in rects ?? [] {
            rect.rect = _convertRect(fromLayout: rect.rect)
        }
        return rects ?? []
    }
    
    // MARK: - UITextInput optional
    /// 根据文本位置和亲和性获取文本样式
    public func textStyling(
        at position: UITextPosition,
        in direction: UITextStorageDirection
    ) -> [NSAttributedString.Key: Any]? {
        guard let position = position as? TextPosition else {
            return nil
        }
        if _innerText.length == 0 {
            return _typingAttributesHolder.attributes
        }
        var attrs: [NSAttributedString.Key: Any]?
        if position.offset >= 0, position.offset <= _innerText.length {
            var ofs = position.offset
            if position.offset == _innerText.length || direction == .backward {
                ofs -= 1
            }
            attrs = _innerText.attributes(at: ofs, effectiveRange: nil)
        }
        return attrs
    }
    
    /// 根据文本范围和偏移量获取文本位置
    public func position(within range: UITextRange, atCharacterOffset offset: Int) -> UITextPosition? {
        guard let range = range as? TextRange else {
            return nil
        }
        if offset < range.start.offset || offset > range.end.offset {
            return nil
        }
        if offset == range.start.offset {
            return range.start
        } else if offset == range.end.offset {
            return range.end
        } else {
            return TextPosition(offset: offset)
        }
    }
    
    /// 根据文本为孩子和 range 获取相应的字符偏移量
    public func characterOffset(of position: UITextPosition, within range: UITextRange) -> Int {
        guard let position = position as? TextPosition else {
            return NSNotFound
        }
        return position.offset
    }
    
    deinit {
        TextKeyboardManager.default.remove(observer: self)
        
        TextEffectWindow.shared?.hide(selectionDot: _selectionView)
        TextEffectWindow.shared?.hide(_magnifierCaret)
        
        TextDebugOption.remove(self)
        
        _longPressTimer?.invalidate()
        _autoScrollTimer?.invalidate()
        _selectionDotFixTimer?.invalidate()
    }
}
// swiftlint:enable type_body_length

extension AttributedTextView {
    // MARK: - Overrice NSObject(NSKeyValueObservingCustomization)
    
    private static let automaticallyNotifiesObserversKeys: Set<AnyHashable> = {
        var keys = Set<AnyHashable>([
            "text",
            "font",
            "textColor",
            "textAlignment",
            "dataDetectorTypes",
            "linkTextAttributes",
            "highlightTextAttributes",
            "textParser",
            "attributedText",
            "textVerticalAlignment",
            "textContainerInset",
            "exclusionPaths",
            "isVerticalForm",
            "linePositionModifier",
            "selectedRange",
            "typingAttributes"
        ])
        return keys
    }()
}

extension AttributedTextView {
    // MARK: - Undo & Redo
    
    private static let localizedUndoStringsDic = [
        "ar": ["إلغاء", "إعادة", "إعادة الكتابة", "تراجع", "تراجع عن الكتابة"],
        "ca": ["Cancel·lar", "Refer", "Refer l’escriptura", "Desfer", "Desfer l’escriptura"],
        "cs": ["Zrušit", "Opakovat akci", "Opakovat akci Psát", "Odvolat akci", "Odvolat akci Psát"],
        "da": ["Annuller", "Gentag", "Gentag Indtastning", "Fortryd", "Fortryd Indtastning"],
        "de": ["Abbrechen", "Wiederholen", "Eingabe wiederholen", "Widerrufen", "Eingabe widerrufen"],
        "el": ["Ακύρωση", "Επανάληψη", "Επανάληψη πληκτρολόγησης", "Αναίρεση", "Αναίρεση πληκτρολόγησης"],
        "en": ["Cancel", "Redo", "Redo Typing", "Undo", "Undo Typing"],
        "es": ["Cancelar", "Rehacer", "Rehacer escritura", "Deshacer", "Deshacer escritura"],
        "es_MX": ["Cancelar", "Rehacer", "Rehacer escritura", "Deshacer", "Deshacer escritura"],
        "fi": ["Kumoa", "Tee sittenkin", "Kirjoita sittenkin", "Peru", "Peru kirjoitus"],
        "fr": ["Annuler", "Rétablir", "Rétablir la saisie", "Annuler", "Annuler la saisie"],
        "he": ["ביטול", "חזור על הפעולה האחרונה", "חזור על הקלדה", "בטל", "בטל הקלדה"],
        "hr": ["Odustani", "Ponovi", "Ponovno upiši", "Poništi", "Poništi upisivanje"],
        "hu": ["Mégsem", "Ismétlés", "Gépelés ismétlése", "Visszavonás", "Gépelés visszavonása"],
        "id": ["Batalkan", "Ulang", "Ulang Pengetikan", "Kembalikan", "Batalkan Pengetikan"],
        "it": ["Annulla", "Ripristina originale", "Ripristina Inserimento", "Annulla", "Annulla Inserimento"],
        "ja": ["キャンセル", "やり直す", "やり直す - 入力", "取り消す", "取り消す - 入力"],
        "ko": ["취소", "실행 복귀", "입력 복귀", "실행 취소", "입력 실행 취소"],
        "ms": ["Batal", "Buat semula", "Ulang Penaipan", "Buat asal", "Buat asal Penaipan"],
        "nb": ["Avbryt", "Utfør likevel", "Utfør skriving likevel", "Angre", "Angre skriving"],
        "nl": ["Annuleer", "Opnieuw", "Opnieuw typen", "Herstel", "Herstel typen"],
        "pl": ["Anuluj", "Przywróć", "Przywróć Wpisz", "Cofnij", "Cofnij Wpisz"],
        "pt": ["Cancelar", "Refazer", "Refazer Digitação", "Desfazer", "Desfazer Digitação"],
        "pt_PT": ["Cancelar", "Refazer", "Refazer digitar", "Desfazer", "Desfazer digitar"],
        "ro": ["Renunță", "Refă", "Refă tastare", "Anulează", "Anulează tastare"],
        "ru": ["Отменить", "Повторить", "Повторить набор на клавиатуре", "Отменить", "Отменить набор на клавиатуре"],
        "sk": ["Zrušiť", "Obnoviť", "Obnoviť písanie", "Odvolať", "Odvolať písanie"],
        "sv": ["Avbryt", "Gör om", "Gör om skriven text", "Ångra", "Ångra skriven text"],
        "th": ["ยกเลิก", "ทำกลับมาใหม่", "ป้อนกลับมาใหม่", "เลิกทำ", "เลิกป้อน"],
        "tr": ["Vazgeç", "Yinele", "Yazmayı Yinele", "Geri Al", "Yazmayı Geri Al"],
        "uk": ["Скасувати", "Повторити", "Повторити введення", "Відмінити", "Відмінити введення"],
        "vi": ["Hủy", "Làm lại", "Làm lại thao tác Nhập", "Hoàn tác", "Hoàn tác thao tác Nhập"],
        "zh": ["取消", "重做", "重做键入", "撤销", "撤销键入"],
        "zh_CN": ["取消", "重做", "重做键入", "撤销", "撤销键入"],
        "zh_HK": ["取消", "重做", "重做輸入", "還原", "還原輸入"],
        "zh_TW": ["取消", "重做", "重做輸入", "還原", "還原輸入"]
    ]
    
    private static let localizedUndoStrings: [String] = {
        var strings: [String] = []
        
        var preferred = Bundle.main.preferredLocalizations.first ?? ""
        if preferred.isEmpty {
            preferred = "English"
        }
        // 典型的地域标识符
        var canonical = Locale.canonicalIdentifier(from: preferred)
        if canonical.isEmpty {
            canonical = "en"
        }
        strings = localizedUndoStringsDic[canonical] ?? []
        // swiftlint:disable:next legacy_objc_type
        if strings.isEmpty, (canonical as NSString).range(of: "_").location != NSNotFound {
            if let prefix = canonical.components(separatedBy: "_").first, !prefix.isEmpty {
                strings = localizedUndoStringsDic[prefix] ?? []
            }
        }
        if strings.isEmpty {
            strings = localizedUndoStringsDic["en"] ?? []
        }
        
        return strings
    }()
    
    /// Returns the default font for text view (same as CoreText).
    private static let _defaultFont = UIFont.systemFont(ofSize: 12)
    
    /// Returns the default tint color for text view (used for caret and select range background).
    private static let _defaultTintColor: UIColor = .systemBlue
    
    /// Returns the default placeholder color for text view (same as UITextField).
    private static let _defaultPlaceholderColor = UIColor(red: 0, green: 0, blue: 25/255.0, alpha: 44/255.0)
 
    private func _localizedUndoStrings() -> [String] {
        return AttributedTextView.localizedUndoStrings
    }
}
