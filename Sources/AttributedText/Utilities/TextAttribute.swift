//
//  TextAttribute.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreText

// swiftlint:disable file_length
/// 文本中定义的点击/长按操作的回调
///
/// Parameters:
/// - containerView: 文本容器视图(例如 Label/TextView)
/// - text: 整个文本
/// - range: `text` 中的文本范围 (如果没有范围, 则为 nil)
/// - rect: `containerView` 中的文本的 frame (如果没有文本, 则为 nil)
///
public typealias TextAction = (UIView, NSAttributedString, NSRange, CGRect) -> Void

// MARK: - Enum Define

/// The attribute type
public enum TextAttributeType: Int {
    case none = 0
    /// UIKit attributes, such as UILabel/UITextField/drawInRect.
    case uiKit = 1      // (1 << 0)
    /// CoreText attributes, used by CoreText.
    case coreText = 2   // (1 << 1)
    /// Text attributes, used by AttributedText.
    case attributedText = 4     // (1 << 2)
}

/// Line style in Text (similar to NSUnderlineStyle).
public enum TextLineStyle: Int {
    
    // basic style (bitmask:0xFF)
    /// (        ) Do not draw a line (Default).
    case none = 0x00
    /// (──────) Draw a single line.
    case single = 0x01
    /// (━━━━━━━) Draw a thick line.
    case thick = 0x02
    /// (══════) Draw a double line.
    case double = 0x09
    
    // style pattern (bitmask:0xF00)
    /// (────────) Draw a solid line (Default).
    /// (‑ ‑ ‑ ‑ ‑ ‑) Draw a line of dots.
    case patternDot = 0x100
    /// (— — — —) Draw a line of dashes.
    case patternDash = 0x200
    /// (— ‑ — ‑ — ‑) Draw a line of alternating dashes and dots.
    case patternDashDot = 0x300
    /// (— ‑ ‑ — ‑ ‑) Draw a line of alternating dashes and two dots.
    case patternDashDotDot = 0x400
    /// (••••••••••••) Draw a line of small circle dots.
    case patternCircleDot = 0x900
}

/// Text vertical alignment.
public enum TextVerticalAlignment: Int {
    /// Top alignment.
    case top = 0
    /// Center alignment.
    case center = 1
    /// Bottom alignment.
    case bottom = 2
}

/// The direction define in Text.
public enum TextDirection: Int {
    
    case none = 0
    case top = 1        // 1 << 0
    case right = 2      // 1 << 1
    case bottom = 4     // 1 << 2
    case left = 8       // 1 << 3
}

/// The trunction type, tells the truncation engine which type of truncation is being requested.
public enum TextTruncationType: Int {
    /// No truncate.
    case none = 0
    /// Truncate at the beginning of the line, leaving the end portion visible.
    case start = 1
    /// Truncate at the end of the line, leaving the start portion visible.
    case end = 2
    /// Truncate in the middle of the line, leaving both the start and the end portions visible.
    case middle = 3
}

/// TextBackedString objects are used by the NSAttributedString class cluster
/// as the values for text backed string attributes (stored in the attributed
/// string under the key named TextAttribute.textBackedString).
///
/// It may used for copy/paste plain text from attributed string.
///
/// Example:
///
///     If :) is replace by a custom emoji (such as😊), the backed string can be set to ":)".
public class TextBackedString: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// 字符串
    public var string: String?
    
    /// 构造方法
    public override init() {
        super.init()
    }
    
    /// backed string
    public convenience init(string: String) {
        self.init()
        
        self.string = string
    }
    
    // MARK: - NSCoding
    /// Decode
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.string = aDecoder.decodeObject(forKey: "string") as? String
    }
    
    /// Encode
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.string, forKey: "string")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextBackedString()
        one.string = self.string
        return one
    }
}

/// TextBinding objects are used by the NSAttributedString class cluster
/// as the values for shadow attributes (stored in the attributed string under
/// the key named TextAttribute.textBinding).
///
/// Add this to a range of text will make the specified characters 'binding together'.
/// TextView will treat the range of text as a single character during text
/// selection and edit.
public class TextBinding: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// 删除确认
    public var isDeleteConfirm = false
    
    /// 构造方法
    public override init() {
        super.init()
    }
    
    /// confirm the range when delete in TextView
    public convenience init(isDeleteConfirm: Bool) {
        self.init()
        
        self.isDeleteConfirm = isDeleteConfirm
    }
    
    // MARK: - NSCoding
    /// Decode
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        self.isDeleteConfirm = aDecoder.decodeBool(forKey: "isDeleteConfirm")
    }
    
    /// Encode
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.isDeleteConfirm, forKey: "isDeleteConfirm")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        return TextBinding(isDeleteConfirm: self.isDeleteConfirm)
    }
}

