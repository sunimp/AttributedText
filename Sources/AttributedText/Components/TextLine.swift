//
//  TextLine.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

/// 文本运行字形绘制模式
public enum TextRunGlyphDrawMode: Int {
    /// No rotate.
    case horizontal = 0
    /// Rotate vertical for single glyph.
    case verticalRotate = 1
    /// Rotate vertical for single glyph, and move the glyph to a better position,
    /// such as fullwidth punctuation.
    case verticalRotateMove = 2
}

/// A range in CTRun, used for vertical form.
public class TextRunGlyphRange: NSObject {
    public var glyphRangeInRun = NSRange(location: 0, length: 0)
    public var drawMode = TextRunGlyphDrawMode.horizontal
    
    /// 构造方法
    public init(range: NSRange, drawMode mode: TextRunGlyphDrawMode) {
        self.glyphRangeInRun = range
        self.drawMode = mode
        
        super.init()
    }
}

/// A range in CTRun, used for vertical form.
public class TextLine: NSObject {
    
    private var firstGlyphPos: CGFloat = 0
    
    /// line index
    public var index: Int = 0
    
    /// line row
    public var row: Int = 0
    
    /// Run rotate range
    public var verticalRotateRange: [[TextRunGlyphRange]]?
    
    /// string range
    public private(set) var range = NSRange(location: 0, length: 0)
    
    /// vertical form
    public private(set) var isVertical = false
    
    /// bounds (ascent + descent)
    public private(set) var bounds: CGRect = .zero
    
    /// bounds.size
    public var size: CGSize {
        return bounds.size
    }
    
    /// bounds.size.width
    public var width: CGFloat {
        return bounds.size.width
    }
    
    /// bounds.size.height
    public var height: CGFloat {
        return bounds.size.height
    }
    
    /// bounds.origin.y
    public var top: CGFloat {
        return bounds.minY
    }
    
    /// bounds.origin.y + bounds.size.height
    public var bottom: CGFloat {
        return bounds.maxY
    }
    
    /// bounds.origin.x
    public var left: CGFloat {
        return bounds.minX
    }
    
    /// bounds.origin.x + bounds.size.width
    public var right: CGFloat {
        return bounds.maxX
    }
    
    private var _position: CGPoint = .zero
    
    /// baseline position
    public var position: CGPoint {
        get {
            return _position
        }
        set {
            _position = newValue
            self.reloadBounds()
        }
    }
    
    /// line ascent
    public private(set) var ascent: CGFloat = 0
    
    /// line descent
    public private(set) var descent: CGFloat = 0
    
    /// line leading
    public private(set) var leading: CGFloat = 0
    
    /// line width
    public private(set) var lineWidth: CGFloat = 0
    
    public private(set) var trailingWhitespaceWidth: CGFloat = 0
    
    /// TextAttachment
    public private(set) var attachments: [TextAttachment]?
    
    /// NSRange
    public private(set) var attachmentRanges: [NSValue]?
    
    /// CGRect
    public private(set) var attachmentRects: [NSValue]?
    
    private var _ctLine: CTLine?
    /// CoreText line
    public private(set) var ctLine: CTLine? {
        get {
            return _ctLine
        }
        set {
            if _ctLine != newValue {
                _ctLine = newValue
                
                if let line = newValue {
                    lineWidth = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
                    let range: CFRange = CTLineGetStringRange(line)
                    self.range = NSRange(location: range.location, length: range.length)
                    if CTLineGetGlyphCount(line) > 0 {
                        let runs = CTLineGetGlyphRuns(line)
                        let pointer = CFArrayGetValueAtIndex(runs, 0)
                        // 获取 UnsafeRawPointer 指针中的内容，用 unsafeBitCast 方法
                        let run = unsafeBitCast(pointer, to: CTRun.self)
                        
                        var pos: CGPoint = .zero
                        CTRunGetPositions(run, CFRangeMake(0, 1), &pos)
                        firstGlyphPos = pos.x
                    } else {
                        firstGlyphPos = 0
                    }
                    trailingWhitespaceWidth = CGFloat(CTLineGetTrailingWhitespaceWidth(line))
                } else {
                    trailingWhitespaceWidth = 0
                    firstGlyphPos = trailingWhitespaceWidth
                    leading = firstGlyphPos
                    descent = leading
                    ascent = descent
                    lineWidth = ascent
                    self.range = NSRange(location: 0, length: 0)
                }
                reloadBounds()
            }
        }
    }
    
