//
//  TextRubyAnnotation.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreText

/// Wrapper for CTRubyAnnotationRef.
///
/// Example:
///
///     let ruby = TextRubyAnnotation()
///     ruby.textBefore = @"zhù yīn"
///     let ctRuby = ruby.ctRubyAnnotation
///
public class TextRubyAnnotation: NSObject, NSCopying, NSCoding, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// Specifies how the ruby text and the base text should be aligned relative to each other.
    public var alignment: CTRubyAlignment = .auto
    
    /// Specifies how the ruby text can overhang adjacent characters.
    public var overhang: CTRubyOverhang = .auto
    
    /// Specifies the size of the annotation text as a percent of the size of the base text.
    public var sizeFactor: CGFloat = 0.5
    
    /// The ruby text is positioned before the base text;
    /// i.e. above horizontal text and to the right of vertical text.
    public var textBefore: String?
    
    /// The ruby text is positioned after the base text;
    /// i.e. below horizontal text and to the left of vertical text.
    public var textAfter: String?
    
    /// The ruby text is positioned to the right of the base text whether it is horizontal or vertical.
    /// This is the way that Bopomofo annotations are attached to Chinese text in Taiwan.
    public var textInterCharacter: String?
    
    /// The ruby text follows the base text with no special styling.
    public var textInline: String?
    
    /// Initializer
    public override init() {
        super.init()
    }
    
    /// Create a ruby object from CTRuby object.
    ///
    /// - Parameters:
    ///    - ctRuby:  A CTRuby object
    ///
    /// - Returns A ruby object, or nil when an error occurs.
    public convenience init(ctRuby: CTRubyAnnotation) {
        self.init()
        
        self.alignment = CTRubyAnnotationGetAlignment(ctRuby)
        self.overhang = CTRubyAnnotationGetOverhang(ctRuby)
        self.sizeFactor = CTRubyAnnotationGetSizeFactor(ctRuby)
        self.textBefore = (CTRubyAnnotationGetTextForPosition(ctRuby, CTRubyPosition.before)) as String?
        self.textAfter = (CTRubyAnnotationGetTextForPosition(ctRuby, CTRubyPosition.after)) as String?
        self.textInterCharacter = (CTRubyAnnotationGetTextForPosition(ctRuby, CTRubyPosition.interCharacter)) as String?
        self.textInline = (CTRubyAnnotationGetTextForPosition(ctRuby, CTRubyPosition.inline)) as String?
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        if let alignment = CTRubyAlignment(rawValue: UInt8(aDecoder.decodeInt32(forKey: "alignment"))) {
            self.alignment = alignment
        }
        if let overhang = CTRubyOverhang(rawValue: UInt8(aDecoder.decodeInt32(forKey: "overhang"))) {
            self.overhang = overhang
        }
        sizeFactor = CGFloat(aDecoder.decodeFloat(forKey: "sizeFactor"))
        textBefore = aDecoder.decodeObject(forKey: "textBefore") as? String
        textAfter = aDecoder.decodeObject(forKey: "textAfter") as? String
        textInterCharacter = aDecoder.decodeObject(forKey: "textInterCharacter") as? String
        textInline = aDecoder.decodeObject(forKey: "textInline") as? String
    }
    
    /// Create a CTRuby object from the instance.
    ///
    /// - Returns: A new CTRuby object, or NULL when an error occurs.
    /// The returned value should be release after used.
    public func ctRubyAnnotation() -> CTRubyAnnotation? {
        
        let hiragana = (self.textBefore ?? "") as CFString
        let furigana = UnsafeMutablePointer<CFTypeRef>.allocate(capacity: Int(CTRubyPosition.count.rawValue))
        defer {
            furigana.deallocate()
        }

        furigana.initialize(repeating: ("" as CFString), count: 4)
        furigana[Int(CTRubyPosition.before.rawValue)] = hiragana
        furigana[Int(CTRubyPosition.after.rawValue)] = (self.textAfter ?? "") as CFString
        furigana[Int(CTRubyPosition.interCharacter.rawValue)] = (self.textInterCharacter ?? "") as CFString
        furigana[Int(CTRubyPosition.inline.rawValue)] = (self.textInline ?? "") as CFString

        var ruby: CTRubyAnnotation?
        furigana.withMemoryRebound(to: Unmanaged<CFString>?.self, capacity: 4) { [weak self] ptr in
            guard let self else { return }
            ruby = CTRubyAnnotationCreate(self.alignment, self.overhang, self.sizeFactor, ptr)
        }
        
        return ruby
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextRubyAnnotation()
        one.alignment = alignment
        one.overhang = overhang
        one.sizeFactor = sizeFactor
        one.textBefore = textBefore
        one.textAfter = textAfter
        one.textInterCharacter = textInterCharacter
        one.textInline = textInline
        return one
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(alignment.rawValue, forKey: "alignment")
        aCoder.encode(overhang.rawValue, forKey: "overhang")
        aCoder.encode(Float(sizeFactor), forKey: "sizeFactor")
        aCoder.encode(textBefore, forKey: "textBefore")
        aCoder.encode(textAfter, forKey: "textAfter")
        aCoder.encode(textInterCharacter, forKey: "textInterCharacter")
        aCoder.encode(textInline, forKey: "textInline")
    }
}