/// TextShadow objects are used by the NSAttributedString class cluster
///
/// as the values for shadow attributes (stored in the attributed string under
/// the key named TextAttribute.textShadow or TextAttribute.textInnerShadow).
///
/// It's similar to `NSShadow`, but offers more options.
public class TextShadow: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// shadow color
    public var color: UIColor?
    
    /// shadow offset
    public var offset = CGSize.zero
    
    /// shadow blur radius
    public var radius: CGFloat = 0
    
    /// shadow blend mode
    public var blendMode = CGBlendMode.normal
    
    /// a sub shadow which will be added above the parent shadow
    public var subShadow: TextShadow?
    
    /// 构造方法
    public override init() {
        super.init()
    }
    
    /// 遍历构造方法
    public convenience init(color: UIColor?, offset: CGSize, radius: CGFloat) {
        self.init()
        
        self.color = color
        self.offset = offset
        self.radius = radius
    }
    
    /// convert NSShadow to TextShadow
    public convenience init?(nsShadow: NSShadow?) {
        guard let nsShadow = nsShadow else {
            return nil
        }
        self.init()
        
        self.offset = nsShadow.shadowOffset
        self.radius = nsShadow.shadowBlurRadius
        if let color = nsShadow.shadowColor {
            if CGColor.typeID == CFGetTypeID(color as CFTypeRef) {
                // swiftlint:disable:next force_cast
                let color = UIColor(cgColor: color as! CGColor)
                self.color = color
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        
        color = aDecoder.decodeObject(forKey: "color") as? UIColor
        radius = CGFloat(aDecoder.decodeFloat(forKey: "radius"))
        offset = aDecoder.decodeCGSize(forKey: "offset")
        subShadow = aDecoder.decodeObject(forKey: "subShadow") as? Self
    }
    
    /// convert TextShadow to NSShadow
    public func nsShadow() -> NSShadow? {
        let shadow = NSShadow()
        shadow.shadowOffset = offset
        shadow.shadowBlurRadius = radius
        shadow.shadowColor = color
        return shadow
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(color, forKey: "color")
        aCoder.encode(Float(radius), forKey: "radius")
        aCoder.encode(offset, forKey: "offset")
        aCoder.encode(subShadow, forKey: "subShadow")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        
        let one = TextShadow()
        one.color = self.color
        one.radius = self.radius
        one.offset = self.offset
        one.subShadow = self.subShadow?.copy() as? Self
        return one
    }
    
}

/// TextDecorationLine objects are used by the NSAttributedString class cluster
/// as the values for decoration line attributes (stored in the attributed string under
/// the key named TextAttribute.textUnderline or TextAttribute.textStrikethrough).
///
/// When it's used as underline, the line is drawn below text glyphs;
/// when it's used as strikethrough, the line is drawn above text glyphs.
public class TextDecoration: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// line style
    public var style: TextLineStyle = .none
    
    /// line width (nil means automatic width)
    public var width: NSNumber?
    
    /// line color (nil means automatic color)
    public var color: UIColor?
    
    /// line shadow
    public var shadow: TextShadow?
    
    /// 构造方法
    public override init() {
        self.style = .single
        
        super.init()
    }
    
    /// 便利构造方法
    public convenience init(style: TextLineStyle, width: NSNumber? = nil, color: UIColor? = nil) {
        self.init()
        
        self.style = style
        self.width = width
        self.color = color
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        
        if let style = TextLineStyle(rawValue: aDecoder.decodeInteger(forKey: "style")) {
            self.style = style
        } else {
            self.style = .none
        }
        self.width = aDecoder.decodeObject(forKey: "width") as? NSNumber
        self.color = aDecoder.decodeObject(forKey: "color") as? UIColor
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(style.rawValue, forKey: "style")
        aCoder.encode(width, forKey: "width")
        aCoder.encode(color, forKey: "color")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        
        let one = TextDecoration()
        one.style = style
        one.width = width
        one.color = color
        return one
    }
    
}

