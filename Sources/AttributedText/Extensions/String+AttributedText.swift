//
//  String+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import Foundation

extension String {
    
    /// 字符串的个数等于字符串的 character.count
    public var length: Int {
        return self.utf16.count
    }
    
    /// compatibility API -intValue for NSString
    public var toInt: Int? {
        return Int(self)
    }
    
    /// compatibility API -floatValue for NSString
    public var toFloat: Float? {
        return Float(self)
    }
    
    /// compatibility API -doubleValue for NSString
    public var toDouble: Double? {
        return Double(self)
    }
    
    /// 索引
    public func indexOf(_ target: Character) -> Int? {
        return self.firstIndex(of: target)?.utf16Offset(in: self)
    }
    
    /// 通过 range 获取子串
    public func substring(range: Range<String.Index>) -> String {
        return String(self[range.lowerBound..<range.upperBound])
    }
    
    /// 从过 NSRange 获取子串
    public func substring(range: NSRange) -> String {
        return self.substring(start: range.location, end: range.location + range.length)
    }
    
    /// 子串
    public func substring(start: Int, end: Int) -> String {
        let startIndex = String.Index(utf16Offset: start, in: self)
        let endIndex = String.Index(utf16Offset: end, in: self)
        return String(self[startIndex..<endIndex])
    }
}
