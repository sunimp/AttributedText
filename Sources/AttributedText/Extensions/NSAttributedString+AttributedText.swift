//
//  NSAttributedString+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

#if canImport(SDWebImage)
import SDWebImage
#endif

extension NSAttributedString {
    
    /// 创建附件
    ///
    /// Parameters:
    /// - content: 支持 UIImage/UIView/CALayer
    /// - contentMode: 附件的内容模式
    /// - width: 附件容器的宽度
    /// - ascent: 附件容器在布局里的上升量
    /// - descent: 附件容器在布局里的下降量
    public static func attachmentString(
        content: Any?,
        contentMode: UIView.ContentMode,
        width: CGFloat,
        ascent: CGFloat,
        descent: CGFloat
    ) -> NSMutableAttributedString {
        
        let attributed = NSMutableAttributedString(string: TextAttribute.textAttachmentToken)
        let attach = TextAttachment()
        attach.content = content
        attach.contentMode = contentMode
        attributed.setTextAttachment(
            attach,
            range: NSRange(location: 0, length: attributed.length)
        )
        
        let delegate = TextRunDelegate()
        delegate.width = width
        delegate.ascent = ascent
        delegate.descent = descent
        let runDelegate = delegate.ctRunDelegate()
        attributed.setRunDelegate(
            runDelegate,
            range: NSRange(location: 0, length: attributed.length)
        )
        return attributed
    }
    
    /// 创建并返回一个附件
    ///
    /// Parameters:
    /// - content: 附件, 支持(UIImage/UIView/CALayer)
    /// - contentMode: 附件容器中的附件内容模式
    /// - attachmentSize: 附件的尺寸
    /// - font: 附件对齐的字体
    /// - alignment: 附件的对齐方式
    ///
    ///     例子: ContentMode: .bottom, Alignment: .top。
    ///     文本          附件持有人
    ///     ↓                ↓
    ///     ─────────┌──────────────────────┐───────
    ///        / \   │                      │ / ___|
    ///       / _ \  │                      │| |
    ///      / ___ \ │                      │| |___     ←── The text line
    ///     /_/   \_\│    ██████████████    │ \____|
    ///     ─────────│    ██████████████    │───────
    ///              │    ██████████████    │
    ///              │    ██████████████ ←───────────────── The attachment content
    ///              │    ██████████████    │
    ///              └──────────────────────┘
    ///
    public static func attachmentString(
        content: Any?,
        contentMode: UIView.ContentMode,
        attachmentSize: CGSize,
        alignTo font: UIFont?,
        alignment: TextVerticalAlignment
    ) -> NSMutableAttributedString {
        
        let attributed = NSMutableAttributedString(string: TextAttribute.textAttachmentToken)
        let attach = TextAttachment()
        attach.content = content
        attach.contentMode = contentMode
        attributed.setTextAttachment(
            attach,
            range: NSRange(location: 0, length: attributed.length)
        )
        
        let delegate = TextRunDelegate()
        delegate.width = attachmentSize.width
        switch alignment {
        case .top:
            delegate.ascent = font?.ascender ?? 0
            delegate.descent = attachmentSize.height - (font?.ascender ?? 0)
            if delegate.descent < 0 {
                delegate.descent = 0
                delegate.ascent = attachmentSize.height
            }
        case .center:
            let fontHeight: CGFloat = (font?.ascender ?? 0) - (font?.descender ?? 0)
            let yOffset: CGFloat = (font?.ascender ?? 0) - fontHeight * 0.5
            delegate.ascent = attachmentSize.height * 0.5 + yOffset
            delegate.descent = attachmentSize.height - delegate.ascent
            if delegate.descent < 0 {
                delegate.descent = 0
                delegate.ascent = attachmentSize.height
            }
        case .bottom:
            delegate.ascent = attachmentSize.height + (font?.descender ?? 0)
            delegate.descent = -(font?.descender ?? 0)
            if delegate.ascent < 0 {
                delegate.ascent = 0
                delegate.descent = attachmentSize.height
            }
        }
        // Swift 中对 CoreFoundation 对象进行了自动内存管理, 不需要手动释放
        let runDelegate = delegate.ctRunDelegate()
        attributed.setRunDelegate(
            runDelegate,
            range: NSRange(location: 0, length: attributed.length)
        )
        return attributed
    }
    
