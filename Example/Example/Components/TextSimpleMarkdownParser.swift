//
//  TextSimpleMarkdownParser.swift
//  AttributedText-Example
//
//  Created by Sun on 2024/9/26.
//

import UIKit

import AttributedText

// swiftlint:disable file_length type_body_length

/// A simple markdown parser.
///
/// It'a very simple markdown parser, you can use this parser to highlight some
/// small piece of markdown text.
///
/// This markdown parser use regular expression to parse text, slow and weak.
/// If you want to write a better parser, try these projests:
///
/// - https://github.com/NimbusKit/markdown
/// - https://github.com/dreamwieber/AttributedMarkdown
/// - https://github.com/indragiek/CocoaMarkdown
///
/// Or you can use lex/yacc to generate your custom parser.
public class TextSimpleMarkdownParser: NSObject, TextParser {
    private var font: UIFont?
    /// h1~h6
    private var headerFonts: [UIFont] = []
    private var boldFont: UIFont?
    private var italicFont: UIFont?
    private var boldItalicFont: UIFont?
    private var monospaceFont: UIFont?
    private var border = TextBorder()
    
    // swiftlint:disable force_try
    /// escape
    private var regexEscape = try! NSRegularExpression(
        pattern: "(\\\\\\\\|\\\\\\`|\\\\\\*|\\\\\\_|\\\\\\(|\\\\\\)|\\\\\\[|\\\\\\]|\\\\#|\\\\\\+|\\\\\\-|\\\\\\!)",
        options: []
    )
    /// #heade
    private var regexHeader = try! NSRegularExpression(
        pattern: "^((\\#{1,6}[^#].*)|(\\#{6}.+))$",
        options: .anchorsMatchLines
    )
    /// header\n====
    private var regexH1 = try! NSRegularExpression(
        pattern: "^[^=\\n][^\\n]*\\n=+$",
        options: .anchorsMatchLines
    )
    /// header\n----
    private var regexH2 = try! NSRegularExpression(
        pattern: "^[^-\\n][^\\n]*\\n-+$",
        options: .anchorsMatchLines
    )
    /// ******
    private var regexBreakline = try! NSRegularExpression(
        pattern: "^[ \\t]*([*-])[ \\t]*((\\1)[ \\t]*){2,}[ \\t]*$",
        options: .anchorsMatchLines
    )
    /// *text*  _text_
    private var regexEmphasis = try! NSRegularExpression(
        pattern: "((?<!\\*)\\*(?=[^ \\t*])(.+?)(?<=[^ \\t*])\\*(?!\\*)|(?<!_)_(?=[^ \\t_])(.+?)(?<=[^ \\t_])_(?!_))",
        options: []
    )
    /// **text**
    private var regexStrong = try! NSRegularExpression(
        pattern: "(?<!\\*)\\*{2}(?=[^ \\t*])(.+?)(?<=[^ \\t*])\\*{2}(?!\\*)",
        options: []
    )
    /// ***text*** ___text___
    private var regexStrongEmphasis = try! NSRegularExpression(
        pattern: """
        ((?<!\\*)\\*{3}(?=[^ \\t*])(.+?)(?<=[^ \\t*])\\*{3}(?!\\*)|(?<!_)_{3}(?=[^ \\t_])(.+?)\
        (?<=[^ \\t_])_{3}(?!_))
        """,
        options: []
    )
    /// __text__
    private var regexUnderline = try! NSRegularExpression(
        pattern: "(?<!_)__(?=[^ \\t_])(.+?)(?<=[^ \\t_])\\__(?!_)",
        options: []
    )
    /// ~~text~~
    private var regexStrikethrough = try! NSRegularExpression(
        pattern: "(?<!~)~~(?=[^ \\t~])(.+?)(?<=[^ \\t~])\\~~(?!~)",
        options: []
    )
    /// `text`
    private var regexInlineCode = try! NSRegularExpression(
        pattern: "(?<!`)(`{1,3})([^`\n]+?)\\1(?!`)",
        options: []
    )
    /// [name](link)
    private var regexLink = try! NSRegularExpression(
        pattern: "!?\\[([^\\[\\]]+)\\](\\(([^\\(\\)]+)\\)|\\[([^\\[\\]]+)\\])",
        options: []
    )
    /// [ref]:
    private var regexLinkRefer = try! NSRegularExpression(
        pattern: "^[ \\t]*\\[[^\\[\\]]\\]:",
        options: .anchorsMatchLines
    )
    /// 1.text 2.text 3.text
    private var regexList = try! NSRegularExpression(
        pattern: "^[ \\t]*([*+-]|\\d+[.])[ \\t]+",
        options: .anchorsMatchLines
    )
    /// > quote
    private var regexBlockQuote = try! NSRegularExpression(
        pattern: "^[ \\t]*>[ \\t>]*",
        options: .anchorsMatchLines
    )
    /// \tcode \tcode
    private var regexCodeBlock = try! NSRegularExpression(
        pattern: "(^\\s*$\\n)((( {4}|\\t).*(\\n|\\z))|(^\\s*$\\n))+",
        options: .anchorsMatchLines
    )
    private var regexNotEmptyLine = try! NSRegularExpression(
        pattern: "^[ \\t]*[^ \\t]+[ \\t]*$",
        options: .anchorsMatchLines
    )
    // swiftlint:enable force_try
    