/// TextBorder objects are used by the NSAttributedString class cluster
/// as the values for border attributes (stored in the attributed string under
/// the key named TextAttribute.textBorder or TextAttribute.textBackgroundBorder).
///
/// It can be used to draw a border around a range of text, or draw a background
/// to a range of text.
///
/// Example:
///
///     ╭──────╮
///     │ Text │
///     ╰──────╯
public class TextBorder: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// border line style
    public var lineStyle = TextLineStyle.single
    
    /// border line width
    public var strokeWidth: CGFloat = 0
    
    /// border line color
    public var strokeColor: UIColor?
    
    /// border line join : CGLineJoin
    public var lineJoin: CGLineJoin = .miter
    
    /// border insets for text bounds
    public var insets: UIEdgeInsets = .zero
    
    /// border corder radius
    public var cornerRadius: CGFloat = 0
    
    /// border shadow
    public var shadow: TextShadow?
    
    /// inner fill color
    public var fillColor: UIColor?
    
    /// 构造方法
    public override init() {
        super.init()
    }
    
    /// 遍历构造方法
    public convenience init(lineStyle: TextLineStyle, lineWidth: CGFloat, strokeColor: UIColor?) {
        self.init()
        
        self.lineStyle = lineStyle
        self.strokeWidth = lineWidth
        self.strokeColor = strokeColor
    }
    
    /// 遍历构造方法
    public convenience init(fillColor: UIColor?, cornerRadius: CGFloat) {
        self.init()
        
        self.fillColor = fillColor
        self.cornerRadius = cornerRadius
        self.insets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: -2)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        if let style = TextLineStyle(rawValue: aDecoder.decodeInteger(forKey: "lineStyle")) {
            self.lineStyle = style
        }
        self.strokeWidth = CGFloat(aDecoder.decodeFloat(forKey: "strokeWidth"))
        self.strokeColor = aDecoder.decodeObject(forKey: "strokeColor") as? UIColor
        if let join = CGLineJoin(rawValue: aDecoder.decodeInt32(forKey: "lineJoin")) {
            self.lineJoin = join
        }
        self.insets = aDecoder.decodeUIEdgeInsets(forKey: "insets")
        self.cornerRadius = CGFloat(aDecoder.decodeFloat(forKey: "cornerRadius"))
        self.shadow = aDecoder.decodeObject(forKey: "shadow") as? TextShadow
        self.fillColor = aDecoder.decodeObject(forKey: "fillColor") as? UIColor
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(lineStyle.rawValue, forKey: "lineStyle")
        aCoder.encode(Float(strokeWidth), forKey: "strokeWidth")
        aCoder.encode(strokeColor, forKey: "strokeColor")
        aCoder.encode(lineJoin.rawValue, forKey: "lineJoin")
        aCoder.encode(insets, forKey: "insets")
        aCoder.encode(Float(cornerRadius), forKey: "cornerRadius")
        aCoder.encode(shadow, forKey: "shadow")
        aCoder.encode(fillColor, forKey: "fillColor")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextBorder()
        one.lineStyle = self.lineStyle
        one.strokeWidth = self.strokeWidth
        one.strokeColor = self.strokeColor
        one.lineJoin = self.lineJoin
        one.insets = self.insets
        one.cornerRadius = self.cornerRadius
        one.shadow = self.shadow?.copy() as? TextShadow
        one.fillColor = self.fillColor
        return one
    }
}

/// TextAttachment objects are used by the NSAttributedString class cluster
/// as the values for attachment attributes (stored in the attributed string under
/// the key named TextAttribute.textAttachment).
///
/// When display an attributed string which contains `TextAttachment` object,
/// the content will be placed in text metric. If the content is `UIImage`,
/// then it will be drawn to CGContext; if the content is `UIView` or `CALayer`,
/// then it will be added to the text container's view or layer.
public class TextAttachment: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// Supported type: UIImage, UIView, CALayer
    public var content: Any?
    
    /// Content display mode.
    public var contentMode: UIView.ContentMode = .scaleToFill
    
    /// The insets when drawing content.
    public var contentInsets: UIEdgeInsets = .zero
    
    /// The user information dictionary.
    public var userInfo: NSDictionary?
    
    /// 构造方法
    public override init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        content = aDecoder.decodeObject(forKey: "content")
        contentInsets = aDecoder.decodeUIEdgeInsets(forKey: "contentInsets")
        userInfo = aDecoder.decodeObject(forKey: "userInfo") as? NSDictionary
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(content, forKey: "content")
        aCoder.encode(contentInsets, forKey: "contentInsets")
        aCoder.encode(userInfo, forKey: "userInfo")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        
        let one = TextAttachment()
        if let object = (content as? NSObject), object.responds(to: #selector(NSObject.copy)) {
            one.content = object.copy()
        } else {
            one.content = self.content
        }
        one.contentInsets = self.contentInsets
        one.userInfo = self.userInfo?.copy() as? NSDictionary
        return one
    }
    
}