    /// 创建并返回一个附件
    ///
    /// Parameters:
    /// - emojiImage: 表情, 一个四边形图像
    /// - fontSize: 字号
    public static func attachmentString(emojiImage: UIImage?, fontSize: CGFloat) -> NSMutableAttributedString? {
        guard let image = emojiImage, fontSize > 0 else {
            return nil
        }
        var hasAnimation = false
        if (image.images?.count ?? 0) > 1 {
            hasAnimation = true
        } else {
#if canImport(SDWebImage)
            let frameCount = (image as? SDAnimatedImage)?.animatedImageFrameCount ?? 0
            if frameCount > 1 {
                hasAnimation = true
            }
#endif
        }
        let ascent = TextUtilities.getEmojiAscent(of: fontSize)
        let descent = TextUtilities.getEmojiDescent(of: fontSize)
        let bounding: CGRect = TextUtilities.getEmojiGlyphBoundingRect(of: fontSize)
        let delegate = TextRunDelegate()
        delegate.ascent = ascent
        delegate.descent = descent
        delegate.width = bounding.size.width + 2 * bounding.origin.x
        let attachment = TextAttachment()
        attachment.contentMode = UIView.ContentMode.scaleAspectFit
        attachment.contentInsets = UIEdgeInsets(
            top: ascent - (bounding.size.height + bounding.origin.y),
            left: bounding.origin.x,
            bottom: descent + bounding.origin.y,
            right: bounding.origin.x
        )
        
        if hasAnimation {
#if canImport(SDWebImage)
            let view = SDAnimatedImageView()
#else
            let view = UIImageView()
#endif
            view.frame = bounding
            view.image = image
            view.contentMode = .scaleAspectFit
            attachment.content = view
        } else {
            attachment.content = image
        }
        let attributed = NSMutableAttributedString(string: TextAttribute.textAttachmentToken)
        attributed.setTextAttachment(
            attachment,
            range: NSRange(location: 0, length: attributed.length)
        )
        let runDelegate = delegate.ctRunDelegate()
        attributed.setRunDelegate(
            runDelegate,
            range: NSRange(location: 0, length: attributed.length)
        )
        return attributed
    }
}

extension NSAttributedString {
    
    /// 返回第一个字符的属性
    public var attributes: [NSAttributedString.Key: Any]? {
        return self.attributes(at: 0)
    }
    
    /// 返回第一个字符的字体
    public var font: UIFont? {
        return self.font(at: 0)
    }
    
    /// 返回第一个字符的字距调整
    public var kern: CGFloat? {
        return self.kern(at: 0)
    }
    
    /// 返回第一个字符的文字颜色
    public var textColor: UIColor? {
        return self.textColor(at: 0)
    }
    
    /// 返回第一个字符的背景颜色
    public var backgroundColor: UIColor? {
        return self.backgroundColor(at: 0)
    }
    
    /// 返回第一个字符的描边宽度
    public var strokeWidth: CGFloat? {
        return self.strokeWidth(at: 0)
    }
    
    /// 返回第一个字符的描边颜色
    public var strokeColor: UIColor? {
        return self.strokeColor(at: 0)
    }
    
    /// 返回第一个字符的阴影
    public var shadow: NSShadow? {
        return self.shadow(at: 0)
    }
    
    /// 返回第一个字符的删除线样式
    public var strikethroughStyle: NSUnderlineStyle {
        return self.strikethroughStyle(at: 0)
    }
    
    /// 返回第一个字符的删除线颜色
    public var strikethroughColor: UIColor? {
        return self.strikethroughColor(at: 0)
    }
    
    /// 返回第一个字符的下划线样式
    public var underlineStyle: NSUnderlineStyle {
        return self.underlineStyle(at: 0)
    }
    
    /// 返回第一个字符的下划线颜色
    public var underlineColor: UIColor? {
        return self.underlineColor(at: 0)
    }
    
    /// 返回第一个字符的连字符
    public var ligature: UInt? {
        return self.ligature(at: 0)
    }
    
    /// 返回第一个字符的字符效果
    public var textEffect: String? {
        return self.textEffect(at: 0)
    }
    
    /// 返回第一个字符的倾斜度
    public var obliqueness: CGFloat? {
        return self.obliqueness(at: 0)
    }
    
    /// 返回第一个字符的展开因子
    public var expansion: CGFloat? {
        return self.expansion(at: 0)
    }
    
    /// 返回第一个字符的基线偏移
    public var baselineOffset: CGFloat? {
        return self.baselineOffset(at: 0)
    }
    
    /// 返回第一个字符是否是垂直字形形式
    public var isVerticalGlyphForm: Bool {
        return self.isVerticalGlyphForm(at: 0)
    }
    
    /// 返回第一个字符的语言
    public var language: String? {
        return self.language(at: 0)
    }
    
    /// 返回第一个字符的书写方向
    public var writingDirection: [NSWritingDirection]? {
        return self.writingDirection(at: 0)
    }
    
    /// 返回第一个字符的段落样式
    public var paragraphStyle: NSParagraphStyle? {
        return self.paragraphStyle(at: 0)
    }
    
    /// 返回第一个字符的外阴影
    public var textShadow: TextShadow? {
        return self.textShadow(at: 0)
    }
    
    /// 返回第一个字符的内阴影
    public var textInnerShadow: TextShadow? {
        return self.textInnerShadow(at: 0)
    }
    
    /// 返回第一个字符的下划线
    public var textUnderline: TextDecoration? {
        return self.textUnderline(at: 0)
    }
    /// 返回第一个字符的删除线
    public var textStrikethrough: TextDecoration? {
        return self.textStrikethrough(at: 0)
    }
    
    /// 返回第一个字符的文字边框
    public var textBorder: TextBorder? {
        return self.textBorder(at: 0)
    }
    