    private var _fontSize: CGFloat = 14
    /// default is 14
    public var fontSize: CGFloat {
        get {
            return _fontSize
        }
        set {
            if newValue < 1 {
                _fontSize = 12
            } else {
                _fontSize = newValue
            }
            _updateFonts()
        }
    }
    
    private var _headerFontSize: CGFloat = 20
    /// default is 20
    public var headerFontSize: CGFloat {
        get {
            return _headerFontSize
        }
        set {
            if newValue < 1 {
                _headerFontSize = 20
            } else {
                _headerFontSize = newValue
            }
            _updateFonts()
        }
    }
    
    /// 文本颜色
    public var textColor: UIColor = .white
    /// 控制文本颜色
    public var controlTextColor: UIColor?
    /// 标题文本颜色
    public var headerTextColor: UIColor?
    /// 缩进文本颜色
    public var inlineTextColor: UIColor?
    /// 代码文本颜色
    public var codeTextColor: UIColor?
    /// 链接文本颜色
    public var linkTextColor: UIColor?
    
    override public init() {
        super.init()
        
        _updateFonts()
        setColorWithBrightTheme()
    }
    
    /// reset the color properties to pre-defined value.
    public func setColorWithBrightTheme() {
        textColor = .black
        controlTextColor = UIColor(white: 0.749, alpha: 1.000)
        headerTextColor = UIColor(red: 1.000, green: 0.502, blue: 0.000, alpha: 1.000)
        inlineTextColor = UIColor(white: 0.150, alpha: 1.000)
        codeTextColor = UIColor(white: 0.150, alpha: 1.000)
        linkTextColor = UIColor(red: 0.000, green: 0.478, blue: 0.962, alpha: 1.000)
        border = TextBorder()
        border.lineStyle = TextLineStyle.single
        border.fillColor = UIColor(white: 0.184, alpha: 0.090)
        border.strokeColor = UIColor(white: 0.546, alpha: 0.650)
        border.insets = UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
        border.cornerRadius = 2
        border.strokeWidth = CGFloat(1).toPoint()
    }
    
    /// reset the color properties to pre-defined value.
    public func setColorWithDarkTheme() {
        textColor = UIColor.white
        controlTextColor = UIColor(white: 0.604, alpha: 1.000)
        headerTextColor = UIColor(red: 0.558, green: 1.000, blue: 0.502, alpha: 1.000)
        inlineTextColor = UIColor(red: 1.000, green: 0.862, blue: 0.387, alpha: 1.000)
        codeTextColor = UIColor(white: 0.906, alpha: 1.000)
        linkTextColor = UIColor(red: 0.000, green: 0.646, blue: 1.000, alpha: 1.000)
        border = TextBorder()
        border.lineStyle = TextLineStyle.single
        border.fillColor = UIColor(white: 0.820, alpha: 0.130)
        border.strokeColor = UIColor(white: 1.000, alpha: 0.280)
        border.insets = UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
        border.cornerRadius = 2
        border.strokeWidth = CGFloat(1).toPoint()
    }
    