    /// 构造器
    override public init() {
        super.init()
    }
    
    /// 便利构造器
    public convenience init(ctLine: CTLine, position: CGPoint, vertical isVertical: Bool) {
        self.init()
        
        self.position = position
        self.isVertical = isVertical
        self.ctLine = ctLine
    }
    
    private func reloadBounds() {
        if isVertical {
            bounds = CGRect(x: position.x - descent, y: position.y, width: self.ascent + descent, height: lineWidth)
            bounds.origin.y += firstGlyphPos
        } else {
            bounds = CGRect(x: position.x, y: position.y - self.ascent, width: lineWidth, height: self.ascent + descent)
            bounds.origin.x += firstGlyphPos
        }
        self.attachments = nil
        self.attachmentRanges = nil
        self.attachmentRects = nil
        guard let ctLine = self.ctLine else {
            return
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        let runCount = CFArrayGetCount(runs)
        if runCount == 0 {
            return
        }
        var tmpAttachments = [TextAttachment]()
        var tmpAttachmentRanges: [NSValue] = []
        var tmpAttachmentRects: [NSValue] = []
        for runIndex in 0 ..< runCount {
            let pointer = CFArrayGetValueAtIndex(runs, runIndex)
            // 获取 UnsafeRawPointer 指针中的内容，用 unsafeBitCast 方法
            let run = unsafeBitCast(pointer, to: CTRun.self)
            let glyphCount: CFIndex = CTRunGetGlyphCount(run)
            if glyphCount == 0 {
                continue
            }
            let attrs = CTRunGetAttributes(run) as? [AnyHashable: Any]
            
            if let attachment = attrs?[TextAttribute.textAttachment] as? TextAttachment {
                var runPosition = CGPoint.zero
                CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition)
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                var runWidth: CGFloat = 0
                var runTypoBounds = CGRect.zero
                runWidth = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading))
                
                if isVertical {
                    (runPosition.x, runPosition.y) = (runPosition.y, runPosition.x)
                    runPosition.y = position.y + runPosition.y
                    runTypoBounds = CGRect(
                        x: position.x + runPosition.x - descent,
                        y: runPosition.y,
                        width: ascent + descent,
                        height: runWidth
                    )
                } else {
                    runPosition.x += position.x
                    runPosition.y = position.y - runPosition.y
                    runTypoBounds = CGRect(
                        x: runPosition.x,
                        y: runPosition.y - ascent,
                        width: runWidth,
                        height: ascent + descent
                    )
                }
                let cfRange: CFRange = CTRunGetStringRange(run)
                let runRange = NSRange(location: cfRange.location, length: cfRange.length)
                
                tmpAttachments.append(attachment)
                tmpAttachmentRanges.append(NSValue(range: runRange))
                tmpAttachmentRects.append(NSValue(cgRect: runTypoBounds))
            }
        }
        self.attachments = !tmpAttachments.isEmpty ? tmpAttachments : nil
        self.attachmentRanges = !tmpAttachmentRanges.isEmpty ? tmpAttachmentRanges : nil
        self.attachmentRects = !tmpAttachmentRects.isEmpty ? tmpAttachmentRects : nil
    }
}
extension TextLine {
    
    public override var description: String {
        var desc = ""
        let range = self.range
        desc += String(format: "<TextLine: %p> row: %zd range: %tu, %tu", self, row, range.location, range.length)
        desc += " position:\(NSCoder.string(for: position))"
        desc += " bounds:\(NSCoder.string(for: bounds))"
        return desc
    }
}