    /// 返回第一个字符的文字背景边框
    public var textBackgroundBorder: TextBorder? {
        return self.textBackgroundBorder(at: 0)
    }
    
    /// 返回第一个字符的仿射变换
    public var textGlyphTransform: CGAffineTransform {
        return self.textGlyphTransform(at: 0)
    }
    
    /// 返回第一个字符的文本对齐方式
    public var alignment: NSTextAlignment {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.alignment
    }
    
    /// 返回第一个字符的换行模式
    public var lineBreakMode: NSLineBreakMode {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.lineBreakMode
    }
    
    /// 返回第一个字符的行间距
    public var lineSpacing: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.lineSpacing
    }
    
    /// 返回第一个字符的段落间距
    public var paragraphSpacing: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.paragraphSpacing
    }
    
    /// 返回第一个字符的段落前的间距
    public var paragraphSpacingBefore: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.paragraphSpacingBefore
    }
    
    /// 返回第一个字符的首行缩进
    public var firstLineHeadIndent: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.firstLineHeadIndent
    }
    
    /// 返回第一个字符的头部缩进
    public var headIndent: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.headIndent
    }
    
    /// 返回第一个字符的尾部缩进
    public var tailIndent: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.tailIndent
    }
    
    /// 返回第一个字符的最小行高
    public var minimumLineHeight: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.minimumLineHeight
    }
    
    /// 返回第一个字符的最大行高
    public var maximumLineHeight: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.maximumLineHeight
    }
    
    /// 返回第一个字符的行高倍数
    public var lineHeightMultiple: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.lineHeightMultiple
    }
    
    /// 返回第一个字符的书写方向
    public var baseWritingDirection: NSWritingDirection {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.baseWritingDirection
    }
    
    /// 返回第一个字符的连字因子
    public var hyphenationFactor: Float {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.hyphenationFactor
    }
    
    /// 返回第一个字符的默认制表符间隔
    public var defaultTabInterval: CGFloat {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.defaultTabInterval
    }
    
    /// 返回第一个字符的制表符
    public var tabStops: [NSTextTab] {
        let style = self.paragraphStyle ?? NSParagraphStyle.default
        return style.tabStops
    }
    
    /// 返回 NSMakeRange(0, self.length)
    public var rangeOfAll: NSRange {
        return NSRange(location: 0, length: self.length)
    }
    
    /// 返回在给定 index 处的字体
    public func font(at index: Int) -> UIFont? {
        return self.attribute(for: .font, at: index) as? UIFont
    }
    
    /// 返给给定 index 处的字距
    public func kern(at index: Int) -> CGFloat? {
        return self.attribute(for: .kern, at: index) as? CGFloat
    }
    
    /// 返给给定 index 处的字色
    public func textColor(at index: Int) -> UIColor? {
        if let color = self.attribute(for: .foregroundColor, at: index) as? UIColor {
            return color
        }
        let key = NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String)
        if let cgColor = self.attribute(for: key, at: index) {
            // swiftlint:disable:next force_cast
            return UIColor(cgColor: cgColor as! CGColor)
        }
        return nil
    }
    
    /// 返回给定 index 处的背景色
    public func backgroundColor(at index: Int) -> UIColor? {
        return self.attribute(for: .backgroundColor, at: index) as? UIColor
    }
    
    /// 返回给定 index 处的描边宽度
    public func strokeWidth(at index: Int) -> CGFloat? {
        return self.attribute(for: .strokeWidth, at: index) as? CGFloat
    }
    
    /// 返回给定 index 处的描边颜色
    public func strokeColor(at index: Int) -> UIColor? {
        if let color = self.attribute(for: .strokeColor, at: index) as? UIColor {
            return color
        }
        
        let key = NSAttributedString.Key(rawValue: kCTStrokeColorAttributeName as String)
        if let cgColor = self.attribute(for: key, at: index) {
            // swiftlint:disable:next force_cast
            return UIColor(cgColor: cgColor as! CGColor)
        }
        return nil
    }
    
    /// 返回给定 index 处的阴影
    public func shadow(at index: Int) -> NSShadow? {
        return self.attribute(for: .shadow, at: index) as? NSShadow
    }
    
    /// 返回给定 index 处的删除线样式
    public func strikethroughStyle(at index: Int) -> NSUnderlineStyle {
        guard let value = self.attribute(for: .strikethroughStyle, at: index) as? Int else {
            return NSUnderlineStyle(rawValue: 0)
        }
        return NSUnderlineStyle(rawValue: value)
    }
    
    /// 返回给定 index 处的删除线颜色
    public func strikethroughColor(at index: Int) -> UIColor? {
        return self.attribute(for: .strikethroughColor, at: index) as? UIColor
    }
    
    /// 返回给定 index 处的下划线样式
    public func underlineStyle(at index: Int) -> NSUnderlineStyle {
        guard let value = self.attribute(for: .underlineStyle, at: index) as? Int else {
            return NSUnderlineStyle(rawValue: 0)
        }
        return NSUnderlineStyle(rawValue: value)
    }
    
    /// 返回给定 index 处的下划线颜色
    public func underlineColor(at index: Int) -> UIColor? {
        if let color = self.attribute(for: .underlineColor, at: index) as? UIColor {
            return color
        }
        let key = NSAttributedString.Key(rawValue: kCTUnderlineColorAttributeName as String)
        if let cgColor = self.attribute(for: key, at: index) {
            // swiftlint:disable:next force_cast
            return UIColor(cgColor: cgColor as! CGColor)
        }
        return nil
    }
    
    /// 返回给定 index 处的连字符
    public func ligature(at index: Int) -> UInt? {
        return self.attribute(for: .ligature, at: index) as? UInt
    }
    
    /// 返回给定 index 处的文字效果
    public func textEffect(at index: Int) -> String? {
        return self.attribute(for: .textEffect, at: index) as? String
    }
    
    /// 返回给定 index 处的倾斜度
    public func obliqueness(at index: Int) -> CGFloat? {
        return self.attribute(for: .obliqueness, at: index) as? CGFloat
    }
    
    /// 返回给定 index 处的字形的展开因子
    public func expansion(at index: Int) -> CGFloat? {
        return self.attribute(for: .expansion, at: index) as? CGFloat
    }
    
    /// 返回给定 index 处的基线偏移
    public func baselineOffset(at index: Int) -> CGFloat? {
        return self.attribute(for: .baselineOffset, at: index) as? CGFloat
    }
    
    /// 返回给定 index 处的文字是否是垂直字形
    public func isVerticalGlyphForm(at index: Int) -> Bool {
        if let value = self.attribute(for: .verticalGlyphForm, at: index) as? Int {
            return value != 0
        }
        return false
    }
    
    /// 返回给定 index 处的字体语言
    public func language(at index: Int) -> String? {
        let key = NSAttributedString.Key(rawValue: kCTLanguageAttributeName as String)
        return self.attribute(for: key, at: index) as? String
    }
    
    /// 返回给定 index 处的书写方向
    public func writingDirection(at index: Int) -> [NSWritingDirection] {
        let key = NSAttributedString.Key(rawValue: kCTWritingDirectionAttributeName as String)
        if let values = self.attribute(for: key, at: index) as? [Int] {
            return values.compactMap { NSWritingDirection(rawValue: $0) }
        }
        return []
    }
    
    /// 返回给定 index 处的段落样式
    public func paragraphStyle(at index: Int) -> NSParagraphStyle? {
        guard let object = self.attribute(for: .paragraphStyle, at: index) as? NSObject else {
            return nil
        }
        if let style = object as? NSParagraphStyle {
            return style
        } else if CFGetTypeID(object) == CTParagraphStyleGetTypeID() {
            // swiftlint:disable:next force_cast
            return NSParagraphStyle.create(ctStyle: object as! CTParagraphStyle)
        }
        return nil
    }
    
    /// 返回给定 index 处的文本对齐方式
    public func alignment(at index: Int) -> NSTextAlignment {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.alignment
    }
    
    /// 返回给定 index 处的文本换行模式
    public func lineBreakMode(at index: Int) -> NSLineBreakMode {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.lineBreakMode
    }
    
    /// 返回给定 index 处的文本行间距
    public func lineSpacing(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.lineSpacing
    }
    
    /// 返回给定 index 处的文本段落间距
    public func paragraphSpacing(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.paragraphSpacing
    }
    
    /// 返回给定 index 处的文本段落前间距
    public func paragraphSpacingBefore(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.paragraphSpacingBefore
    }
    
    /// 返回给定 index 处的文本首行缩进
    public func firstLineHeadIndent(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.firstLineHeadIndent
    }
    
    /// 返回给定 index 处的文本头部缩进
    public func headIndent(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.headIndent
    }
    
    /// 返回给定 index 处的文本尾部缩进
    public func tailIndent(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.tailIndent
    }
    
    /// 返回给定 index 处的文本最小行高
    public func minimumLineHeight(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.minimumLineHeight
    }
    
    /// 返回给定 index 处的文本最大行高
    public func maximumLineHeight(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.maximumLineHeight
    }
    
    /// 返回给定 index 处的文本行高倍数
    public func lineHeightMultiple(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.lineHeightMultiple
    }
    
    /// 返回给定 index 处的文本书写方向
    public func baseWritingDirection(at index: Int) -> NSWritingDirection {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.baseWritingDirection
    }
    
    /// 返回给定 index 处的文本连字符因子
    public func hyphenationFactor(at index: Int) -> Float {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.hyphenationFactor
    }
    
    /// 返回给定 index 处的文本
    public func defaultTabInterval(at index: Int) -> CGFloat {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.defaultTabInterval
    }
    
    /// 返回给定 index 处的文本
    public func tabStops(at index: Int) -> [NSTextTab] {
        let style = self.paragraphStyle(at: index) ?? NSParagraphStyle.default
        return style.tabStops
    }
    
    /// 返回给定 index 处的阴影
    public func textShadow(at index: Int) -> TextShadow? {
        return self.attribute(for: TextAttribute.textShadow, at: index) as? TextShadow
    }
    
    /// 返回给定 index 处的内阴影
    public func textInnerShadow(at index: Int) -> TextShadow? {
        return self.attribute(for: TextAttribute.textInnerShadow, at: index) as? TextShadow
    }
    
    /// 返回给定 index 处的下划线
    public func textUnderline(at index: Int) -> TextDecoration? {
        return self.attribute(for: TextAttribute.textUnderline, at: index) as? TextDecoration
    }
    
    /// 返回给定 index 处的删除线
    public func textStrikethrough(at index: Int) -> TextDecoration? {
        return self.attribute(for: TextAttribute.textStrikethrough, at: index) as? TextDecoration
    }
    
    /// 返回给定 index 处文本边框
    public func textBorder(at index: Int) -> TextBorder? {
        return self.attribute(for: TextAttribute.textBorder, at: index) as? TextBorder
    }
    
    /// 返回给定 index 处文本背景边框
    public func textBackgroundBorder(at index: Int) -> TextBorder? {
        return self.attribute(for: TextAttribute.textBackgroundBorder, at: index) as? TextBorder
    }
    
    /// 返回给定 index 处文本仿射变换
    public func textGlyphTransform(at index: Int) -> CGAffineTransform {
        if let transform = self.attribute(for: TextAttribute.textGlyphTransform, at: index) as? CGAffineTransform {
            return transform
        }
        return .identity
    }
    /// 返回给定 range 的纯文本
    public func plainText(for range: NSRange) -> String? {
        guard range.location != NSNotFound, range.length != NSNotFound else {
            return nil
        }
        var result = ""
        if range.length == 0 {
            return result
        }
        let plainString = self.string
        self.enumerateAttribute(TextAttribute.textBackedString, in: range, options: []) { value, subRange, _ in
            if let backed = value as? TextBackedString,
               let backedString = backed.string {
                result += backedString
            } else {
                result += plainString.substring(range: subRange)
            }
        }
        return result
    }
    
    /// 返回给定 index 处字符的属性
    public func attributes(at index: Int) -> [NSAttributedString.Key: Any]? {
        if index > self.length || self.length == 0 {
            return nil
        }
        var location = index
        if self.length > 0 && index == self.length {
            location -= 1
        }
        return self.attributes(at: location, effectiveRange: nil)
    }
    
    /// 返回在给定 index 处, 给定 key 的属性
    public func attribute(for key: NSAttributedString.Key, at index: Int) -> Any? {
        if index > self.length || self.length == 0 {
            return nil
        }
        var location = index
        if self.length > 0 && index == self.length {
            location -= 1
        }
        return self.attribute(key, at: location, effectiveRange: nil)
    }
    
    /// 计算文本尺寸
    /// - Parameters:
    ///   - containerWidth: 容器的宽度
    ///   - containerHeight： 容器的高度
    ///   - maxLines: 最大行数, 默认 0, 表示不限制
    ///   - roundUp: 是否向上取整
    /// - Returns: 文本尺寸
    public func size(
        containerWidth: CGFloat = .greatestFiniteMagnitude,
        containerHeight: CGFloat = .greatestFiniteMagnitude,
        maxLines: Int = 0,
        roundUp: Bool = true
    ) -> CGSize {
        let container = TextContainer(size: CGSize(width: containerWidth, height: containerHeight))
        container.maximumNumberOfRows = maxLines
        guard let layout = TextLayout(container: container, text: self) else {
            return .zero
        }
        if roundUp {
            return layout.textBoundingSize.ceilFlattened()
        }
        return layout.textBoundingSize
    }
}