    private func _updateFonts() {
        font = UIFont.systemFont(ofSize: fontSize)
        headerFonts = [UIFont]()
        for index in 0..<6 {
            let size = headerFontSize - (headerFontSize - fontSize) / 5.0 * CGFloat(index)
            headerFonts.append(UIFont.systemFont(ofSize: size))
        }
        boldFont = font?.traitBold()
        italicFont = font?.traitItalic()
        boldItalicFont = font?.traitBoldItalic()
        monospaceFont = UIFont(name: "Menlo", size: fontSize)
        if monospaceFont == nil {
            monospaceFont = UIFont(name: "Courier", size: fontSize)
        }
    }
    
    private func lenghOfBeginWhite(in string: String?, with range: NSRange) -> Int {
        guard let string = string else {
            return 0
        }
        for index in 0..<range.length {
            let char = String(string[string.index(string.startIndex, offsetBy: index + range.location)])
            if char != " ", char != "\t", char != "\n" {
                return index
            }
        }
        return string.length
    }
    
    private func lenghOfEndWhite(in string: String?, with range: NSRange) -> Int {
        guard let string = string else {
            return 0
        }
        var index = range.length - 1
        while index >= 0 {
            let char = String(string[string.index(string.startIndex, offsetBy: index + range.location)])
            if char != " ", char != "\t", char != "\n" {
                return (range.length - index)
            }
            index -= 1
        }
        return string.length
    }
    
    private func lenghOfBeginChar(_ char: Character, in string: String?, with range: NSRange) -> Int {
        guard let string = string, !string.isEmpty else {
            return 0
        }
        for index in 0..<range.length {
            // swiftlint:disable:next for_where
            if string[string.index(string.startIndex, offsetBy: index + range.location)] != char {
                return index
            }
        }
        return string.length
    }
    
