//
//  TextRunDelegate.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreText

/// CTRun (一个字形) 代理
public class TextRunDelegate: NSObject, NSCopying, NSCoding, NSSecureCoding {
    
    // MARK: - NSSecureCoding
    public static var supportsSecureCoding: Bool {
        return true
    }

    /// 上升量
    public var ascent: CGFloat = 0
    /// 下降量
    public var descent: CGFloat = 0
    /// 宽度
    public var width: CGFloat = 0
    
    /// 用户信息
    public var userInfo: [AnyHashable: Any]?
    
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        ascent = CGFloat(aDecoder.decodeFloat(forKey: "ascent"))
        descent = CGFloat(aDecoder.decodeFloat(forKey: "descent"))
        width = CGFloat(aDecoder.decodeFloat(forKey: "width"))
        userInfo = aDecoder.decodeObject(forKey: "userInfo") as? [AnyHashable: Any]
    }
    
    // MARK: - NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(Float(ascent), forKey: "ascent")
        aCoder.encode(Float(descent), forKey: "descent")
        aCoder.encode(Float(width), forKey: "width")
        aCoder.encode(userInfo, forKey: "userInfo")
    }
    
    /// CoreText object
    public func ctRunDelegate() -> CTRunDelegate? {
        let extentBuffer = UnsafeMutablePointer<TextRunDelegate>.allocate(capacity: 1)
        extentBuffer.initialize(to: self)
        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateCurrentVersion, dealloc: { pointer in
            pointer.deallocate()
            
        }, getAscent: { pointer -> CGFloat in
            return pointer.assumingMemoryBound(to: TextRunDelegate.self).pointee.ascent
            
        }, getDescent: { pointer -> CGFloat in
            return pointer.assumingMemoryBound(to: TextRunDelegate.self).pointee.descent
            
        }, getWidth: { pointer -> CGFloat in
            return pointer.assumingMemoryBound(to: TextRunDelegate.self).pointee.width
            
        })
        return CTRunDelegateCreate(&callbacks, extentBuffer)
    }
    
    // MARK: - NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextRunDelegate()
        one.ascent = self.ascent
        one.descent = self.descent
        one.width = self.width
        one.userInfo = self.userInfo
        return one
    }
}