extension NSAttributedString {
    
    // MARK: - Get AttributedText attribute as property
    
    /// Unarchive string from data.
    ///
    /// - Parameters:
    ///     - data: The archived attributed string data.
    ///
    /// - Returns: Returns nil if an error occurs.
    public static func unarchive(from data: Data?) -> NSAttributedString? {
        guard let data = data else {
            return nil
        }
        do {
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        } catch {
            print("⚠️ Unarchiving Data to NSAttributedString failed: \(error)")
        }
        return nil
    }
    
    /// Archive the string to data.
    ///
    /// - Returns: Returns nil if an error occurs.
    public func archiveToData() -> Data? {
        do {
            return try self.data(
                from: self.rangeOfAll,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            )
        } catch {
            print("⚠️ Archiving NSAttributedString to Data failed: \(error)")
        }
        return nil
    }
}

extension NSMutableAttributedString {

    /// 为整个文本字符串设置具有给定名称和值的属性
    @discardableResult
    public func setAttribute(_ key: NSAttributedString.Key, value: Any?) -> Self {
        self.setAttribute(key, value: value, range: NSRange(location: 0, length: self.length))
        return self
    }
    
    /// 将具有给定名称和值的属性设置为指定范围内的字符
    @discardableResult
    public func setAttribute(_ key: NSAttributedString.Key, value: Any?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        if let value = value {
            self.addAttribute(key, value: value, range: finalRange)
        } else {
            self.removeAttribute(key, range: finalRange)
        }
        return self
    }
    