/// TextHighlight objects are used by the NSAttributedString class cluster
/// as the values for touchable highlight attributes (stored in the attributed string
/// under the key named TextHighlightAttributeName).
///
/// When display an attributed string in `Label` or `TextView`, the range of
/// highlight text can be toucheds down by users. If a range of text is turned into
/// highlighted state, the `attributes` in `TextHighlight` will be used to modify
/// (set or remove) the original attributes in the range for display.
public class TextHighlight: NSObject, NSCoding, NSCopying, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// 字体
    public var font: UIFont? {
        get {
            return attributes[NSAttributedString.Key(rawValue: kCTFontAttributeName as String)] as? UIFont
        }
        set {
            if let newFont = newValue {
                let ctFont = CTFontCreateWithName(newFont.fontName as CFString, newFont.pointSize, nil)
                attributes[NSAttributedString.Key(rawValue: kCTFontAttributeName as String)] = ctFont
            } else {
                attributes[NSAttributedString.Key(rawValue: kCTFontAttributeName as String)] = nil
            }
        }
    }
    
    /// 颜色
    public var color: UIColor? {
        get {
            return attributes[NSAttributedString.Key.foregroundColor] as? UIColor
        }
        set {
            attributes[NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String)] = newValue?.cgColor
            attributes[NSAttributedString.Key.foregroundColor] = newValue
        }
    }
    
    /// 描边宽度
    public var strokeWidth: NSNumber? {
        get {
            return attributes[NSAttributedString.Key(rawValue: kCTStrokeWidthAttributeName as String)] as? NSNumber
        }
        set {
            attributes[NSAttributedString.Key(rawValue: kCTStrokeWidthAttributeName as String)] = newValue
        }
    }
    
    /// 描边颜色
    public var strokeColor: UIColor? {
        get {
            return attributes[NSAttributedString.Key.strokeColor] as? UIColor
        }
        set {
            attributes[NSAttributedString.Key(rawValue: kCTStrokeColorAttributeName as String)] = newValue?.cgColor
            attributes[NSAttributedString.Key.strokeColor] = newValue
        }
    }
    
    /// 阴影
    public var shadow: TextShadow? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textShadow, value: newValue)
        }
    }
    
    /// 内阴影
    public var innerShadow: TextShadow? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textInnerShadow, value: newValue)
        }
    }
    
    /// 下划线
    public var underline: TextDecoration? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textUnderline, value: newValue)
        }
    }
    
    /// 删除线
    public var strikethrough: TextDecoration? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textStrikethrough, value: newValue)
        }
    }
    
    /// 背景边框
    public var backgroundBorder: TextBorder? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textBackgroundBorder, value: newValue)
        }
    }
    
    /// 边框
    public var border: TextBorder? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textBorder, value: newValue)
        }
    }
    
    /// 附件
    public var attachment: TextAttachment? {
        get {
            return nil
        }
        set {
            self.setAttribute(TextAttribute.textAttachment, value: newValue)
        }
    }
    
    /// Attributes that you can apply to text in an attributed string when highlight.
    /// Key:   Same as CoreText/Text Attribute Name.
    /// Value: Modify attribute value when highlight (nil for remove attribute).
    public private(set) var attributes: [NSAttributedString.Key: Any] = [:]
    
    /// The user information dictionary, default is nil.
    public var userInfo: NSDictionary?
    
    /// Tap action when user tap the highlight, default is nil.
    /// If the value is nil, TextView or Label will ask it's delegate to handle the tap action.
    public var tapAction: TextAction?
    
    /// Long press action when user long press the highlight, default is nil.
    /// If the value is nil, TextView or Label will ask it's delegate to handle the long press action.
    public var longPressAction: TextAction?
    
    /// 构造方法
    override public init() {
        super.init()
    }
    
    /// Convenience methods to create a default highlight with the specifeid background color.
    ///
    /// - Parameters:
    ///     - backgroundColor: The background border color.
    public convenience init(backgroundColor: UIColor?) {
        self.init()
        
        let border = TextBorder()
        border.insets = UIEdgeInsets(top: -2, left: -1, bottom: -2, right: -1)
        border.cornerRadius = 3
        border.fillColor = backgroundColor
        self.backgroundBorder = border
    }
    
    /// Creates a highlight object with specified attributes.
    ///
    /// - Parameters:
    ///     - attributes: The attributes which will replace original attributes when highlight,
    /// If the value is NSNull, it will removed when highlight.
    public convenience init(attributes: [NSAttributedString.Key: Any]?) {
        self.init()
        if let attr = attributes {
            self.attributes = attr
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        if let data = aDecoder.decodeObject(forKey: "attributes") as? Data {
            let attrs = try? JSONSerialization.jsonObject(with: data)
            if let attrs = attrs as? [NSAttributedString.Key: Any] {
                self.attributes = attrs
            }
        }
        self.userInfo = aDecoder.decodeObject(forKey: "userInfo") as? NSDictionary
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        let data = try? JSONSerialization.data(withJSONObject: self.attributes, options: [])
        aCoder.encode(data, forKey: "attributes")
        aCoder.encode(self.userInfo, forKey: "userInfo")
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextHighlight()
        one.attributes = self.attributes
        return one
    }
    
    // MARK: - Convenience methods below to set the `attributes`.
    public func setAttribute(_ key: NSAttributedString.Key, value: Any?) {
        self.attributes[key] = value
    }
}