    // swiftlint:disable function_body_length
    /// 解析文本
    public func parseText(_ text: NSMutableAttributedString?, selectedRange _: NSRangePointer?) -> Bool {
        guard let text = text, text.length > 0 else {
            return false
        }
        
        text.removeAttributes(in: NSRange(location: 0, length: text.length))
        text.setFont(font)
        text.setTextColor(textColor)
        let string = text.string
        
        regexEscape.replaceMatches(
            in: NSMutableString(string: string),
            options: [],
            range: NSRange(location: 0, length: string.length),
            withTemplate: "@@"
        )
        
        regexHeader.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                let whiteLen = self.lenghOfBeginWhite(in: string, with: range)
                var sharpLen = self.lenghOfBeginChar(
                    "#"["#".startIndex],
                    in: string,
                    with: NSRange(location: range.location + whiteLen, length: range.length - whiteLen)
                )
                if sharpLen > 6 {
                    sharpLen = 6
                }
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: whiteLen + sharpLen)
                )
                text.setTextColor(
                    self.headerTextColor,
                    range: NSRange(
                        location: range.location + whiteLen + sharpLen,
                        length: range.length - whiteLen - sharpLen
                    )
                )
                text.setFont(self.headerFonts[sharpLen - 1], range: range)
            }
        )
        
        regexH1.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                var linebreak: NSRange?
                if let tmpRange = string.range(of: "\n", options: [], range: Range(range, in: string), locale: nil) {
                    linebreak = NSRange(tmpRange, in: string)
                }
                
                if let location = linebreak?.location, location != NSNotFound {
                    text.setTextColor(
                        self.headerTextColor,
                        range: NSRange(location: range.location, length: location - range.location)
                    )
                    text.setFont(
                        self.headerFonts.first,
                        range: NSRange(location: range.location, length: (location - range.location) + 1)
                    )
                    text.setTextColor(
                        self.controlTextColor,
                        range: NSRange(
                            location: location + (linebreak?.length ?? 0),
                            length: range.location + range.length - location - (linebreak?.length ?? 0)
                        )
                    )
                }
            }
        )
        
        regexH2.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                var linebreak: NSRange?
                if let tmpRange = string.range(of: "\n", options: [], range: Range(range, in: string), locale: nil) {
                    linebreak = NSRange(tmpRange, in: string)
                }
                
                if let location = linebreak?.location, location != NSNotFound {
                    text.setTextColor(
                        self.headerTextColor,
                        range: NSRange(location: range.location, length: location - range.location)
                    )
                    text.setFont(
                        self.headerFonts[1],
                        range: NSRange(location: range.location, length: (location - range.location) + 1)
                    )
                    text.setTextColor(
                        self.controlTextColor,
                        range: NSRange(
                            location: location + (linebreak?.length ?? 0),
                            length: range.location + range.length - location - (linebreak?.length ?? 0)
                        )
                    )
                }
            }
        )
        
        regexBreakline.enumerateMatches(
            in: string, options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                if let range = result?.range {
                    text.setTextColor(self.controlTextColor, range: range)
                }
            }
        )
        
        regexEmphasis.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: 1)
                )
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: (range.location + range.length) - 1, length: 1)
                )
                text.setFont(
                    self.italicFont,
                    range: NSRange(location: range.location + 1, length: range.length - 2)
                )
            }
        )
        
        regexStrong.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: 2)
                )
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: (range.location + range.length) - 2, length: 2)
                )
                text.setFont(
                    self.boldFont,
                    range: NSRange(location: range.location + 2, length: range.length - 4)
                )
            }
        )
        
        regexStrongEmphasis.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: 3)
                )
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: (range.location + range.length) - 3, length: 3)
                )
                text.setFont(
                    self.boldItalicFont,
                    range: NSRange(location: range.location + 3, length: range.length - 6)
                )
            }
        )
        
        regexUnderline.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: 2)
                )
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: (range.location + range.length) - 2, length: 2)
                )
                text.setTextUnderline(
                    TextDecoration(style: .single, width: 1, color: nil),
                    range: NSRange(location: range.location + 2, length: range.length - 4)
                )
            }
        )
        
        regexStrikethrough.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: 2)
                )
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: (range.location + range.length) - 2, length: 2)
                )
                text.setTextStrikethrough(
                    TextDecoration(style: .single, width: 1, color: nil),
                    range: NSRange(location: range.location + 2, length: range.length - 4)
                )
            }
        )
        
        regexInlineCode.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                let len: Int = self.lenghOfBeginChar("`", in: string, with: range)
                
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: range.location, length: len)
                )
                text.setTextColor(
                    self.controlTextColor,
                    range: NSRange(location: (range.location + range.length) - len, length: len)
                )
                text.setTextColor(
                    self.inlineTextColor,
                    range: NSRange(location: range.location + len, length: range.length - 2 * len)
                )
                text.setFont(
                    self.monospaceFont,
                    range: range
                )
                text.setTextBorder(
                    self.border.copy() as? TextBorder,
                    range: range
                )
            }
        )
        
        regexLink.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(self.linkTextColor, range: range)
            }
        )
        
        regexLinkRefer.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(self.controlTextColor, range: range)
            }
        )
        
        regexList.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(self.controlTextColor, range: range)
            }
        )
        
        regexBlockQuote.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                text.setTextColor(self.controlTextColor, range: range)
            }
        )
        
        regexCodeBlock.enumerateMatches(
            in: string,
            options: [],
            range: NSRange(location: 0, length: string.length),
            using: { result, _, _ in
                guard let range = result?.range else {
                    return
                }
                let firstLineRange = self.regexNotEmptyLine.rangeOfFirstMatch(
                    in: string,
                    options: [],
                    range: range
                )
                let lenStart = firstLineRange.location != NSNotFound ? (firstLineRange.location - range.location) : 0
                let lenEnd: Int = self.lenghOfEndWhite(in: string, with: range)
                if lenStart + lenEnd < range.length {
                    let codeR = NSRange(location: range.location + lenStart, length: range.length - lenStart - lenEnd)
                    text.setTextColor(self.codeTextColor, range: codeR)
                    text.setFont(self.monospaceFont, range: codeR)
                    let border = TextBorder()
                    border.lineStyle = TextLineStyle.single
                    border.fillColor = UIColor(white: 0.184, alpha: 0.090)
                    
                    border.strokeColor = UIColor(white: 0.200, alpha: 0.300)
                    border.insets = UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
                    border.cornerRadius = 3
                    border.strokeWidth = CGFloat(2).toPoint()
                    text.setTextBlockBorder(self.border.copy() as? TextBorder, range: codeR)
                }
            }
        )
        
        return true
        // swiftlint:enable function_body_length
    }
}
