//
//  TextSimpleEmoticonParser.swift
//  AttributedText-Example
//
//  Created by Sun on 2024/9/26.
//

import UIKit

import AttributedText

/// A simple emoticon parser.
///
/// Use this parser to map some specified piece of string to image emoticon.
///
/// Example:
///
///     "Hello :smile:"  ->  "Hello 😀"
///
/// It can also be used to extend the "unicode emoticon".
public class TextSimpleEmoticonParser: NSObject, TextParser {
    
    private var regex: NSRegularExpression?
    private var mapper: [String: UIImage]?
    private lazy var lock = DispatchSemaphore(value: 1)
    
    /// The custom emoticon mapper.
    /// The key is a specified plain string, such as ":smile:".
    /// The value is a UIImage which will replace the specified plain string in text.
    public var emoticonMapper: [String: UIImage]? {
        get {
            lock.wait()
            let mapper = self.mapper
            lock.signal()
            
            return mapper
        }
        set {
            lock.wait()
            self.mapper = newValue
            
            if let tmpMapper = newValue, !tmpMapper.isEmpty {
                var pattern = "("
                let allKeys = tmpMapper.keys
                let charset = CharacterSet(charactersIn: "$^?+*.,#|{}[]()\\")
                var index = 0
                let max = allKeys.count
                while index < max {
                    var one = allKeys[allKeys.index(allKeys.startIndex, offsetBy: index)]
                    // escape regex characters
                    var ci = 0, cmax = one.count
                    while ci < cmax {
                        let char = String(one[one.index(one.startIndex, offsetBy: ci)])
                        if let unichar = Unicode.Scalar(char), charset.contains(unichar) {
                            one.insert(contentsOf: "\\", at: one.index(one.startIndex, offsetBy: ci))
                            ci += 1
                            cmax += 1
                        }
                        ci += 1
                    }
                    pattern += one
                    if index != max - 1 {
                        pattern += "|"
                    }
                    index += 1
                }
                pattern += ")"
                do {
                    regex = try NSRegularExpression(pattern: pattern, options: [])
                } catch {
                    print("⚠️ Emoticon Parse Failed: \(error.localizedDescription)")
                }
            } else {
                regex = nil
            }
            
            lock.signal()
        }
    }
    
    override public init() {
        super.init()
    }
    
    // correct the selected range during text replacement
    private func _replaceText(in range: NSRange, withLength length: Int, selectedRange: NSRange) -> NSRange {
        var selectedRange = selectedRange
        // no change
        if range.length == length {
            return selectedRange
        }
        // right
        if range.location >= selectedRange.location + selectedRange.length {
            return selectedRange
        }
        // left
        if selectedRange.location >= range.location + range.length {
            selectedRange.location += (length - range.length)
            return selectedRange
        }
        // same
        if NSEqualRanges(range, selectedRange) {
            selectedRange.length = length
            return selectedRange
        }
        // one edge same
        if (range.location == selectedRange.location && range.length < selectedRange.length) ||
            (range.location + range.length == selectedRange.location + selectedRange.length &&
             range.length < selectedRange.length) {
            selectedRange.length += (length - range.length)
            return selectedRange
        }
        
        selectedRange.location = range.location + length
        selectedRange.length = 0
        
        return selectedRange
    }
    
    /// 解析文本
    public func parseText(_ text: NSMutableAttributedString?, selectedRange range: NSRangePointer?) -> Bool {
        guard let text = text, text.length > 0 else {
            return false
        }
        
        let tmpMapper: [AnyHashable: UIImage]?
        let tmpRegex: NSRegularExpression?
        
        lock.wait()
        tmpMapper = self.mapper
        tmpRegex = self.regex
        lock.signal()
        
        guard let tMapper = tmpMapper, !tMapper.isEmpty, tmpRegex != nil else {
            return false
        }
        
        let matches = tmpRegex?.matches(
            in: text.string,
            options: [],
            range: NSRange(location: 0, length: text.length)
        )
        if let matches, matches.isEmpty {
            return false
        }
        var selectedRange = {
            if let range = range {
                return range.pointee
            }
            return NSRange(location: 0, length: 0)
        }()
        var cutLength = 0
        
        for one in matches ?? [] {
            var oneRange = one.range
            if oneRange.length == 0 {
                continue
            }
            oneRange.location -= cutLength
            let subStr = (text.string as NSString).substring(with: oneRange)
            let emoticon = tMapper[subStr]
            guard emoticon != nil else {
                continue
            }
            var fontSize: CGFloat = 12 // CoreText default value
            
            // swiftlint:disable:next force_cast
            if let font = text.attribute(for: .font, at: oneRange.location) as! CTFont? {
                fontSize = CTFontGetSize(font)
            }
            let atr = NSAttributedString.attachmentString(emojiImage: emoticon, fontSize: fontSize)
            let backedstring = TextBackedString()
            backedstring.string = subStr
            atr?.setTextBackedString(backedstring, range: NSRange(location: 0, length: atr?.length ?? 0))
            text.replaceCharacters(in: oneRange, with: atr?.string ?? "")
            text.removeDiscontinuousAttributes(in: NSRange(location: oneRange.location, length: atr?.length ?? 0))
            if let anAttributes = atr?.attributes {
                text.addAttributes(anAttributes, range: NSRange(location: oneRange.location, length: atr?.length ?? 0))
            }
            selectedRange = _replaceText(in: oneRange, withLength: atr?.length ?? 0, selectedRange: selectedRange)
            cutLength += oneRange.length - 1
        }
        
        range?.pointee = selectedRange
        
        return true
    }
}