// MARK: - Attribute Value Define

/// The tap/long press action callback defined in Text.
///
/// - Parameters:
///     - containerView: The text container view (such as Label/TextView).
///     - text: The whole text.
///     - range: The text range in `text` (if no range, the range.location is NSNotFound).
///     - rect: The text frame in `containerView` (if no data, the rect is CGRectNull).
public enum TextAttribute {
    
    // MARK: - Attribute Name Defined in Text
    
    /// The value of this attribute is a `TextBackedString` object.
    /// Use this attribute to store the original plain text if it is replaced by something else (such as attachment).
    public static let textBackedString = NSAttributedString.Key("TextBackedString")
    
    /// The value of this attribute is a `TextBinding` object.
    /// Use this attribute to bind a range of text together, as if it was a single charactor.
    public static let textBinding = NSAttributedString.Key("TextBinding")
    
    /// The value of this attribute is a `TextShadow` object.
    /// Use this attribute to add shadow to a range of text.
    /// Shadow will be drawn below text glyphs. Use TextShadow.subShadow to add multi-shadow.
    public static let textShadow = NSAttributedString.Key("TextShadow")
    
    /// The value of this attribute is a `TextShadow` object.
    /// Use this attribute to add inner shadow to a range of text.
    /// Inner shadow will be drawn above text glyphs. Use TextShadow.subShadow to add multi-shadow.
    public static let textInnerShadow = NSAttributedString.Key("TextInnerShadow")
    
    /// The value of this attribute is a `TextDecoration` object.
    /// Use this attribute to add underline to a range of text.
    /// The underline will be drawn below text glyphs.
    public static let textUnderline = NSAttributedString.Key("TextUnderline")
    
    /// The value of this attribute is a `TextDecoration` object.
    /// Use this attribute to add strikethrough (depublic static lete line) to a range of text.
    /// The strikethrough will be drawn above text glyphs.
    public static let textStrikethrough = NSAttributedString.Key("TextStrikethrough")
    
    /// The value of this attribute is a `TextBorder` object.
    /// Use this attribute to add cover border or cover color to a range of text.
    /// The border will be drawn above the text glyphs.
    public static let textBorder = NSAttributedString.Key("TextBorder")
    
    /// The value of this attribute is a `TextBorder` object.
    /// Use this attribute to add background border or background color to a range of text.
    /// The border will be drawn below the text glyphs.
    public static let textBackgroundBorder = NSAttributedString.Key("TextBackgroundBorder")
    
    /// The value of this attribute is a `TextBorder` object.
    /// Use this attribute to add a code block border to one or more line of text.
    /// The border will be drawn below the text glyphs.
    public static let textBlockBorder = NSAttributedString.Key("TextBlockBorder")
    
    /// The value of this attribute is a `TextAttachment` object.
    /// Use this attribute to add attachment to text.
    /// It should be used in conjunction with a CTRunDelegate.
    public static let textAttachment = NSAttributedString.Key("TextAttachment")
    
    /// The value of this attribute is a `TextHighlight` object.
    /// Use this attribute to add a touchable highlight state to a range of text.
    public static let textHighlight = NSAttributedString.Key("TextHighlight")
    
    /// The value of this attribute is a object of CGAffineTransform.
    /// Use this attribute to add transform to each glyph in a range of text.
    public static let textGlyphTransform = NSAttributedString.Key("TextGlyphTransform")
    
