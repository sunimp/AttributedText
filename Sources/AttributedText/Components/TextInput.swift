//
//  TextInput.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

/// Text position affinity.
///
/// For example, the offset appears after the last
/// character on a line is backward affinity, before the first character on
/// the following line is forward affinity.
public enum TextAffinity: Int {
    /// offset appears before the character
    case forward = 0
    /// offset appears after the character
    case backward = 1
}

/// A TextSelectionRect object encapsulates information about a selected range of
/// text in a text-displaying view.
///
/// TextSelectionRect has the same API as Apple's implementation in UITextView/UITextField,
/// so you can alse use it to interact with UITextView/UITextField.
public class TextSelectionRect: UITextSelectionRect, NSCopying {
    private var _rect = CGRect.zero
    override public var rect: CGRect {
        get {
            return _rect
        }
        set {
            _rect = newValue
        }
    }
    
    private var _writingDirection: NSWritingDirection = .natural
    override public var writingDirection: NSWritingDirection {
        get {
            return _writingDirection
        }
        set {
            _writingDirection = newValue
        }
    }
    
    private var _containsStart = false
    override public var containsStart: Bool {
        get {
            return _containsStart
        }
        set {
            _containsStart = newValue
        }
    }
    
    private var _containsEnd = false
    override public var containsEnd: Bool {
        get {
            return _containsEnd
        }
        set {
            _containsEnd = newValue
        }
    }
    
    private var _isVertical = false
    override public var isVertical: Bool {
        get {
            return _isVertical
        }
        set {
            _isVertical = newValue
        }
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextSelectionRect()
        one.rect = rect
        one.writingDirection = writingDirection
        one.containsStart = containsStart
        one.containsEnd = containsEnd
        one.isVertical = isVertical
        return one
    }
}

/// A TextPosition object represents a position in a text container; in other words,
/// it is an index into the backing string in a text-displaying view.
///
/// TextPosition has the same API as Apple's implementation in UITextView/UITextField,
/// so you can alse use it to interact with UITextView/UITextField.
public class TextPosition: UITextPosition, NSCopying {
    /// 偏移量
    public private(set) var offset: Int = 0
    /// 亲和性
    public private(set) var affinity: TextAffinity = .forward
    
    /// 构造方法
    override public init() {
        super.init()
    }
    
    /// 便捷构造方法
    public convenience init(offset: Int, affinity: TextAffinity = .forward) {
        self.init()
        
        self.offset = offset
        self.affinity = affinity
    }
    
    /// 比较
    @objc
    public func compare(_ other: TextPosition?) -> ComparisonResult {
        guard let other = other else {
            return .orderedAscending
        }
        if offset < other.offset {
            return .orderedAscending
        }
        if offset > other.offset {
            return .orderedDescending
        }
        if affinity == .backward, other.affinity == .forward {
            return .orderedAscending
        }
        if affinity == .forward, other.affinity == .backward {
            return .orderedDescending
        }
        return .orderedSame
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let position = TextPosition(offset: offset, affinity: affinity)
        return position
    }
    
    public func hash() -> Int {
        return offset * 2 + (affinity == TextAffinity.forward ? 1 : 0)
    }
    
    public func isEqual(_ object: TextPosition?) -> Bool {
        guard let object = object else {
            return false
        }
        return offset == object.offset && affinity == object.affinity
    }
}

/// A TextRange object represents a range of characters in a text container; in other words,
/// it identifies a starting index and an ending index in string backing a text-displaying view.
///
/// TextRange has the same API as Apple's implementation in UITextView/UITextField,
/// so you can alse use it to interact with UITextView/UITextField.
public class TextRange: UITextRange, NSCopying {
    private var _start = TextPosition(offset: 0)
    override public var start: TextPosition {
        get {
            return _start
        }
        set {
            _start = newValue
        }
    }
    
    private var _end = TextPosition(offset: 0)
    override public var end: TextPosition {
        get {
            return _end
        }
        set {
            _end = newValue
        }
    }
    
    override public var isEmpty: Bool {
        return _start.offset == _end.offset
    }
    
    public var nsRange: NSRange {
        return NSRange(location: _start.offset, length: _end.offset - _start.offset)
    }
    
    override public var hash: Int {
        return MemoryLayout<Int>.size == 8 ? Int(CFSwapInt64(UInt64(start.hash))) :
        Int(CFSwapInt32(UInt32(start.hash))) + end.hash
    }
    
    /// 构造方法
    override public init() {
        super.init()
    }
    
    /// 便捷构造方法
    public convenience init(range: NSRange, affinity: TextAffinity = .forward) {
        let start = TextPosition(offset: range.location, affinity: affinity)
        let end = TextPosition(offset: range.location + range.length, affinity: affinity)
        self.init(start: start, end: end)
    }
    
    /// 便捷构造方法
    public convenience init(start: TextPosition, end: TextPosition) {
        self.init()
        if start.compare(end) == .orderedDescending {
            self._start = end
            self._end = start
        } else {
            self._start = start
            self._end = end
        }
    }
    
    public static func `default`() -> TextRange {
        return TextRange()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return TextRange(start: self.start, end: self.end)
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Self else {
            return false
        }
        return start.isEqual(object.start) && end.isEqual(object.end)
    }
}

extension TextPosition {
    public override var description: String {
        return """
        <\(type(of: self)): \(String(format: "%p", self))> \
        (\(offset)\(affinity == TextAffinity.forward ? "F" : "B"))
        """
    }
}

extension TextRange {
    public override var description: String {
        return """
        <\(type(of: self)): \(String(format: "%p", self))> \
        (\(_start.offset), \(end.offset - start.offset))\
        \(end.affinity == .forward ? "F" : "B")
        """
    }
}