    /// 在给定的范围内移除属性
    @discardableResult
    public func removeAttributes(in range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttributes(nil, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置字体
    @discardableResult
    public func setFont(_ font: UIFont?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.font, value: font, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置字间距
    @discardableResult
    public func setKern(_ kern: CGFloat?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.kern, value: kern, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置字颜色
    @discardableResult
    public func setTextColor(_ color: UIColor?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String),
            value: color?.cgColor,
            range: finalRange
        )
        self.setAttribute(.foregroundColor, value: color, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置背景色
    @discardableResult
    public func setBackgroundColor(_ backgroundColor: UIColor?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.backgroundColor, value: backgroundColor, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置描边宽度
    @discardableResult
    public func setStrokeWidth(_ strokeWidth: CGFloat?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.strokeWidth, value: strokeWidth, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置描边颜色
    @discardableResult
    public func setStrokeColor(_ strokeColor: UIColor?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTStrokeColorAttributeName as String),
            value: strokeColor?.cgColor,
            range: finalRange
        )
        self.setAttribute(.strokeColor, value: strokeColor, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置阴影
    @discardableResult
    public func setShadow(_ shadow: NSShadow?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.shadow, value: shadow, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置删除线样式
    @discardableResult
    public func setStrikethroughStyle(_ strikethroughStyle: NSUnderlineStyle, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        let style = strikethroughStyle.rawValue == 0 ? nil : strikethroughStyle.rawValue
        self.setAttribute(.strikethroughStyle, value: style, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置删除线颜色
    @discardableResult
    public func setStrikethroughColor(_ strikethroughColor: UIColor?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.strikethroughColor, value: strikethroughColor, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置下划线样式
    @discardableResult
    public func setUnderlineStyle(_ underlineStyle: NSUnderlineStyle, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        let style = underlineStyle.rawValue == 0 ? nil : underlineStyle.rawValue
        self.setAttribute(.underlineStyle, value: style, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置下划线颜色
    @discardableResult
    public func setUnderlineColor(_ underlineColor: UIColor?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTUnderlineColorAttributeName as String),
            value: underlineColor?.cgColor,
            range: finalRange
        )
        self.setAttribute(.underlineColor, value: underlineColor, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置连字符
    @discardableResult
    public func setLigature(_ ligature: UInt?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.ligature, value: ligature, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文字效果
    @discardableResult
    public func setTextEffect(_ textEffect: String?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.textEffect, value: textEffect, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置倾斜度
    @discardableResult
    public func setObliqueness(_ obliqueness: CGFloat?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.obliqueness, value: obliqueness, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置扩展因子
    @discardableResult
    public func setExpansion(_ expansion: CGFloat?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.expansion, value: expansion, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置基线偏移
    @discardableResult
    public func setBaselineOffset(_ baselineOffset: CGFloat?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.baselineOffset, value: baselineOffset, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置垂直字形形式
    @discardableResult
    public func setIsVerticalGlyphForm(_ isVerticalGlyphForm: Bool, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        let value = isVerticalGlyphForm ? true : nil
        self.setAttribute(.verticalGlyphForm, value: value, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置语言
    @discardableResult
    public func setLanguage(_ language: String?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTLanguageAttributeName as String),
            value: language,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置书写方向
    @discardableResult
    public func setWritingDirection(_ writingDirection: [NSWritingDirection]?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTWritingDirectionAttributeName as String),
            value: writingDirection,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置段落样式
    @discardableResult
    public func setParagraphStyle(_ paragraphStyle: NSParagraphStyle?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.paragraphStyle, value: paragraphStyle, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置对齐方式
    @discardableResult
    public func setAlignment(_ alignment: NSTextAlignment, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.alignment == alignment {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.alignment == alignment {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.alignment = alignment
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置书写方向
    @discardableResult
    public func setBaseWritingDirection(
        _ baseWritingDirection: NSWritingDirection,
        range: NSRange? = nil
    ) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.baseWritingDirection == baseWritingDirection {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.baseWritingDirection == baseWritingDirection {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.baseWritingDirection = baseWritingDirection
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置行间距
    @discardableResult
    public func setLineSpacing(_ lineSpacing: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.lineSpacing == lineSpacing {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.lineSpacing == lineSpacing {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.lineSpacing = lineSpacing
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置段落间距
    @discardableResult
    public func setParagraphSpacing(_ paragraphSpacing: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.paragraphSpacing == paragraphSpacing {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.paragraphSpacing == paragraphSpacing {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.paragraphSpacing = paragraphSpacing
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置段落前间距
    @discardableResult
    public func setParagraphSpacingBefore(_ paragraphSpacingBefore: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.paragraphSpacingBefore == paragraphSpacingBefore {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.paragraphSpacingBefore == paragraphSpacingBefore {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.paragraphSpacingBefore = paragraphSpacingBefore
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置首行缩进
    @discardableResult
    public func setFirstLineHeadIndent(_ firstLineHeadIndent: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.firstLineHeadIndent == firstLineHeadIndent {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.firstLineHeadIndent == firstLineHeadIndent {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.firstLineHeadIndent = firstLineHeadIndent
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置头部缩进
    @discardableResult
    public func setHeadIndent(_ headIndent: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.headIndent == headIndent {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.headIndent == headIndent {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.headIndent = headIndent
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置尾部缩进
    @discardableResult
    public func setTailIndent(_ tailIndent: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.tailIndent == tailIndent {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.tailIndent == tailIndent {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.tailIndent = tailIndent
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置换行模式
    @discardableResult
    public func setLineBreakMode(_ lineBreakMode: NSLineBreakMode, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.lineBreakMode == lineBreakMode {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.lineBreakMode == lineBreakMode {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.lineBreakMode = lineBreakMode
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置最小行高
    @discardableResult
    public func setMinimumLineHeight(_ minimumLineHeight: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.minimumLineHeight == minimumLineHeight {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.minimumLineHeight == minimumLineHeight {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.minimumLineHeight = minimumLineHeight
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置最大行高
    @discardableResult
    public func setMaximumLineHeight(_ maximumLineHeight: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.maximumLineHeight == maximumLineHeight {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.maximumLineHeight == maximumLineHeight {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.maximumLineHeight = maximumLineHeight
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置行高倍数
    @discardableResult
    public func setLineHeightMultiple(_ lineHeightMultiple: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.lineHeightMultiple == lineHeightMultiple {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.lineHeightMultiple == lineHeightMultiple {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.lineHeightMultiple = lineHeightMultiple
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置连字因子
    @discardableResult
    public func setHyphenationFactor(_ hyphenationFactor: Float, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.hyphenationFactor == hyphenationFactor {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.hyphenationFactor == hyphenationFactor {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.hyphenationFactor = hyphenationFactor
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置默认制表符间隔
    @discardableResult
    public func setDefaultTabInterval(_ defaultTabInterval: CGFloat, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.defaultTabInterval == defaultTabInterval {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.defaultTabInterval == defaultTabInterval {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.defaultTabInterval = defaultTabInterval
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置制表符
    @discardableResult
    public func setTabStops(_ tabStops: [NSTextTab], range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.enumerateAttribute(.paragraphStyle, in: finalRange, options: []) { value, subRange, _ in
            var style: NSMutableParagraphStyle?
            if var value = value as? NSParagraphStyle {
                if CFGetTypeID(value) == CTParagraphStyleGetTypeID() {
                    // swiftlint:disable:next force_cast
                    value = NSParagraphStyle.create(ctStyle: value as! CTParagraphStyle)
                }
                if value.tabStops == tabStops {
                    return
                }
                if value is NSMutableParagraphStyle {
                    style = value as? NSMutableParagraphStyle
                } else {
                    style = value as? NSMutableParagraphStyle
                }
            } else {
                if NSParagraphStyle.default.tabStops == tabStops {
                    return
                }
                style = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
            }
            style?.tabStops = tabStops
            self.setParagraphStyle(style, range: subRange)
        }
        return self
    }
    
    /// 在给定的范围内设置上标
    @discardableResult
    public func setSuperscript(_ superscript: Int?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String),
            value: superscript,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置字形信息
    @discardableResult
    public func setGlyphInfo(_ glyphInfo: CTGlyphInfo?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTGlyphInfoAttributeName as String),
            value: glyphInfo,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置 runDelegate
    @discardableResult
    public func setRunDelegate(_ runDelegate: CTRunDelegate?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String),
            value: runDelegate,
            range: finalRange
        )
        
        return self
    }
    
    /// 在给定的范围内设置 baselineClass
    @discardableResult
    public func setBaselineClass(_ baselineClass: CFString?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTBaselineClassAttributeName as String),
            value: baselineClass,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置 baselineInfo
    @discardableResult
    public func setBaselineInfo(_ baselineInfo: CFDictionary?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTBaselineInfoAttributeName as String),
            value: baselineInfo,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置 referenceInfo
    @discardableResult
    public func setReferenceInfo(_ referenceInfo: CFDictionary?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTBaselineReferenceInfoAttributeName as String),
            value: referenceInfo,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置注解
    @discardableResult
    public func setRubyAnnotation(_ rubyAnnotation: CTRubyAnnotation?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(
            NSAttributedString.Key(rawValue: kCTRubyAnnotationAttributeName as String),
            value: rubyAnnotation,
            range: finalRange
        )
        return self
    }
    
    /// 在给定的范围内设置 NSTextAttachment
    @discardableResult
    public func setNSTextAttachment(_ attachment: NSTextAttachment?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.attachment, value: attachment, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置链接 (URL (preferred) or String)
    @discardableResult
    public func setLink(_ link: Any?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(.link, value: link, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置 TextBackedString
    @discardableResult
    public func setTextBackedString(_ textBackedString: TextBackedString?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textBackedString, value: textBackedString, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置 TextBinding
    @discardableResult
    public func setTextBinding(_ textBinding: TextBinding?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textBinding, value: textBinding, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置阴影
    @discardableResult
    public func setTextShadow(_ textShadow: TextShadow?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textShadow, value: textShadow, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置内阴影
    @discardableResult
    public func setTextInnerShadow(_ textInnerShadow: TextShadow?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textInnerShadow, value: textInnerShadow, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置下划线
    @discardableResult
    public func setTextUnderline(_ textUnderline: TextDecoration?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textUnderline, value: textUnderline, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置删除线
    @discardableResult
    public func setTextStrikethrough(_ textStrikethrough: TextDecoration?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textStrikethrough, value: textStrikethrough, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文本边框
    @discardableResult
    public func setTextBorder(_ textBorder: TextBorder?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textBorder, value: textBorder, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文本背景边框
    @discardableResult
    public func setTextBackgroundBorder(_ textBackgroundBorder: TextBorder?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textBackgroundBorder, value: textBackgroundBorder, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置自定义附件
    @discardableResult
    public func setTextAttachment(_ attachment: TextAttachment?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textAttachment, value: attachment, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文本高亮
    @discardableResult
    public func setTextHighlight(_ textHighlight: TextHighlight?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textHighlight, value: textHighlight, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文本块边框
    @discardableResult
    public func setTextBlockBorder(_ textBlockBorder: TextBorder?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setAttribute(TextAttribute.textBlockBorder, value: textBlockBorder, range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文本注解
    @discardableResult
    public func setTextRubyAnnotation(_ annotation: TextRubyAnnotation?, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        self.setRubyAnnotation(annotation?.ctRubyAnnotation(), range: finalRange)
        return self
    }
    
    /// 在给定的范围内设置文本仿射变换
    @discardableResult
    public func setTextGlyphTransform(_ textGlyphTransform: CGAffineTransform, range: NSRange? = nil) -> Self {
        let finalRange = range ?? self.rangeOfAll
        let value = textGlyphTransform.isIdentity ? nil : textGlyphTransform
        self.setAttribute(TextAttribute.textGlyphTransform, value: value, range: finalRange)
        return self
    }
    
    /// 设置文本高亮的便捷方法
    @discardableResult
    public func setTextHighlightRange(
        _ range: NSRange,
        color: UIColor,
        font: UIFont? = nil,
        backgroundColor: UIColor? = nil,
        userInfo: [AnyHashable: Any]? = nil,
        tapAction action: TextAction? = nil,
        longPressAction: TextAction? = nil
    ) -> Self {
        let highlight = TextHighlight(backgroundColor: backgroundColor)
        // swiftlint:disable:next legacy_objc_type
        highlight.userInfo = userInfo as? NSDictionary
        highlight.tapAction = action
        highlight.longPressAction = longPressAction
        self.setTextColor(color, range: range)
        if let font {
            self.setFont(font, range: range)
        }
        self.setTextHighlight(highlight, range: range)
        return self
    }
    
    /// 在接收器中插入给定位置的字符串的字符, 新的字符串继承了第一个被替换的字符的属性
    @discardableResult
    public func insertString(_ string: String?, at location: Int) -> Self {
        guard let text = string else {
            return self
        }
        self.replaceCharacters(in: NSRange(location: location, length: 0), with: text)
        self.removeDiscontinuousAttributes(in: NSRange(location: location, length: text.count))
        return self
    }
    
    /// 在接收器的尾部添加给定字符串的字符, 新的字符串继承了接收器尾部的属性
    @discardableResult
    public func appendString(_ string: String?) -> Self {
        guard let text = string else {
            return self
        }
        let length = self.length
        self.replaceCharacters(in: NSRange(location: length, length: 0), with: text)
        self.removeDiscontinuousAttributes(in: NSRange(location: length, length: text.count))
        return self
    }
    
    /// 移除指定范围内的所有不连续的属性
    /// 参见 `allDiscontinuousAttributeKeys`
    public func removeDiscontinuousAttributes(in range: NSRange) {
        for key in NSMutableAttributedString.allDiscontinuousAttributeKeys() {
            self.removeAttribute(key, range: range)
        }
    }
}

extension NSMutableAttributedString {
    
    fileprivate static var _allDiscontinuousAttributeKeys: [NSAttributedString.Key] = []
    
    /// 返回所有不连续的属性键，例如 RunDelegate/Attachment/Ruby。
    ///
    /// 这些属性只能设置在指定的文本范围内, 在编辑文本时不应该扩展到其他范围
    public static func allDiscontinuousAttributeKeys() -> [NSAttributedString.Key] {
        guard NSMutableAttributedString._allDiscontinuousAttributeKeys.isEmpty else {
            return NSMutableAttributedString._allDiscontinuousAttributeKeys
        }
        var keys: [NSAttributedString.Key] = []
        keys.append(NSAttributedString.Key(kCTSuperscriptAttributeName as String))
        keys.append(NSAttributedString.Key(kCTRunDelegateAttributeName as String))
        keys.append(TextAttribute.textBackedString)
        keys.append(TextAttribute.textBinding)
        keys.append(TextAttribute.textAttachment)
        keys.append(NSAttributedString.Key(kCTRubyAnnotationAttributeName as String))
        keys.append(NSAttributedString.Key.attachment)
        return keys
    }
    
}