    // MARK: - String Token Define
    
    /// Object replacement character (U+FFFC), used for text attachment.
    public static let textAttachmentToken = "\u{FFFC}"
    
    /// Horizontal ellipsis (U+2026), used for text truncation  "…".
    public static let textTruncationToken = "\u{2026}"
    
    private static var textAttributeTypesMap: [NSAttributedString.Key: TextAttributeType]?
    
    /// 通过 NSAttributedString.Key 获取 TextAttributeType
    public static func getTextAttributeType(for key: NSAttributedString.Key) -> TextAttributeType {
        
        if let map = textAttributeTypesMap {
            return map[key] ?? .none
        }
        
        var result: [NSAttributedString.Key: TextAttributeType] = [:]
        
        let all = TextAttributeType(
            rawValue: TextAttributeType.uiKit.rawValue |
            TextAttributeType.coreText.rawValue |
            TextAttributeType.attributedText.rawValue
        )
        let coreTextAttributedText = TextAttributeType(
            rawValue: TextAttributeType.coreText.rawValue | TextAttributeType.attributedText.rawValue
        )
        let uiKitAttributedText = TextAttributeType(
            rawValue: TextAttributeType.uiKit.rawValue | TextAttributeType.attributedText.rawValue
        )
        let uiKitCoreText = TextAttributeType(
            rawValue: TextAttributeType.uiKit.rawValue | TextAttributeType.coreText.rawValue
        )
        let uiKit = TextAttributeType.uiKit
        let coreText = TextAttributeType.coreText
        let attributedText = TextAttributeType.attributedText
        
        result[.font] = all
        result[.kern] = all
        result[.foregroundColor] = uiKit
        result[NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String)] = coreText
        result[NSAttributedString.Key(rawValue: kCTForegroundColorFromContextAttributeName as String)] = coreText
        result[.backgroundColor] = uiKit
        result[.strokeWidth] = all
        result[.strokeColor] = uiKit
        result[NSAttributedString.Key(rawValue: kCTStrokeColorAttributeName as String)] = coreTextAttributedText
        result[.shadow] = uiKitAttributedText
        result[.strikethroughStyle] = uiKit
        result[.underlineStyle] = uiKitCoreText
        result[NSAttributedString.Key(rawValue: kCTUnderlineColorAttributeName as String)] = coreText
        result[.ligature] = all
        // kCTSuperscriptAttributeName is a CoreText attrubite, but only supported by UIKit...
        result[NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)] = uiKit
        result[.verticalGlyphForm] = all
        result[NSAttributedString.Key(rawValue: kCTGlyphInfoAttributeName as String)] = coreTextAttributedText
        result[NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)] = coreTextAttributedText
        result[NSAttributedString.Key(rawValue: kCTBaselineClassAttributeName as String)] = coreTextAttributedText
        result[NSAttributedString.Key(rawValue: kCTBaselineInfoAttributeName as String)] = coreTextAttributedText
        result[NSAttributedString.Key(rawValue: kCTBaselineReferenceInfoAttributeName as String)] = coreTextAttributedText
        result[NSAttributedString.Key(rawValue: kCTWritingDirectionAttributeName as String)] = coreTextAttributedText
        result[.paragraphStyle] = all
        
        result[.strikethroughColor] = uiKit
        result[.underlineColor] = uiKit
        result[.textEffect] = uiKit
        result[.obliqueness] = uiKit
        result[.expansion] = uiKit
        result[NSAttributedString.Key(rawValue: kCTLanguageAttributeName as String)] = coreTextAttributedText
        result[.baselineOffset] = uiKit
        result[.writingDirection] = all
        result[.attachment] = uiKit
        result[.link] = uiKit
        result[NSAttributedString.Key(rawValue: kCTRubyAnnotationAttributeName as String)] = coreText
        
        result[Self.textBackedString] = attributedText
        result[Self.textBinding] = attributedText
        result[Self.textShadow] = attributedText
        result[Self.textInnerShadow] = attributedText
        result[Self.textUnderline] = attributedText
        result[Self.textStrikethrough] = attributedText
        result[Self.textBorder] = attributedText
        result[Self.textBackgroundBorder] = attributedText
        result[Self.textBlockBorder] = attributedText
        result[Self.textAttachment] = attributedText
        result[Self.textHighlight] = attributedText
        result[Self.textGlyphTransform] = attributedText
        
        textAttributeTypesMap = result
        return result[key] ?? .none
    }
}
