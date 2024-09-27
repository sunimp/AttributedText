//
//  TextLayout.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

// swiftlint:disable file_length
private struct TextDecorationType: OptionSet {
    static let underline = Self(rawValue: 1 << 0)
    static let strikethrough = Self(rawValue: 1 << 1)
    
    let rawValue: Int
}

private struct TextBorderType: OptionSet {
    static let backgound = Self(rawValue: 1 << 0)
    static let normal = Self(rawValue: 1 << 1)
    
    let rawValue: Int
}

private struct RowEdge {
    var head: CGFloat = 0
    var foot: CGFloat = 0
}

// swiftlint:disable type_body_length
/// The TextContainer class defines a region in which text is laid out.
///  TextLayout class uses one or more TextContainer objects to generate layouts.
///
///  A TextContainer defines rectangular regions (`size` and `insets`) or
///  nonrectangular shapes (`path`), and you can define exclusion paths inside the
///  text container's bounding rectangle so that text flows around the exclusion
///  path as it is laid out.
///
///  All methods in this class is thread-safe.
///
///  Example:
///
///     ┌─────────────────────────────┐ <--------- container
///     │                             │
///     │    Lorem Ipsum is simply  <------------ container insets
///     │    sheetsc      sunknown    │
///     │    print         askmake    │
///     │    types        <----------------------- container exclusion path
///     │    asdfas         adfasd    │
///     │    asdfasdfa   asdfasdfa    │
///     │    asdfasdfasdfasdfasdfa    │
///     │                             │
///     └─────────────────────────────┘
///
public class TextContainer: NSObject, NSCoding, NSCopying, NSSecureCoding {
    // MARK: - NSSecureCoding
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    /// The max text container size in layout.
    public static let maxSize = CGSize(width: 0x100000, height: 0x100000)
    
    private var _size: CGSize = .zero
    /// The constrained size. (if the size is larger than TextContainerMaxSize, it will be clipped)
    public var size: CGSize {
        get {
            lock.wait()
            let size = _size
            lock.signal()
            return size
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            if _path == nil {
                _size = newValue.clipped()
            }
            lock.signal()
        }
    }
    
    private var _insets: UIEdgeInsets = .zero
    /// The insets for constrained size. The inset value should not be negative. Default is UIEdgeInsetsZero.
    public var insets: UIEdgeInsets {
        get {
            lock.wait()
            let insets = _insets
            lock.signal()
            return insets
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            if _path == nil {
                var insets = newValue
                if insets.top < 0 { insets.top = 0 }
                if insets.left < 0 { insets.left = 0 }
                if insets.bottom < 0 { insets.bottom = 0 }
                if insets.right < 0 { insets.right = 0 }
                _insets = insets
            }
            lock.signal()
        }
    }
    
    private var _path: UIBezierPath?
    /// Custom constrained path. Set this property to ignore `size` and `insets`. Default is nil.
    public var path: UIBezierPath? {
        get {
            lock.wait()
            let path = _path
            lock.signal()
            return path
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _path = newValue?.copy() as? UIBezierPath
            if let path = _path {
                let bounds = path.bounds
                var size = bounds.size
                var insets: UIEdgeInsets = .zero
                if bounds.origin.x < 0 { size.width += bounds.origin.x }
                if bounds.origin.x > 0 { insets.left = bounds.origin.x }
                if bounds.origin.y < 0 { size.height += bounds.origin.y }
                if bounds.origin.y > 0 { insets.top = bounds.origin.y }
                _size = size
                _insets = insets
            }
            lock.signal()
        }
    }
    
    private var _exclusionPaths: [UIBezierPath]?
    /// An array of `UIBezierPath` for path exclusion. Default is nil.
    public var exclusionPaths: [UIBezierPath]? {
        get {
            lock.wait()
            let paths = _exclusionPaths
            lock.signal()
            return paths
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _exclusionPaths = newValue
            lock.signal()
        }
    }
    
    private var _pathLineWidth: CGFloat = 0
    /// Path line width. Default is 0;
    public var pathLineWidth: CGFloat {
        get {
            lock.wait()
            let width = _pathLineWidth
            lock.signal()
            return width
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _pathLineWidth = newValue
            lock.signal()
        }
    }
    
    private var _isPathFillEvenOdd = true
    /// The Even/Odd Fill Path
    ///
    /// `true`: (PathFillEvenOdd) Text is filled in the area that would be painted
    /// if the path were given to CGContextEOFillPath.
    ///
    /// `false`: (PathFillWindingNumber) Text is fill in the area that would be painted
    /// if the path were given to CGContextFillPath.
    ///
    /// Default is `true`
    public var isPathFillEvenOdd: Bool {
        get {
            lock.wait()
            let isOdd = _isPathFillEvenOdd
            lock.signal()
            return isOdd
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _isPathFillEvenOdd = newValue
            lock.signal()
        }
    }
    
    private var _isVerticalForm = false
    /// Whether the text is vertical form (may used for CJK text layout). Default is NO.
    public var isVerticalForm: Bool {
        get {
            lock.wait()
            let isVertical = _isVerticalForm
            lock.signal()
            return isVertical
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _isVerticalForm = newValue
            lock.signal()
        }
    }
    
    private var _maximumNumberOfRows: Int = 0
    /// Maximum number of rows, 0 means no limit. Default is 0.
    public var maximumNumberOfRows: Int {
        get {
            lock.wait()
            let rows = _maximumNumberOfRows
            lock.signal()
            return rows
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _maximumNumberOfRows = newValue
            lock.signal()
        }
    }
    
    private var _truncationType = TextTruncationType.none
    /// The line truncation type, default is none.
    public var truncationType: TextTruncationType {
        get {
            lock.wait()
            let type = _truncationType
            lock.signal()
            return type
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _truncationType = newValue
            lock.signal()
        }
    }
    
    private var _truncationToken: NSAttributedString?
    /// The truncation token. If nil, the layout will use "…" instead. Default is nil.
    public var truncationToken: NSAttributedString? {
        get {
            lock.wait()
            let token = _truncationToken
            lock.signal()
            return token
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _truncationToken = newValue?.copy() as? NSAttributedString
            lock.signal()
        }
    }
    
    private weak var _linePositionModifier: TextLinePositionModifier?
    /// This modifier is applied to the lines before the layout is completed,
    /// give you a chance to modify the line position. Default is nil.
    public weak var linePositionModifier: TextLinePositionModifier? {
        get {
            lock.wait()
            let modifier = _linePositionModifier
            lock.signal()
            return modifier
        }
        set {
            if isReadonly {
                print("⚠️ Cannot change the property of the 'container' in 'TextLayout'.")
            }
            lock.wait()
            _linePositionModifier = newValue?.copy() as? TextLinePositionModifier
            lock.signal()
        }
    }
    
    /// used only in TextLayout.implementation
    fileprivate var isReadonly = false
    fileprivate lazy var lock: DispatchSemaphore = .init(value: 1)
    
    /// 构造方法
    override public init() {
        super.init()
    }
    
    /// Creates a container with the specified size. @param size The size.
    public convenience init(size: CGSize, insets: UIEdgeInsets = .zero) {
        self.init()
        
        self.size = size.clipped()
        self.insets = insets
    }
    
    /// Creates a container with the specified path. @param path The path.
    public convenience init(path: UIBezierPath?) {
        self.init()
        
        self.path = path
    }
    
    /// NSCoding
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        self._size = aDecoder.decodeCGSize(forKey: "size")
        self._insets = aDecoder.decodeUIEdgeInsets(forKey: "insets")
        self._path = aDecoder.decodeObject(forKey: "path") as? UIBezierPath
        self._exclusionPaths = aDecoder.decodeObject(forKey: "exclusionPaths") as? [UIBezierPath]
        self._isPathFillEvenOdd = aDecoder.decodeBool(forKey: "pathFillEvenOdd")
        self._pathLineWidth = CGFloat(aDecoder.decodeFloat(forKey: "pathLineWidth"))
        self._isVerticalForm = aDecoder.decodeBool(forKey: "isVerticalForm")
        self._maximumNumberOfRows = aDecoder.decodeInteger(forKey: "maximumNumberOfRows")
        if let type = TextTruncationType(rawValue: aDecoder.decodeInteger(forKey: "truncationType")) {
            self._truncationType = type
        }
        self._truncationToken = aDecoder.decodeObject(forKey: "truncationToken") as? NSAttributedString
        self._linePositionModifier = aDecoder.decodeObject(forKey: "linePositionModifier") as? TextLinePositionModifier
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextContainer()
        lock.wait()
        one._size = _size
        one._insets = _insets
        one._path = _path
        one._exclusionPaths = _exclusionPaths
        one._isPathFillEvenOdd = _isPathFillEvenOdd
        one._pathLineWidth = _pathLineWidth
        one._isVerticalForm = _isVerticalForm
        one._maximumNumberOfRows = _maximumNumberOfRows
        one._truncationType = _truncationType
        one._truncationToken = _truncationToken?.copy() as? NSAttributedString
        one._linePositionModifier = _linePositionModifier
        lock.signal()
        return one
    }
    
    override public func mutableCopy() -> Any {
        return copy()
    }
    
    // MARK: - NSCoding
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(_size, forKey: "size")
        aCoder.encode(_insets, forKey: "insets")
        aCoder.encode(_path, forKey: "path")
        aCoder.encode(_exclusionPaths, forKey: "exclusionPaths")
        aCoder.encode(_isPathFillEvenOdd, forKey: "pathFillEvenOdd")
        aCoder.encode(Float(_pathLineWidth), forKey: "pathLineWidth")
        aCoder.encode(_isVerticalForm, forKey: "isVerticalForm")
        aCoder.encode(_maximumNumberOfRows, forKey: "maximumNumberOfRows")
        aCoder.encode(_truncationType.rawValue, forKey: "truncationType")
        aCoder.encode(_truncationToken, forKey: "truncationToken")
        if _linePositionModifier?.responds(to: #selector(encode(with:))) ?? false {
            aCoder.encode(linePositionModifier, forKey: "linePositionModifier")
        }
    }
}

/// The TextLinePositionModifier protocol declares the required method to modify
/// the line position in text layout progress. See `TextLinePositionSimpleModifier` for example.
public protocol TextLinePositionModifier: NSObjectProtocol, NSCopying {
    /// This method will called before layout is completed. The method should be thread-safe.
    /// - Parameters:
    ///     - lines: An array of TextLine.
    ///     - text: The full text.
    ///     - container: The layout container.
    func modifyLines(_ lines: [TextLine]?, fromText text: NSAttributedString?, in container: TextContainer?)
}

/**
 A simple implementation of `TextLinePositionModifier`. It can fix each line's position
 to a specified value, lets each line of height be the same.
 */
public class TextLinePositionSimpleModifier: NSObject, TextLinePositionModifier {
    /// The fixed line height (distance between two baseline).
    public var fixedLineHeight: CGFloat = 0
    
    public func modifyLines(_ lines: [TextLine]?, fromText text: NSAttributedString?, in container: TextContainer?) {
        guard let lines = lines, let container = container else {
            return
        }
        
        let maxCount = lines.count
        
        if container.isVerticalForm {
            for index in 0..<maxCount {
                let line = lines[index]
                var pos = line.position
                pos.x = container.size.width -
                    container.insets.right -
                    CGFloat(line.row) * fixedLineHeight -
                    fixedLineHeight * 0.9
                line.position = pos
            }
        } else {
            for index in 0..<maxCount {
                let line = lines[index]
                var pos = line.position
                pos.y = CGFloat(line.row) * fixedLineHeight + fixedLineHeight * 0.9 + container.insets.top
                line.position = pos
            }
        }
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let one = TextLinePositionSimpleModifier()
        one.fixedLineHeight = fixedLineHeight
        return one
    }
}

/// TextLayout class is a readonly class stores text layout result.
///  All the property in this class is readonly, and should not be changed.
///  The methods in this class is thread-safe (except some of the draw methods).
///
///  example: (layout with a circle exclusion path)
///
///     ┌──────────────────────────┐  <------ container
///     │ [--------Line0--------]  │  <- Row0
///     │ [--------Line1--------]  │  <- Row1
///     │ [-Line2-]     [-Line3-]  │  <- Row2
///     │ [-Line4]       [Line5-]  │  <- Row3
///     │ [-Line6-]     [-Line7-]  │  <- Row4
///     │ [--------Line8--------]  │  <- Row5
///     │ [--------Line9--------]  │  <- Row6
///     └──────────────────────────┘
public class TextLayout: NSObject, NSCoding, NSCopying {
    // MARK: - Text layout attributes
   
    /// The text container
    public private(set) lazy var container = TextContainer()
    /// The full text
    public private(set) var text: NSAttributedString?
    /// The text range in full text
    public private(set) var range = NSRange(location: 0, length: 0)
    /// CTFrameSetter
    public private(set) lazy var frameSetter = CTFramesetterCreateWithAttributedString(NSAttributedString(string: ""))
    /// CTFrame
    public private(set) lazy var frame: CTFrame = {
        let ctSetter = CTFramesetterCreateWithAttributedString(NSAttributedString(string: ""))
        let ctFrame = CTFramesetterCreateFrame(
            ctSetter,
            NSRange(location: 0, length: 0).cfRange(),
            UIBezierPath().cgPath,
            [AnyHashable: Any]() as CFDictionary
        )
        return ctFrame
    }()

    /// Array of `TextLine`, no truncated
    public private(set) lazy var lines: [TextLine] = []
    /// TextLine with truncated token, or nil
    public private(set) var truncatedLine: TextLine?
    /// Array of `TextAttachment`
    public private(set) var attachments: [TextAttachment]?
    /// Array of NSRange(wrapped by NSValue) in text
    public private(set) var attachmentRanges: [NSValue]?
    /// Array of CGRect(wrapped by NSValue) in container
    public private(set) var attachmentRects: [NSValue]?
    /// Set of Attachment (UIImage/UIView/CALayer)
    public private(set) var attachmentContentsSet: Set<AnyHashable>?
    /// Number of rows
    public private(set) var rowCount: Int = 0
    /// Visible text range
    public private(set) lazy var visibleRange = NSRange(location: 0, length: 0)
    /// Bounding rect (glyphs)
    public private(set) var textBoundingRect = CGRect.zero
    /// Bounding size (glyphs and insets, ceil to pixel)
    public private(set) var textBoundingSize = CGSize.zero
    /// Has highlight attribute
    public private(set) var containsHighlight = false
    /// Has block border attribute
    public private(set) var needDrawBlockBorder = false
    
    /// Has background border attribute
    public private(set) var needDrawBackgroundBorder = false
    /// Has shadow attribute
    public private(set) var needDrawShadow = false
    /// Has underline attribute
    public private(set) var needDrawUnderline = false
    /// Has visible text
    public private(set) var needDrawText = false
    /// Has attachment attribute
    public private(set) var needDrawAttachment = false
    /// Has inner shadow attribute
    public private(set) var needDrawInnerShadow = false
    /// Has strickthrough attribute
    public private(set) var needDrawStrikethrough = false
    /// Has border attribute
    public private(set) var needDrawBorder = false
    
    private var lineRowsIndex: UnsafeMutablePointer<Int>?
    /// top-left origin
    private var lineRowsEdge: UnsafeMutablePointer<RowEdge>?
    
    override private init() {
        super.init()
    }
    
    private convenience init(container: TextContainer) {
        self.init()
        self.container = container
    }
    
    // MARK: - Generate text layout

    /// Generate a layout with the given container size and text.
    ///
    /// - Parameters:
    ///     - containerSize: The text container's size
    ///     - text: The text (if nil, returns nil).
    /// - Returns: A new layout, or nil when an error occurs.
    public convenience init?(containerSize: CGSize, text: NSAttributedString?) {
        self.init(container: TextContainer(size: containerSize), text: text)
    }
    
    /// Generate a layout with the given container and text.
    ///
    /// - Parameters:
    ///     - container: The text container (if nil, returns nil).
    ///     - text: The text (if nil, returns nil).
    /// - Returns: A new layout, or nil when an error occurs.
    public convenience init?(container: TextContainer?, text: NSAttributedString?) {
        self.init(container: container, text: text, range: NSRange(location: 0, length: text?.length ?? 0))
    }
    
    // swiftlint:disable function_body_length
    /// Generate a layout with the given container and text.
    ///
    /// - Parameters:
    ///     - container: The text container (if nil, returns nil).
    ///     - text: The text (if nil, returns nil).
    ///     - range: The text range (if out of range, returns nil). If the
    ///     length of the range is 0, it means the length is no limit.
    /// - Returns: A new layout, or nil when an error occurs.
    public convenience init?(container: TextContainer?, text: NSAttributedString?, range: NSRange) {
        guard let textCopy = text?.mutableCopy() as? NSMutableAttributedString,
              let containerCopy = container?.copy() as? TextContainer
        else {
            return nil
        }
        if range.location + range.length > textCopy.length {
            return nil
        }
        self.init(container: containerCopy)
        
        var cgPath: CGPath
        var cgPathBox = CGRect.zero
        var isVerticalForm = false
        var rowMaySeparated = false
        var frameAttrs = [AnyHashable: AnyObject]()
        
        var ctLines: CFArray?
        var lineOrigins: UnsafeMutablePointer<CGPoint>?
        var tmpLineCount = 0
        var tmpLines: [TextLine] = []
        var tmpAttachments: [TextAttachment]?
        var tmpAttachmentRanges: [NSValue]?
        var tmpAttachmentRects: [NSValue]?
        var tmpAttachmentContentsSet: Set<AnyHashable>?
        var needTruncation = false
        var tmpTruncationToken: NSAttributedString?
        var tmpTruncatedLine: TextLine?
        var tmpLineRowsEdge: UnsafeMutablePointer<RowEdge>?
        var tmpLineRowsIndex: UnsafeMutablePointer<Int>?
        
        var maximumNumberOfRows = 0
        var constraintSizeIsExtended = false
        var constraintRectBeforeExtended = CGRect.zero
        
        containerCopy.isReadonly = true
        maximumNumberOfRows = containerCopy.maximumNumberOfRows

        self.text = text
        self.container = containerCopy
        self.range = range
        isVerticalForm = containerCopy.isVerticalForm
        // set cgPath and cgPathBox
        if containerCopy.path == nil, (containerCopy.exclusionPaths?.count ?? 0) == 0 {
            if containerCopy.size.width <= 0 || containerCopy.size.height <= 0 {
                lineOrigins?.deallocate()
                tmpLineRowsEdge?.deallocate()
                tmpLineRowsIndex?.deallocate()
                return nil
            }
            var rect = CGRect.zero
            rect.size = containerCopy.size
            constraintSizeIsExtended = true
            constraintRectBeforeExtended = rect.inset(by: containerCopy.insets)
            constraintRectBeforeExtended = constraintRectBeforeExtended.standardized
            if containerCopy.isVerticalForm {
                rect.size.width = TextContainer.maxSize.width
            } else {
                rect.size.height = TextContainer.maxSize.height
            }
            rect = rect.inset(by: containerCopy.insets)
            rect = rect.standardized
            cgPathBox = rect
            rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
            cgPath = CGPath(rect: rect, transform: nil) // let CGPathIsRect() returns true
            
        } else if let path = containerCopy.path,
                  path.cgPath.isRect(&cgPathBox),
                  (containerCopy.exclusionPaths?.isEmpty ?? true) {
            let rect: CGRect = cgPathBox.applying(CGAffineTransform(scaleX: 1, y: -1))
            cgPath = CGPath(rect: rect, transform: nil) // let CGPathIsRect() returns true
            
        } else {
            rowMaySeparated = true
            var path: CGMutablePath
            if let containerPath = containerCopy.path {
                path = containerPath.cgPath.mutableCopy() ?? CGMutablePath()
            } else {
                var rect: CGRect = .zero
                rect.size = containerCopy.size
                rect = rect.inset(by: containerCopy.insets)
                let rectPath = CGPath(rect: rect, transform: nil)
                path = rectPath.mutableCopy() ?? CGMutablePath()
            }
            if let exclusionPaths = self.container.exclusionPaths {
                for onePath in exclusionPaths {
                    path.addPath(onePath.cgPath, transform: .identity)
                }
            }
            cgPathBox = path.boundingBoxOfPath
            var transform = CGAffineTransform(scaleX: 1, y: -1)
            if let transPath = path.mutableCopy(using: &transform) {
                path = transPath
            }
            cgPath = path
        }
        
        // swiftlint:disable legacy_objc_type
        // frame setter config
        if containerCopy.isPathFillEvenOdd == false {
            frameAttrs[kCTFramePathFillRuleAttributeName] = NSNumber(
                value: CTFramePathFillRule.windingNumber.rawValue
            )
        }
        if containerCopy.pathLineWidth > 0 {
            frameAttrs[kCTFramePathWidthAttributeName] = NSNumber(
                value: Float(containerCopy.pathLineWidth)
            )
        }
        if containerCopy.isVerticalForm == true {
            frameAttrs[kCTFrameProgressionAttributeName] = NSNumber(
                value: CTFrameProgression.rightToLeft.rawValue
            )
        }
        // create CoreText objects
        let ctSetter = CTFramesetterCreateWithAttributedString(textCopy)
        let ctFrame = CTFramesetterCreateFrame(ctSetter, range.cfRange(), cgPath, frameAttrs as CFDictionary)
        
        ctLines = CTFrameGetLines(ctFrame)
        tmpLineCount = CFArrayGetCount(ctLines)
        if tmpLineCount > 0 {
            lineOrigins = UnsafeMutablePointer<CGPoint>.allocate(capacity: tmpLineCount)
            if let lineOrigins {
                CTFrameGetLineOrigins(ctFrame, CFRangeMake(0, tmpLineCount), lineOrigins)
            }
        }
        guard let lineOrigins = lineOrigins else {
            return nil
        }
        // swiftlint:enable legacy_objc_type
        
        var tmpTextBoundingRect = CGRect.zero
        var tmpTextBoundingSize = CGSize.zero
        var rowIdx: Int = -1
        var tmpRowCount = 0
        var lastRect = CGRect(x: 0, y: CGFloat(-Float.greatestFiniteMagnitude), width: 0, height: 0)
        var lastPosition = CGPoint(x: 0, y: CGFloat(-Float.greatestFiniteMagnitude))
        if isVerticalForm {
            lastRect = CGRect(x: CGFloat(Float.greatestFiniteMagnitude), y: 0, width: 0, height: 0)
            lastPosition = CGPoint(x: CGFloat(Float.greatestFiniteMagnitude), y: 0)
        }
        
        // calculate line frame
        var lineCurrentIdx = 0
        for index in 0..<tmpLineCount {
            let ctLine = unsafeBitCast(CFArrayGetValueAtIndex(ctLines, index), to: CTLine.self)
            let ctRuns = CTLineGetGlyphRuns(ctLine)
            if CFArrayGetCount(ctRuns) == 0 {
                continue
            }
            // CoreText coordinate system
            let ctLineOrigin: CGPoint = lineOrigins[index]
            // UIKit coordinate system
            var position = CGPoint.zero
            position.x = cgPathBox.origin.x + ctLineOrigin.x
            position.y = cgPathBox.size.height + cgPathBox.origin.y - ctLineOrigin.y
            let line = TextLine(ctLine: ctLine, position: position, vertical: isVerticalForm)
            let rect: CGRect = line.bounds
            if constraintSizeIsExtended {
                if isVerticalForm {
                    if rect.origin.x + rect.size.width >
                        constraintRectBeforeExtended.origin.x + constraintRectBeforeExtended.size.width {
                        break
                    }
                } else {
                    if rect.origin.y + rect.size.height >
                        constraintRectBeforeExtended.origin.y + constraintRectBeforeExtended.size.height {
                        break
                    }
                }
            }
            
            var newRow = true
            if rowMaySeparated, position.x != lastPosition.x {
                if isVerticalForm {
                    if rect.size.width > lastRect.size.width {
                        if rect.origin.x > lastPosition.x, lastPosition.x > rect.origin.x - rect.size.width {
                            newRow = false
                        }
                    } else {
                        if lastRect.origin.x > position.x, position.x > lastRect.origin.x - lastRect.size.width {
                            newRow = false
                        }
                    }
                } else {
                    if rect.size.height > lastRect.size.height {
                        if rect.origin.y < lastPosition.y, lastPosition.y < rect.origin.y + rect.size.height {
                            newRow = false
                        }
                    } else {
                        if lastRect.origin.y < position.y, position.y < lastRect.origin.y + lastRect.size.height {
                            newRow = false
                        }
                    }
                }
            }
            if newRow {
                rowIdx += 1
            }
            lastRect = rect
            lastPosition = position
            
            line.index = lineCurrentIdx
            line.row = rowIdx
            tmpLines.append(line)
            tmpRowCount = rowIdx + 1
            lineCurrentIdx += 1
            if index == 0 {
                tmpTextBoundingRect = rect
            } else {
                if maximumNumberOfRows == 0 || rowIdx < maximumNumberOfRows {
                    tmpTextBoundingRect = tmpTextBoundingRect.union(rect)
                }
            }
        }
        
        if tmpRowCount > 0 {
            if maximumNumberOfRows > 0 {
                if tmpRowCount > maximumNumberOfRows {
                    needTruncation = true
                    tmpRowCount = maximumNumberOfRows
                    repeat {
                        guard let line = tmpLines.last else {
                            break
                        }
                        if line.row < tmpRowCount {
                            break
                        }
                        tmpLines.removeLast()
                    } while true
                }
            }
            if !needTruncation,
               let lastLine = tmpLines.last,
               lastLine.range.location + lastLine.range.length < (text?.length ?? textCopy.length) {
                needTruncation = true
            }
            // Give user a chance to modify the line's position.
            if let modifier = containerCopy.linePositionModifier {
                modifier.modifyLines(tmpLines, fromText: text, in: containerCopy)
                tmpTextBoundingRect = CGRect.zero
                var indexi = 0
                let maxCount = tmpLines.count
                while indexi < maxCount {
                    let line = tmpLines[indexi]
                    if indexi == 0 {
                        tmpTextBoundingRect = line.bounds
                    } else {
                        tmpTextBoundingRect = tmpTextBoundingRect.union(line.bounds)
                    }
                    indexi += 1
                }
            }
            tmpLineRowsEdge = UnsafeMutablePointer<RowEdge>.allocate(capacity: tmpRowCount)
            tmpLineRowsIndex = UnsafeMutablePointer<Int>.allocate(capacity: tmpRowCount)
            guard let tmpLineRowsEdge = tmpLineRowsEdge, let tmpLineRowsIndex = tmpLineRowsIndex else {
                return
            }
            
            var lastRowIdx: Int = -1
            var lastHead: CGFloat = 0
            var lastFoot: CGFloat = 0
            
            var lineIndex = 0
            let maxCount = tmpLines.count
            while lineIndex < maxCount {
                let line = tmpLines[lineIndex]
                let rect = line.bounds
                if line.row != lastRowIdx {
                    if lastRowIdx >= 0 {
                        tmpLineRowsEdge[lastRowIdx] = RowEdge(head: lastHead, foot: lastFoot)
                    }
                    lastRowIdx = line.row
                    tmpLineRowsIndex[lastRowIdx] = lineIndex
                    if isVerticalForm {
                        lastHead = rect.origin.x + rect.size.width
                        lastFoot = lastHead - rect.size.width
                    } else {
                        lastHead = rect.origin.y
                        lastFoot = lastHead + rect.size.height
                    }
                } else {
                    if isVerticalForm {
                        lastHead = max(lastHead, rect.origin.x + rect.size.width)
                        lastFoot = min(lastFoot, rect.origin.x)
                    } else {
                        lastHead = min(lastHead, rect.origin.y)
                        lastFoot = max(lastFoot, rect.origin.y + rect.size.height)
                    }
                }
                lineIndex += 1
            }
            
            tmpLineRowsEdge[lastRowIdx] = RowEdge(head: lastHead, foot: lastFoot)
            
            for index in 1..<tmpRowCount {
                let v0: RowEdge = tmpLineRowsEdge[index - 1]
                let v1: RowEdge = tmpLineRowsEdge[index]
                let tmp = (v0.foot + v1.head) * 0.5
                tmpLineRowsEdge[index].head = tmp
                tmpLineRowsEdge[index - 1].foot = tmp
            }
        }
        
        do {
            // calculate bounding size
            var rect: CGRect = tmpTextBoundingRect
            if containerCopy.path != nil {
                if containerCopy.pathLineWidth > 0 {
                    let inset: CGFloat = containerCopy.pathLineWidth / 2
                    rect = rect.insetBy(dx: -inset, dy: -inset)
                }
            } else {
                rect = rect.inset(by: containerCopy.insets.inverted())
            }
            rect = rect.standardized
            var size: CGSize = rect.size
            if containerCopy.isVerticalForm {
                size.width += containerCopy.size.width - (rect.origin.x + rect.size.width)
            } else {
                size.width += rect.origin.x
            }
            size.height += rect.origin.y
            if size.width < 0 {
                size.width = 0
            }
            if size.height < 0 {
                size.height = 0
            }
            size.width = ceil(size.width)
            size.height = ceil(size.height)
            tmpTextBoundingSize = size
        }
        
        var tmpVisibleRange = CTFrameGetVisibleStringRange(ctFrame).nsRange()
        if needTruncation, let lastLine = tmpLines.last {
            let lastRange = lastLine.range
            tmpVisibleRange.length = lastRange.location + lastRange.length - tmpVisibleRange.location
            
            // create truncated line
            if containerCopy.truncationType != .none {
                var truncationTokenLine: CTLine?
                if let token = containerCopy.truncationToken {
                    tmpTruncationToken = token
                    truncationTokenLine = CTLineCreateWithAttributedString(token as CFAttributedString)
                } else if let ctLine = lastLine.ctLine {
                    let runs = CTLineGetGlyphRuns(ctLine)
                    let runCount: Int = CFArrayGetCount(runs)
                    var attrs: [NSAttributedString.Key: Any] = [:]
                    if runCount > 0 {
                        let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runCount - 1), to: CTRun.self)
                        if let tmpAttrs = CTRunGetAttributes(run) as? [NSAttributedString.Key: Any] {
                            attrs = tmpAttrs
                        }
                        
                        for key in NSMutableAttributedString.allDiscontinuousAttributeKeys() {
                            attrs.removeValue(forKey: key)
                        }
                        
                        // swiftlint:disable:next force_cast
                        var font = attrs[kCTFontAttributeName as NSAttributedString.Key] as! CTFont?
                        let fontSize: CGFloat = {
                            if let font = font {
                                return CTFontGetSize(font)
                            }
                            return 12.0
                        }()
                        let uiFont = UIFont.systemFont(ofSize: fontSize * 0.9)
                        font = CTFontCreateWithName(uiFont.fontName as CFString, uiFont.pointSize, nil)
                        if font != nil {
                            attrs[kCTFontAttributeName as NSAttributedString.Key] = font
                        }
                        // swiftlint:disable:next force_cast
                        let color = attrs[kCTForegroundColorAttributeName as NSAttributedString.Key] as! CGColor?
                        if let color = color, CFGetTypeID(color) == CGColor.typeID, color.alpha == 0 {
                            // ignore clear color
                            attrs.removeValue(forKey: kCTForegroundColorAttributeName as NSAttributedString.Key)
                        }
                    }
                    let token = NSAttributedString(string: TextAttribute.textTruncationToken, attributes: attrs)
                    tmpTruncationToken = token
                    truncationTokenLine = CTLineCreateWithAttributedString(token as CFAttributedString)
                }
                
                if let tokenLine = truncationTokenLine, let token = tmpTruncationToken {
                    var type: CTLineTruncationType = .end
                    if containerCopy.truncationType == TextTruncationType.start {
                        type = .start
                    } else if containerCopy.truncationType == TextTruncationType.middle {
                        type = .middle
                    }
                    let lastLineText = textCopy.attributedSubstring(from: lastLine.range) as? NSMutableAttributedString
                    lastLineText?.append(token)
                    if let lastLineText = lastLineText {
                        let ctLastLineExtend = CTLineCreateWithAttributedString(lastLineText as CFAttributedString)
                        
                        var truncatedWidth: CGFloat = lastLine.width
                        var cgPathRect = CGRect.zero
                        if cgPath.isRect(&cgPathRect) {
                            if isVerticalForm {
                                truncatedWidth = cgPathRect.size.height
                            } else {
                                truncatedWidth = cgPathRect.size.width
                            }
                        }
                        
                        if let ctTruncatedLine = CTLineCreateTruncatedLine(
                            ctLastLineExtend,
                            Double(truncatedWidth),
                            type,
                            tokenLine
                        ) {
                            tmpTruncatedLine = TextLine(
                                ctLine: ctTruncatedLine,
                                position: lastLine.position,
                                vertical: isVerticalForm
                            )
                            tmpTruncatedLine?.index = lastLine.index
                            tmpTruncatedLine?.row = lastLine.row
                        }
                    }
                }
            }
        }
        
        if isVerticalForm {
            let rotateCharset = TextUtilities.verticalFormRotateCharacterSet
            let rotateMoveCharset = TextUtilities.verticalFormRotateAndMoveCharacterSet
            let lineBlock: ((TextLine?) -> Void) = { line in
                guard let ctLine = line?.ctLine else {
                    return
                }
                let runs = CTLineGetGlyphRuns(ctLine)
                let runCount: Int = CFArrayGetCount(runs)
                if runCount == 0 {
                    return
                }
                line?.verticalRotateRange = [[TextRunGlyphRange]]()
                for index in 0..<runCount {
                    let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, index), to: CTRun.self)
                    var runRanges = [TextRunGlyphRange]()
                    let glyphCount: Int = CTRunGetGlyphCount(run)
                    if glyphCount == 0 {
                        continue
                    }
                    
                    let runStrIdx = UnsafeMutablePointer<CFIndex>.allocate(capacity: glyphCount + 1)
                    CTRunGetStringIndices(run, CFRangeMake(0, 0), runStrIdx)
                    let runStrRange: CFRange = CTRunGetStringRange(run)
                    runStrIdx[glyphCount] = runStrRange.location + runStrRange.length
                    
                    guard let runAttrs = CTRunGetAttributes(run) as? [String: AnyObject] else {
                        continue
                    }
                    // swiftlint:disable:next force_cast
                    let font = runAttrs[kCTFontAttributeName as String] as! CTFont
                    let isColorGlyph: Bool = TextUtilities.isContainsColorBitmapGlyphs(of: font)
                    var prevIdx = 0
                    var prevMode = TextRunGlyphDrawMode.horizontal
                    guard let layoutStr = self.text?.string else {
                        continue
                    }
                    
                    for glyph in 0..<glyphCount {
                        var glyphRotate = false
                        var glyphRotateMove = false
                        let runStrLen = CFIndex(runStrIdx[glyph + 1] - runStrIdx[glyph])
                        if isColorGlyph {
                            glyphRotate = true
                        } else if runStrLen == 1 {
                            // swiftlint:disable:next legacy_objc_type
                            let char = (layoutStr as NSString).character(at: runStrIdx[glyph])
                            glyphRotate = rotateCharset.characterIsMember(char)
                            if glyphRotate {
                                glyphRotateMove = rotateMoveCharset.characterIsMember(char)
                            }
                        } else if runStrLen > 1 {
                            let glyphStr = layoutStr[
                                layoutStr.index(
                                    layoutStr.startIndex,
                                    offsetBy: runStrIdx[glyph]
                                )..<layoutStr.index(
                                    layoutStr.startIndex,
                                    offsetBy: runStrIdx[glyph] + runStrLen
                                )
                            ]
                            // swiftlint:disable:next legacy_objc_type
                            let glyphRotate: Bool = (glyphStr as NSString).rangeOfCharacter(
                                from: rotateCharset as CharacterSet
                            ).location != NSNotFound
                            if glyphRotate {
                                // swiftlint:disable:next legacy_objc_type
                                glyphRotateMove = (glyphStr as NSString).rangeOfCharacter(
                                    from: rotateMoveCharset as CharacterSet
                                ).location != NSNotFound
                            }
                        }
                        let mode: TextRunGlyphDrawMode = glyphRotateMove ?
                            .verticalRotateMove :
                            (glyphRotate ? .verticalRotate : .horizontal)
                        if glyph == 0 {
                            prevMode = mode
                        } else if mode != prevMode {
                            let aRange = TextRunGlyphRange(
                                range: NSRange(location: prevIdx, length: glyph - prevIdx),
                                drawMode: prevMode
                            )
                            runRanges.append(aRange)
                            prevIdx = glyph
                            prevMode = mode
                        }
                    }
                    
                    if prevIdx < glyphCount {
                        let aRange = TextRunGlyphRange(
                            range: NSRange(location: prevIdx, length: glyphCount - prevIdx),
                            drawMode: prevMode
                        )
                        runRanges.append(aRange)
                    }
                    runStrIdx.deallocate()
                    line?.verticalRotateRange?.append(runRanges)
                }
            }
            
            for line in tmpLines {
                lineBlock(line)
            }
            if tmpTruncatedLine != nil {
                lineBlock(tmpTruncatedLine)
            }
        }
        
        if tmpVisibleRange.length > 0 {
            self.needDrawText = true
            typealias EnumerateBlock = (([NSAttributedString.Key: Any], NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)
            let block: EnumerateBlock = { [weak self] attrs, _, _ in
                guard let self else { return }
                if attrs[TextAttribute.textHighlight] != nil {
                    self.containsHighlight = true
                }
                if attrs[TextAttribute.textBlockBorder] != nil {
                    self.needDrawBlockBorder = true
                }
                if attrs[TextAttribute.textBackgroundBorder] != nil {
                    self.needDrawBackgroundBorder = true
                }
                if attrs[TextAttribute.textShadow] != nil || attrs[NSAttributedString.Key.shadow] != nil {
                    self.needDrawShadow = true
                }
                if attrs[TextAttribute.textUnderline] != nil {
                    self.needDrawUnderline = true
                }
                if attrs[TextAttribute.textAttachment] != nil {
                    self.needDrawAttachment = true
                }
                if attrs[TextAttribute.textInnerShadow] != nil {
                    self.needDrawInnerShadow = true
                }
                if attrs[TextAttribute.textStrikethrough] != nil {
                    self.needDrawStrikethrough = true
                }
                if attrs[TextAttribute.textBorder] != nil {
                    self.needDrawBorder = true
                }
            }
            self.text?.enumerateAttributes(
                in: tmpVisibleRange,
                options: .longestEffectiveRangeNotRequired,
                using: block
            )
            if tmpTruncatedLine != nil, let token = tmpTruncationToken {
                tmpTruncationToken?.enumerateAttributes(
                    in: NSRange(location: 0, length: token.length),
                    options: .longestEffectiveRangeNotRequired,
                    using: block
                )
            }
        }
        
        tmpAttachments = []
        tmpAttachmentRanges = []
        tmpAttachmentRects = []
        tmpAttachmentContentsSet = []
        
        let maxCount = tmpLines.count
        for index in 0..<maxCount {
            var line = tmpLines[index]
            if let truncatedLine = tmpTruncatedLine, line.index == truncatedLine.index {
                line = truncatedLine
            }
            if line.attachments?.count ?? 0 > 0 {
                if let anAttachments = line.attachments {
                    tmpAttachments?.append(contentsOf: anAttachments)
                }
                if let aRanges = line.attachmentRanges {
                    tmpAttachmentRanges?.append(contentsOf: aRanges)
                }
                if let aRects = line.attachmentRects {
                    tmpAttachmentRects?.append(contentsOf: aRects)
                }
                for attachment in line.attachments ?? [] {
                    if let content = attachment.content as? AnyHashable {
                        tmpAttachmentContentsSet?.insert(content)
                    }
                }
            }
        }
        if let attachments = tmpAttachments, attachments.isEmpty {
            tmpAttachmentRects = nil
            tmpAttachmentRanges = nil
            tmpAttachments = nil
        }
        
        self.frameSetter = ctSetter
        self.frame = ctFrame
        self.lines = tmpLines
        self.truncatedLine = tmpTruncatedLine
        self.attachments = tmpAttachments
        self.attachmentRanges = tmpAttachmentRanges
        self.attachmentRects = tmpAttachmentRects
        self.attachmentContentsSet = tmpAttachmentContentsSet
        self.rowCount = tmpRowCount
        self.visibleRange = tmpVisibleRange
        self.textBoundingRect = tmpTextBoundingRect
        self.textBoundingSize = tmpTextBoundingSize
        self.lineRowsEdge = tmpLineRowsEdge
        self.lineRowsIndex = tmpLineRowsIndex
        
        lineOrigins.deallocate()
    }
    
    // MARK: - Coding

    /// Decode
    public required convenience init?(coder aDecoder: NSCoder) {
        let data = aDecoder.decodeObject(forKey: "text") as? Data
        let text = NSAttributedString.unarchive(from: data)
        let range = (aDecoder.decodeObject(forKey: "range") as? NSValue)?.rangeValue ??
        text?.rangeOfAll ?? NSRange(location: 0, length: 0)
        let container = aDecoder.decodeObject(forKey: "container") as? TextContainer
        self.init(container: container, text: text, range: range)
    }
    
    /// Encode
    public func encode(with aCoder: NSCoder) {
        if let text = self.text {
            let data = text.archiveToData()
            aCoder.encode(data, forKey: "text")
        }
        aCoder.encode(self.container, forKey: "container")
        aCoder.encode(NSValue(range: self.range), forKey: "range")
    }
    
    // MARK: - Copying

    /// Readonly object, return `self`
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    // MARK: - Query
    
    /// Get the row index with 'edge' distance.
    ///
    /// - Parameters:
    ///     - edge: The distance from edge to the point.
    ///     If vertical form, the edge is left edge, otherwise the edge is top edge.
    ///
    /// - Returns: NSNotFound if there's no row at the point.
    private func _rowIndex(for edge: CGFloat) -> Int {
        guard rowCount > 0, let rowsEdge = self.lineRowsEdge else {
            return NSNotFound
        }
        let isVertical = container.isVerticalForm
        var lo = 0, hi: Int = rowCount - 1, mid = 0
        var rowIdx: Int = NSNotFound
        while lo <= hi {
            mid = (lo + hi) / 2
            let oneEdge = rowsEdge[mid]
            if isVertical ? (oneEdge.foot <= edge && edge <= oneEdge.head) : (oneEdge.head <= edge && edge <= oneEdge.foot) {
                rowIdx = mid
                break
            }
            if isVertical ? (edge > oneEdge.head) : (edge < oneEdge.head) {
                if mid == 0 {
                    break
                }
                hi = mid - 1
            } else {
                lo = mid + 1
            }
        }
        return rowIdx
    }
    
    /// Get the closest row index with 'edge' distance.
    ///
    /// - Parameters:
    ///     - edge:  The distance from edge to the point.
    ///     If vertical form, the edge is left edge, otherwise the edge is top edge.
    ///
    /// - Returns: NSNotFound if there's no line.
    private func _closestRowIndex(forEdge edge: CGFloat) -> Int {
        guard rowCount > 0, let rowsEdge = self.lineRowsEdge else {
            return NSNotFound
        }
        var rowIdx = _rowIndex(for: edge)
        if rowIdx == NSNotFound {
            if container.isVerticalForm {
                if edge > rowsEdge[0].head {
                    rowIdx = 0
                } else if edge < rowsEdge[rowCount - 1].foot {
                    rowIdx = rowCount - 1
                }
            } else {
                if edge < rowsEdge[0].head {
                    rowIdx = 0
                } else if edge > rowsEdge[rowCount - 1].foot {
                    rowIdx = rowCount - 1
                }
            }
        }
        return rowIdx
    }
    
    /// Get a CTRun from a line position.
    ///
    /// - Parameters:
    ///     - line: The text line.
    ///     - position: The position in the whole text.
    ///
    /// - Returns: NULL if not found (no CTRun at the position).
    private func _run(for line: TextLine?, position: TextPosition?) -> CTRun? {
        guard let ctLine = line?.ctLine, let position = position else {
            return nil
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        var index = 0
        let max = CFArrayGetCount(runs)
        while index < max {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, index), to: CTRun.self)
            let range: CFRange = CTRunGetStringRange(run)
            if position.affinity == .backward {
                if range.location < position.offset, position.offset <= range.location + range.length {
                    return run
                }
            } else {
                if range.location <= position.offset, position.offset < range.location + range.length {
                    return run
                }
            }
            index += 1
        }
        return nil
    }
    
    /// Whether the position is inside a composed character sequence.
    ///
    /// - Parameters:
    ///     - line: The text line.
    ///     - position: Text text position in whole text.
    ///     - block: The block to be executed before returns `true`.
    ///         - left: left X offset
    ///         - right: right X offset
    ///         - prev: left position
    ///         - next: right position
    @discardableResult
    private func _insideComposedCharacterSequences(
        _ line: TextLine?,
        position: Int,
        block: @escaping (_ left: CGFloat, _ right: CGFloat, _ prev: Int, _ next: Int) -> Void
    ) -> Bool {
        guard let line = line, line.range.length != 0 else {
            return false
        }
        var inside = false
        var tmpPrev = 0
        var tmpNext = 0
        
        guard let string = text?.string, let range = Range(line.range, in: string) else {
            return false
        }
        string.enumerateSubstrings(
            in: range,
            options: .byComposedCharacterSequences
        ) { _, substringRange, _, stop in
            let tmpr = NSRange(substringRange, in: string)
            let prev = tmpr.location
            let next = tmpr.location + tmpr.length
            if prev == position || next == position {
                stop = true
            }
            if prev < position, position < next {
                inside = true
                tmpPrev = prev
                tmpNext = next
                stop = true
            }
        }
        if inside {
            let left = offset(for: tmpPrev, lineIndex: line.index)
            let right = offset(for: tmpNext, lineIndex: line.index)
            block(left, right, tmpPrev, tmpNext)
        }
        return inside
    }
    
    /// Whether the position is inside an emoji (such as National Flag Emoji).
    ///
    /// - Parameters:
    ///     - line: The text line.
    ///     - position: Text text position in whole text.
    ///     - block: Yhe block to be executed before returns `true`.
    ///         - left: emoji's left X offset
    ///         - right: emoji's right X offset
    ///         - prev: emoji's left position
    ///         - next: emoji's right position
    @discardableResult
    private func _insideEmoji(
        _ line: TextLine?,
        position: Int,
        block: @escaping (_ left: CGFloat, _ right: CGFloat, _ prev: Int, _ next: Int) -> Void
    ) -> Bool {
        guard let line = line, let ctLine = line.ctLine else {
            return false
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        let runMax = CFArrayGetCount(runs)
        for runIndex in 0..<runMax {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 {
                continue
            }
            let range: CFRange = CTRunGetStringRange(run)
            if range.length <= 1 {
                continue
            }
            if position <= range.location || position >= range.location + range.length {
                continue
            }
            guard let attrs = CTRunGetAttributes(run) as? [String: AnyObject] else {
                continue
            }
            
            // swiftlint:disable:next force_cast
            let font = attrs[kCTFontAttributeName as String] as! CTFont
            if !TextUtilities.isContainsColorBitmapGlyphs(of: font) {
                continue
            }
            // Here's Emoji runs (larger than 1 unichar), and position is inside the range.
            let indices = UnsafeMutablePointer<CFIndex>.allocate(capacity: glyphCount)
            CTRunGetStringIndices(run, CFRangeMake(0, glyphCount), indices)
            for glyph in 0..<glyphCount {
                let prev: CFIndex = indices[glyph]
                let next: CFIndex = glyph + 1 < glyphCount ? indices[glyph + 1] : range.location + range.length
                if position == prev {
                    break // Emoji edge
                }
                if prev < position, position < next {
                    // inside an emoji (such as National Flag Emoji)
                    var pos = CGPoint.zero
                    var adv = CGSize.zero
                    CTRunGetPositions(run, CFRangeMake(glyph, 1), &pos)
                    CTRunGetAdvances(run, CFRangeMake(glyph, 1), &adv)
                    // if block
                    block(line.position.x + pos.x, line.position.x + pos.x + adv.width, prev, next)
                    
                    return true
                }
            }
            indices.deallocate()
        }
        return false
    }
    
    /// Whether the write direction is RTL at the specified point
    ///
    /// - Parameters:
    ///     - line:  The text line
    ///     - point: The point in layout.
    ///
    /// - Returns: `true` if RTL.
    private func _isRightToLeft(in line: TextLine?, at point: CGPoint) -> Bool {
        guard let line = line, let ctLine = line.ctLine else {
            return false
        }
        // get write direction
        var isRTL = false
        let runs = CTLineGetGlyphRuns(ctLine)
        var index = 0
        let max = CFArrayGetCount(runs)
        while index < max {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, index), to: CTRun.self)
            var glyphPosition = CGPoint.zero
            CTRunGetPositions(run, CFRangeMake(0, 1), &glyphPosition)
            if container.isVerticalForm {
                var runX: CGFloat = glyphPosition.x
                runX += line.position.y
                let runWidth = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), nil, nil, nil))
                if runX <= point.y, point.y <= runX + runWidth {
                    if CTRunGetStatus(run).rawValue & CTRunStatus.rightToLeft.rawValue != 0 {
                        isRTL = true
                    }
                    break
                }
            } else {
                var runX: CGFloat = glyphPosition.x
                runX += line.position.x
                let runWidth = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), nil, nil, nil))
                if runX <= point.x, point.x <= runX + runWidth {
                    if CTRunGetStatus(run).rawValue & CTRunStatus.rightToLeft.rawValue != 0 {
                        isRTL = true
                    }
                    break
                }
            }
            index += 1
        }
        return isRTL
    }
    
    /// Correct the range's edge.
    private func _correctedRange(withEdge range: TextRange) -> TextRange? {
        var range = range
        let visibleRange = self.visibleRange
        var start = range.start
        var end = range.end
        if start.offset == visibleRange.location && start.affinity == TextAffinity.backward {
            start = TextPosition(offset: start.offset, affinity: .forward)
        }
        if end.offset == visibleRange.location + visibleRange.length && start.affinity == .forward {
            end = TextPosition(offset: end.offset, affinity: .backward)
        }
        if start != range.start || end != range.end {
            range = TextRange(start: start, end: end)
        }
        return range
    }

    // MARK: - Query information from text layout
    
    /// The first line index for row.
    ///
    /// - Parameters:
    ///     - row: A row index.
    ///
    /// - Returns: The line index, or NSNotFound if not found.
    public func lineIndex(for row: Int) -> Int {
        guard row < rowCount, let rowsIndex = self.lineRowsIndex else {
            return NSNotFound
        }
        return rowsIndex[row]
    }
    
    /// The number of lines for row.
    ///
    /// - Parameters:
    ///     - row: A row index.
    ///
    /// - Returns: The number of lines, or NSNotFound when an error occurs.
    public func lineCount(for row: Int) -> Int {
        guard row < rowCount, let rowsIndex = self.lineRowsIndex else {
            return NSNotFound
        }
        if row == rowCount - 1 {
            return lines.count - rowsIndex[row]
        } else {
            return rowsIndex[row + 1] - rowsIndex[row]
        }
    }
    
    /// The row index for line.
    ///
    /// - Parameters:
    ///     - line: A row index.
    ///
    /// - Returns: The row index, or NSNotFound if not found.
    public func rowIndex(for line: Int) -> Int {
        if line >= lines.count {
            return NSNotFound
        }
        return lines[line].row
    }
    
    /// The line index for a specified point.
    ///
    /// It returns NSNotFound if there's no text at the point.
    ///
    /// - Parameters:
    ///     - point:  A point in the container.
    ///
    /// - Return: The line index, or NSNotFound if not found.
    public func lineIndex(for point: CGPoint) -> Int {
        guard !self.lines.isEmpty, self.rowCount > 0, let rowsIndex = self.lineRowsIndex else {
            return NSNotFound
        }
        let rowIdx: Int = _rowIndex(for: container.isVerticalForm ? point.x : point.y)
        if rowIdx == NSNotFound {
            return NSNotFound
        }
        let lineIdx0: Int = rowsIndex[rowIdx]
        let lineIdx1: Int = rowIdx == (rowCount - 1) ? lines.count - 1 : rowsIndex[rowIdx + 1] - 1
        for index in lineIdx0...lineIdx1 {
            let bounds = lines[index].bounds
            if bounds.contains(point) {
                return index
            }
        }
        return NSNotFound
    }
    
    /// The line index closest to a specified point.
    ///
    /// - Parameters:
    ///     - point: A point in the container.
    ///
    /// - Returns: The line index, or NSNotFound if no line exist in layout.
    public func closestLineIndex(for point: CGPoint) -> Int {
        let isVertical = container.isVerticalForm
        guard !self.lines.isEmpty, rowCount > 0, let rowsIndex = self.lineRowsIndex else {
            return NSNotFound
        }
        let rowIdx: Int = _closestRowIndex(forEdge: isVertical ? point.x : point.y)
        if rowIdx == NSNotFound {
            return NSNotFound
        }
        let lineIdx0: Int = rowsIndex[rowIdx]
        let lineIdx1: Int = rowIdx == rowCount - 1 ? lines.count - 1 : rowsIndex[rowIdx + 1] - 1
        if lineIdx0 == lineIdx1 {
            return lineIdx0
        }
        var minDistance = CGFloat.greatestFiniteMagnitude
        var minIndex: Int = lineIdx0
        for index in lineIdx0...lineIdx1 {
            let bounds = lines[index].bounds
            if isVertical {
                if bounds.origin.y <= point.y, point.y <= bounds.origin.y + bounds.size.height {
                    return index
                }
                var distance: CGFloat = 0
                if point.y < bounds.origin.y {
                    distance = bounds.origin.y - point.y
                } else {
                    distance = point.y - (bounds.origin.y + bounds.size.height)
                }
                if distance < minDistance {
                    minDistance = distance
                    minIndex = index
                }
            } else {
                if bounds.origin.x <= point.x, point.x <= bounds.origin.x + bounds.size.width {
                    return index
                }
                var distance: CGFloat = 0
                if point.x < bounds.origin.x {
                    distance = bounds.origin.x - point.x
                } else {
                    distance = point.x - (bounds.origin.x + bounds.size.width)
                }
                if distance < minDistance {
                    minDistance = distance
                    minIndex = index
                }
            }
        }
        return minIndex
    }
    
    /// The offset in container for a text position in a specified line.
    ///
    /// The offset is the text position's baseline point.x.
    /// If the container is vertical form, the offset is the baseline point.y;
    ///
    /// - Parameters:
    ///     - textPosition: The text position in string.
    ///     - lineIndex: The line index.
    ///
    /// - Returns: The offset in container, or CGFloat.greatestFiniteMagnitude if not found.
    public func offset(for textPosition: Int, lineIndex: Int) -> CGFloat {
        guard lineIndex < lines.count else {
            return CGFloat.greatestFiniteMagnitude
        }
        let position = textPosition
        let line = lines[lineIndex]
        guard let ctLine = line.ctLine else {
            return CGFloat.greatestFiniteMagnitude
        }
        let range: CFRange = CTLineGetStringRange(ctLine)
        if position < range.location || position > range.location + range.length {
            return CGFloat.greatestFiniteMagnitude
        }
        let offset: CGFloat = CTLineGetOffsetForStringIndex(ctLine, position, nil)
        return container.isVerticalForm ? (offset + line.position.y) : (offset + line.position.x)
    }
    
    /// The text position for a point in a specified line.
    ///
    /// This method just call CTLineGetStringIndexForPosition() and does
    /// NOT consider the emoji, line break character, binding text...
    ///
    /// - Parameters:
    ///     - point: A point in the container.
    ///     - lineIndex: The line index.
    ///
    /// - Returns: The text position, or NSNotFound if not found.
    public func textPosition(for point: CGPoint, lineIndex: Int) -> Int {
        if lineIndex >= lines.count {
            return NSNotFound
        }
        var point = point
        let line = lines[lineIndex]
        guard let ctLine = line.ctLine else {
            return NSNotFound
        }
        if container.isVerticalForm {
            point.x = point.y - line.position.y
            point.y = 0
        } else {
            point.x -= line.position.x
            point.y = 0
        }
        var idx: CFIndex = CTLineGetStringIndexForPosition(ctLine, point)
        if idx == kCFNotFound {
            return NSNotFound
        }
        
        // If the emoji contains one or more variant form (such as ☔️ "\u2614\uFE0F")
        // and the font size is smaller than 379/15, then each variant form ("\uFE0F")
        // will rendered as a single blank glyph behind the emoji glyph. Maybe it's a
        // bug in CoreText? Seems iOS8.3 fixes this problem.
        //
        // If the point hit the blank glyph, the CTLineGetStringIndexForPosition()
        // returns the position before the emoji glyph, but it should returns the
        // position after the emoji and variant form.
        //
        // Here's a workaround.
        let runs = CTLineGetGlyphRuns(ctLine)
        var runIndex = 0
        let max = CFArrayGetCount(runs)
        while runIndex < max {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            let range: CFRange = CTRunGetStringRange(run)
            if range.location <= idx, idx < range.location + range.length {
                let glyphCount: Int = CTRunGetGlyphCount(run)
                if glyphCount == 0 {
                    break
                }
                guard let attrs = CTRunGetAttributes(run) as? [String: AnyObject] else {
                    continue
                }
                // swiftlint:disable:next force_cast
                let font = attrs[kCTFontAttributeName as String] as! CTFont
                if !TextUtilities.isContainsColorBitmapGlyphs(of: font) {
                    break
                }
                let indices = UnsafeMutablePointer<CFIndex>.allocate(capacity: glyphCount)
                let positions = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
                CTRunGetStringIndices(run, CFRangeMake(0, glyphCount), indices)
                CTRunGetPositions(run, CFRangeMake(0, glyphCount), positions)
                for glyph in 0..<glyphCount {
                    let gIdx: Int = indices[glyph]
                    if gIdx == idx, glyph + 1 < glyphCount {
                        let right: CGFloat = positions[glyph + 1].x
                        if point.x < right {
                            break
                        }
                        var next: Int = indices[glyph + 1]
                        repeat {
                            if next == range.location + range.length {
                                break
                            }
                            // swiftlint:disable:next legacy_objc_type
                            let char = ((self.text?.string ?? "") as NSString).character(at: next)
                            if char == 0xfe0e || char == 0xfe0f {
                                // unicode variant form for emoji style
                                next += 1
                            } else {
                                break
                            }
                        } while true
                        if next != indices[glyph + 1] {
                            idx = next
                        }
                        break
                    }
                }
                indices.deallocate()
                positions.deallocate()
                break
            }
            runIndex += 1
        }
        return idx
    }
    
    /// The closest text position to a specified point.
    ///
    /// This method takes into account the restrict of emoji, line break
    /// character, binding text and text affinity.
    ///
    /// - Parameters:
    ///     - point:  A point in the container.
    ///
    /// - Returns: A text position, or nil if not found.
    public func closestPosition(to point: CGPoint) -> TextPosition? {
        let isVertical: Bool = container.isVerticalForm
        var point = point
        // When call CTLineGetStringIndexForPosition() on ligature such as 'fi',
        // and the point `hit` the glyph's left edge, it may get the ligature inside offset.
        // I don't know why, maybe it's a bug of CoreText. Try to avoid it.
        if isVertical {
            point.y += 0.00001234
        } else {
            point.x += 0.00001234
        }
        var lineIndex: Int = closestLineIndex(for: point)
        if lineIndex == NSNotFound {
            return nil
        }
        var line: TextLine? = lines[lineIndex]
        var position: Int = textPosition(for: point, lineIndex: lineIndex)
        if position == NSNotFound {
            position = line?.range.location ?? 0
        }
        if position <= visibleRange.location {
            return TextPosition(offset: visibleRange.location, affinity: .forward)
        } else if position >= visibleRange.location + visibleRange.length {
            return TextPosition(offset: visibleRange.location + visibleRange.length, affinity: .backward)
        }
        var finalAffinity = TextAffinity.forward
        var finalAffinityDetected = false
        // binding range
        var bindingRange = NSRange(location: 0, length: 0)
        let binding = text?.attribute(
            TextAttribute.textBinding,
            at: position,
            longestEffectiveRange: &bindingRange,
            in: NSRange(location: 0, length: text?.length ?? 0)
        )
        
        if binding != nil, bindingRange.length > 0 {
            let headLineIdx: Int = self.lineIndex(for: TextPosition(offset: bindingRange.location))
            let tailLineIdx: Int = self.lineIndex(
                for: TextPosition(offset: bindingRange.location + bindingRange.length,
                                  affinity: .backward)
            )
            if headLineIdx == lineIndex, lineIndex == tailLineIdx {
                // all in same line
                let left = offset(for: bindingRange.location, lineIndex: lineIndex)
                let right = offset(for: bindingRange.location + bindingRange.length, lineIndex: lineIndex)
                if left != CGFloat.greatestFiniteMagnitude, right != CGFloat.greatestFiniteMagnitude {
                    if container.isVerticalForm {
                        if abs(Float(point.y - left)) < abs(Float(point.y - right)) {
                            position = bindingRange.location
                            finalAffinity = TextAffinity.forward
                        } else {
                            position = bindingRange.location + bindingRange.length
                            finalAffinity = TextAffinity.backward
                        }
                    } else {
                        if abs(Float(point.x - left)) < abs(Float(point.x - right)) {
                            position = bindingRange.location
                            finalAffinity = TextAffinity.forward
                        } else {
                            position = bindingRange.location + bindingRange.length
                            finalAffinity = TextAffinity.backward
                        }
                    }
                } else if left != CGFloat.greatestFiniteMagnitude {
                    position = Int(left)
                    finalAffinity = TextAffinity.forward
                } else if right != CGFloat.greatestFiniteMagnitude {
                    position = Int(right)
                    finalAffinity = TextAffinity.backward
                }
                finalAffinityDetected = true
            } else if headLineIdx == lineIndex {
                let left: CGFloat = offset(for: bindingRange.location, lineIndex: lineIndex)
                if left != CGFloat.greatestFiniteMagnitude {
                    position = bindingRange.location
                    finalAffinity = TextAffinity.forward
                    finalAffinityDetected = true
                }
            } else if tailLineIdx == lineIndex {
                let right: CGFloat = offset(for: bindingRange.location + bindingRange.length, lineIndex: lineIndex)
                if right != CGFloat.greatestFiniteMagnitude {
                    position = bindingRange.location + bindingRange.length
                    finalAffinity = TextAffinity.backward
                    finalAffinityDetected = true
                }
            } else {
                var onLeft = false
                var onRight = false
                if headLineIdx != NSNotFound, tailLineIdx != NSNotFound {
                    if abs(headLineIdx - lineIndex) < abs(tailLineIdx - lineIndex) {
                        onLeft = true
                    } else {
                        onRight = true
                    }
                } else if headLineIdx != NSNotFound {
                    onLeft = true
                } else if tailLineIdx != NSNotFound {
                    onRight = true
                }
                if onLeft {
                    let left = offset(for: bindingRange.location, lineIndex: headLineIdx)
                    if left != CGFloat.greatestFiniteMagnitude {
                        lineIndex = headLineIdx
                        line = lines[headLineIdx]
                        position = bindingRange.location
                        finalAffinity = TextAffinity.forward
                        finalAffinityDetected = true
                    }
                } else if onRight {
                    let right = offset(for: bindingRange.location + bindingRange.length, lineIndex: tailLineIdx)
                    if right != CGFloat.greatestFiniteMagnitude {
                        lineIndex = tailLineIdx
                        line = lines[tailLineIdx]
                        position = bindingRange.location + bindingRange.length
                        finalAffinity = TextAffinity.backward
                        finalAffinityDetected = true
                    }
                }
            }
        }
        
        guard let line = line else {
            return nil
        }
        
        // empty line
        if line.range.length == 0 {
            let isBehind: Bool = lines.count > 1 && lineIndex == lines.count - 1 // end line
            return TextPosition(offset: line.range.location, affinity: isBehind ? .backward : .forward)
        }
        // detect weather the line is a linebreak token
        if line.range.length <= 2 {
            let range = line.range
            let string = text?.string.substring(start: range.location, end: range.location + range.length)
            if let string, TextUtilities.isLinebreakString(of: string) {
                // an empty line ("\r", "\n", "\r\n")
                return TextPosition(offset: line.range.location)
            }
        }
        // above whole text frame
        if lineIndex == 0, isVertical ? (point.x > line.right) : (point.y < line.top) {
            position = 0
            finalAffinity = TextAffinity.forward
            finalAffinityDetected = true
        }
        // below whole text frame
        if lineIndex == lines.count - 1, isVertical ? (point.x < line.left) : (point.y > line.bottom) {
            position = line.range.location + line.range.length
            finalAffinity = TextAffinity.backward
            finalAffinityDetected = true
        }
        
        // There must be at least one non-linebreak char,
        // ignore the linebreak characters at line end if exists.
        // There must be at least one non-linebreak char,
        // ignore the linebreak characters at line end if exists.
        if position >= line.range.location + line.range.length - 1 {
            if position > line.range.location {
                // swiftlint:disable:next legacy_objc_type
                let char1 = ((text?.string ?? "") as NSString).character(at: position - 1)
                if TextUtilities.isLinebreakChar(of: char1) {
                    position -= 1
                    if position > line.range.location {
                        // swiftlint:disable:next legacy_objc_type
                        let char0 = ((text?.string ?? "") as NSString).character(at: position - 1)
                        if TextUtilities.isLinebreakChar(of: char0) {
                            position -= 1
                        }
                    }
                }
            }
        }
        if position == line.range.location {
            return TextPosition(offset: position)
        }
        if position == line.range.location + line.range.length {
            return TextPosition(offset: position, affinity: TextAffinity.backward)
        }
        
        _insideComposedCharacterSequences(line, position: position) { lft, rht, prev, next in
            if isVertical {
                position = (abs(Float(lft - point.y)) < abs(Float(rht - point.y))) &&
                    (abs(Float(rht - point.y)) < Float(rht != 0 ? prev : next)) ? 1 : 0
            } else {
                position = (abs(Float(lft - point.x)) < abs(Float(rht - point.x))) &&
                    (abs(Float(rht - point.x)) < Float(rht != 0 ? prev : next)) ? 1 : 0
            }
        }
        
        _insideEmoji(line, position: position) { lft, rht, prev, next in
            if isVertical {
                position = (abs(Float(lft - point.y)) < abs(Float(rht - point.y))) &&
                    (abs(Float(rht - point.y)) < Float(rht != 0 ? prev : next)) ? 1 : 0
            } else {
                position = (abs(Float(lft - point.x)) < abs(Float(rht - point.x))) &&
                    (abs(Float(rht - point.x)) < Float(rht != 0 ? prev : next)) ? 1 : 0
            }
        }
        
        if position < visibleRange.location {
            position = visibleRange.location
        } else if position > visibleRange.location + visibleRange.length {
            position = visibleRange.location + visibleRange.length
        }
        if !finalAffinityDetected {
            let ofs: CGFloat = offset(for: position, lineIndex: lineIndex)
            if ofs != CGFloat.greatestFiniteMagnitude {
                let isRTL: Bool = _isRightToLeft(in: line, at: point)
                if position >= line.range.location + line.range.length {
                    finalAffinity = isRTL ? TextAffinity.forward : TextAffinity.backward
                } else if position <= line.range.location {
                    finalAffinity = isRTL ? TextAffinity.backward : TextAffinity.forward
                } else {
                    finalAffinity = (ofs < (isVertical ? point.y : point.x) && !isRTL) ? .forward : .backward
                }
            }
        }
        return TextPosition(offset: position, affinity: finalAffinity)
    }
    
    /// Returns the new position when moving selection grabber in text
    ///
    /// There are two grabber in the text selection period, user can only
    /// move one grabber at the same time.
    ///
    /// - Parameters:
    ///     - point: A point in the container.
    ///     - oldPosition: The old text position for the moving grabber.
    ///     - otherPosition: The other position in text selection view.
    ///
    /// - Returns: A text position, or nil if not found.
    ///
    public func position(
        for point: CGPoint,
        oldPosition: TextPosition?,
        otherPosition: TextPosition?
    ) -> TextPosition? {
        guard let old = oldPosition, let other = otherPosition, let rowsEdge = self.lineRowsEdge else {
            return oldPosition
        }
        var point = point
        var newPos = closestPosition(to: point)
        if newPos == nil {
            return oldPosition
        }
        if newPos?.compare(otherPosition) == old.compare(otherPosition), newPos?.offset != other.offset {
            return newPos
        }
        let lineIndex: Int = self.lineIndex(for: otherPosition)
        if lineIndex == NSNotFound {
            return oldPosition
        }
        let line = lines[lineIndex]
        let vertical = rowsEdge[line.row]
        
        if container.isVerticalForm {
            point.x = (vertical.head + vertical.foot) * 0.5
        } else {
            point.y = (vertical.head + vertical.foot) * 0.5
        }
        newPos = closestPosition(to: point)
        if newPos?.compare(otherPosition) == old.compare(otherPosition), newPos?.offset != other.offset {
            return newPos
        }
        
        if container.isVerticalForm {
            if old.compare(other) == .orderedAscending {
                // search backward
                let range: TextRange? = textRange(byExtending: otherPosition, in: UITextLayoutDirection.up, offset: 1)
                if range != nil {
                    return range?.start
                }
            } else {
                // search forward
                let range: TextRange? = textRange(byExtending: otherPosition, in: UITextLayoutDirection.down, offset: 1)
                if range != nil {
                    return range?.end
                }
            }
        } else {
            if old.compare(other) == .orderedAscending {
                // search backward
                let range: TextRange? = textRange(byExtending: otherPosition, in: UITextLayoutDirection.left, offset: 1)
                if range != nil {
                    return range?.start
                }
            } else {
                // search forward
                let range: TextRange? = textRange(byExtending: otherPosition, in: UITextLayoutDirection.right, offset: 1)
                if range != nil {
                    return range?.end
                }
            }
        }
        return oldPosition
    }
    
    /// Returns the character or range of characters that is at a given point in the container.
    /// If there is no text at the point, returns nil.
    ///
    /// This method takes into account the restrict of emoji, line break
    /// character, binding text and text affinity.
    ///
    /// - Parameters:
    ///     - point: A point in the container.
    ///
    /// - Returns: An object representing a range that encloses a character (or characters)
    /// at point. Or nil if not found.
    public func textRange(at point: CGPoint) -> TextRange? {
        let lineIndex: Int = self.lineIndex(for: point)
        if lineIndex == NSNotFound {
            return nil
        }
        let textPosition: Int = self.textPosition(for: point, lineIndex: lineIndex)
        if textPosition == NSNotFound {
            return nil
        }
        let pos = closestPosition(to: point)
        guard let pos = pos else {
            return nil
        }
        // get write direction
        let isRTL: Bool = _isRightToLeft(in: lines[lineIndex], at: point)
        let rect = caretRect(for: pos)
        
        if rect.isNull {
            return nil
        }
        if container.isVerticalForm {
            let range = textRange(
                byExtending: pos,
                in: ((rect.origin.y) >= point.y && !isRTL) ? .up : .down, offset: 1
            )
            return range
        } else {
            let range = textRange(
                byExtending: pos,
                in: ((rect.origin.x) >= point.x && !isRTL) ? .left : .right, offset: 1
            )
            return range
        }
    }
    
    /// Returns the closest character or range of characters that is at a given point in
    /// the container.
    ///
    /// This method takes into account the restrict of emoji, line break
    /// character, binding text and text affinity.
    ///
    /// - Parameters:
    ///     - point: A point in the container.
    ///
    /// - Returns: An object representing a range that encloses a character (or characters)
    /// at point. Or nil if not found.
    public func closestTextRange(at point: CGPoint) -> TextRange? {
        guard let pos = closestPosition(to: point) else {
            return nil
        }
        let lineIndex: Int = self.lineIndex(for: pos)
        if lineIndex == NSNotFound {
            return nil
        }
        let line = lines[lineIndex]
        let RTL: Bool = _isRightToLeft(in: line, at: point)
        let rect = caretRect(for: pos)
        
        if rect.isNull {
            return nil
        }
        var direction: UITextLayoutDirection = .right
        if pos.offset >= line.range.location + line.range.length {
            if direction.rawValue != (RTL ? 1 : 0) {
                direction = container.isVerticalForm ? .up : .left
            } else {
                direction = container.isVerticalForm ? .down : .right
            }
        } else if pos.offset <= line.range.location {
            if direction.rawValue != (RTL ? 1 : 0) {
                direction = container.isVerticalForm ? .down : .right
            } else {
                direction = container.isVerticalForm ? .up : .left
            }
        } else {
            if container.isVerticalForm {
                direction = ((rect.origin.y) >= point.y && !RTL) ? .up : .down
            } else {
                direction = ((rect.origin.x) >= point.x && !RTL) ? .left : .right
            }
        }
        return textRange(byExtending: pos, in: direction, offset: 1)
    }
    
    /// If the position is inside an emoji, composed character sequences, line break '\\r\\n'
    /// or custom binding range, then returns the range by extend the position. Otherwise,
    /// returns a zero length range from the position.
    ///
    /// - Parameters:
    ///     - position: A text-position object that identifies a location in layout.
    ///
    /// - Returns: A text-range object that extend the position. Or nil if an error occurs
    public func textRange(byExtending position: TextPosition?) -> TextRange? {
        let visibleStart: Int = visibleRange.location
        let visibleEnd: Int = visibleRange.location + visibleRange.length
        guard let position = position, position.offset >= visibleStart, position.offset <= visibleEnd else {
            return nil
        }
        
        // head or tail, returns immediately
        if position.offset == visibleStart {
            return TextRange(range: NSRange(location: position.offset, length: 0))
        } else if position.offset == visibleEnd {
            return TextRange(range: NSRange(location: position.offset, length: 0), affinity: .backward)
        }
        
        // binding range
        var tRange = NSRange(location: 0, length: 0)
        let binding = text?.attribute(
            TextAttribute.textBinding,
            at: position.offset,
            longestEffectiveRange: &tRange,
            in: visibleRange
        )
        if binding != nil, tRange.length != 0, tRange.location < position.offset {
            return TextRange(range: tRange)
        }
        // inside emoji or composed character sequences
        let lineIndex: Int = self.lineIndex(for: position)
        
        if lineIndex != NSNotFound {
            var tmpPrev = 0
            var tmpNext = 0
            var emoji = false
            var seq = false
            let line = lines[lineIndex]
            emoji = _insideEmoji(line, position: position.offset, block: { _, _, prev, next in
                tmpPrev = prev
                tmpNext = next
            })
            if !emoji {
                seq = _insideComposedCharacterSequences(line, position: position.offset, block: { _, _, prev, next in
                    tmpPrev = prev
                    tmpNext = next
                })
            }
            if emoji || seq {
                return TextRange(range: NSRange(location: tmpPrev, length: tmpNext - tmpPrev))
            }
        }
        
        // inside linebreak '\r\n'
        if position.offset > visibleStart, position.offset < visibleEnd {
            // swiftlint:disable legacy_objc_type
            let char0 = ((self.text?.string ?? "") as NSString).character(at: position.offset - 1)
            if char0 == ("\r" as NSString).character(at: 0), position.offset < visibleEnd {
                let char1 = ((self.text?.string ?? "") as NSString).character(at: position.offset)
                if char1 == ("\n" as NSString).character(at: 0) {
                    return TextRange(
                        start: TextPosition(offset: position.offset - 1),
                        end: TextPosition(offset: position.offset + 1)
                    )
                }
            }
            if TextUtilities.isLinebreakChar(of: char0), position.affinity == .backward {
                let string = ((text?.string ?? "") as NSString).substring(to: position.offset)
                let length: Int = TextUtilities.linebreakTailLength(of: string)
                return TextRange(
                    start: TextPosition(offset: position.offset - length),
                    end: TextPosition(offset: position.offset)
                )
            }
            // swiftlint:enable legacy_objc_type
        }
        
        return TextRange(range: NSRange(location: position.offset, length: 0), affinity: position.affinity)
    }
    
    /// Returns a text range at a given offset in a specified direction from another
    /// text position to its farthest extent in a certain direction of layout.
    ///
    /// - Parameters:
    ///     - position: A text-position object that identifies a location in layout.
    ///     - direction: A constant that indicates a direction of layout (right, left, up, down).
    ///     - offset: A character offset from position.
    ///
    /// - Returns: A text-range object that represents the distance from position to the
    /// farthest extent in direction. Or nil if an error occurs.
    public func textRange(
        byExtending position: TextPosition?,
        in direction: UITextLayoutDirection,
        offset: Int
    ) -> TextRange? {
        let visibleStart: Int = visibleRange.location
        let visibleEnd: Int = visibleRange.location + visibleRange.length
        guard let position = position, position.offset >= visibleStart, position.offset <= visibleEnd else {
            return nil
        }
        if offset == 0 {
            return textRange(byExtending: position)
        }
        var offset = offset
        
        let isVerticalForm = container.isVerticalForm
        var verticalMove = false
        var forwardMove = false
        if isVerticalForm {
            verticalMove = direction == .left || direction == .right
            forwardMove = direction == .left || direction == .down
        } else {
            verticalMove = direction == .up || direction == .down
            forwardMove = direction == .down || direction == .right
        }
        if offset < 0 {
            forwardMove = !forwardMove
            offset = -offset
        }
        // head or tail, returns immediately
        if !forwardMove, position.offset == visibleStart {
            return TextRange(range: NSRange(location: visibleRange.location, length: 0))
        } else if forwardMove, position.offset == visibleEnd {
            return TextRange(range: NSRange(location: position.offset, length: 0), affinity: .backward)
        }

        // extend from position
        guard let fromRange = textRange(byExtending: position) else {
            return nil
        }
        let allForward = TextRange(start: fromRange.start, end: TextPosition(offset: visibleEnd))
        let allBackward = TextRange(start: TextPosition(offset: visibleStart), end: fromRange.end)
        
        if verticalMove { // up/down in text layout
            let lineIndex: Int = self.lineIndex(for: position)
            if lineIndex == NSNotFound {
                return nil
            }
            let line = lines[lineIndex]
            let moveToRowIndex = line.row + (forwardMove ? offset : -offset)
            if moveToRowIndex < 0 {
                return allBackward
            } else if moveToRowIndex >= Int(rowCount) {
                return allForward
            }
            let ofs: CGFloat = self.offset(for: position.offset, lineIndex: lineIndex)
            if ofs == CGFloat.greatestFiniteMagnitude {
                return nil
            }
            let moveToLineFirstIndex: Int = self.lineIndex(for: moveToRowIndex)
            let moveToLineCount: Int = lineCount(for: moveToRowIndex)
            if moveToLineFirstIndex == NSNotFound || moveToLineCount == NSNotFound || moveToLineCount == 0 {
                return nil
            }
            var mostLeft = CGFloat.greatestFiniteMagnitude
            var mostRight: CGFloat = -CGFloat.greatestFiniteMagnitude
            var mostLeftLine = TextLine()
            var mostRightLine = TextLine()
            var insideIndex: Int = NSNotFound
            
            for index in 0..<moveToLineCount {
                let lineIndex: Int = moveToLineFirstIndex + index
                let line = lines[lineIndex]
                if isVerticalForm {
                    if line.top <= ofs, ofs <= line.bottom {
                        insideIndex = line.index
                        break
                    }
                    if line.top < mostLeft {
                        mostLeft = line.top
                        mostLeftLine = line
                    }
                    if line.bottom > mostRight {
                        mostRight = line.bottom
                        mostRightLine = line
                    }
                } else {
                    if line.left <= ofs, ofs <= line.right {
                        insideIndex = line.index
                        break
                    }
                    if line.left < mostLeft {
                        mostLeft = line.left
                        mostLeftLine = line
                    }
                    if line.right > mostRight {
                        mostRight = line.right
                        mostRightLine = line
                    }
                }
            }
            
            var afinityEdge = false
            if insideIndex == NSNotFound {
                if ofs <= mostLeft {
                    insideIndex = mostLeftLine.index
                } else {
                    insideIndex = mostRightLine.index
                }
                afinityEdge = true
            }
            let insideLine = lines[insideIndex]
            var pos = 0
            if isVerticalForm {
                pos = textPosition(for: CGPoint(x: insideLine.position.x, y: ofs), lineIndex: insideIndex)
            } else {
                pos = textPosition(for: CGPoint(x: ofs, y: insideLine.position.y), lineIndex: insideIndex)
            }
            if pos == NSNotFound {
                return nil
            }
            var extPos: TextPosition?
            
            if afinityEdge {
                if pos == insideLine.range.location + insideLine.range.length, let text = text {
                    let subStr = text.string.substring(
                        start: insideLine.range.location,
                        end: insideLine.range.location + insideLine.range.length
                    )
                    let lineBreakLen: Int = TextUtilities.linebreakTailLength(of: subStr)
                    extPos = TextPosition(offset: pos - lineBreakLen)
                } else {
                    extPos = TextPosition(offset: pos)
                }
            } else {
                extPos = TextPosition(offset: pos)
            }
            
            guard let ext = textRange(byExtending: extPos) else {
                return nil
            }
            if forwardMove {
                return TextRange(start: fromRange.start, end: ext.end)
            } else {
                return TextRange(start: ext.start, end: fromRange.end)
            }
        } else {
            let toPosition = TextPosition(offset: position.offset + (forwardMove ? offset : -offset))
            if toPosition.offset <= visibleStart {
                return allBackward
            } else if toPosition.offset >= visibleEnd {
                return allForward
            }
            
            guard let toRange = textRange(byExtending: toPosition) else {
                return nil
            }
            let start: Int = min(fromRange.start.offset, toRange.start.offset)
            let end: Int = max(fromRange.end.offset, toRange.end.offset)
            return TextRange(range: NSRange(location: start, length: end - start))
        }
    }

    /// Returns the line index for a given text position.
    ///
    /// This method takes into account the text affinity.
    ///
    /// - Parameters:
    ///     - position: A text-position object that identifies a location in layout.
    ///
    /// - Returns: The line index, or NSNotFound if not found.
    public func lineIndex(for position: TextPosition?) -> Int {
        guard let position = position, !lines.isEmpty else {
            return NSNotFound
        }
        
        let location = position.offset
        var lo = 0
        var hi: Int = lines.count - 1
        var mid = 0
        if position.affinity == .backward {
            while lo <= hi {
                mid = (lo + hi) / 2
                let line = lines[mid]
                let range = line.range
                if range.location < location, location <= (range.location + range.length) {
                    return mid
                }
                if location <= range.location {
                    hi = mid - 1
                } else {
                    lo = mid + 1
                }
            }
        } else {
            while lo <= hi {
                mid = (lo + hi) / 2
                let line = lines[mid]
                let range = line.range
                if range.location <= location, location < (range.location + range.length) {
                    return mid
                }
                if location < range.location {
                    hi = mid - 1
                } else {
                    lo = mid + 1
                }
            }
        }
        return NSNotFound
    }
    
    /// Returns the baseline position for a given text position.
    ///
    /// - Parameters:
    ///     - position: An object that identifies a location in the layout.
    ///
    /// - Returns: The baseline position for text, or CGPointZero if not found.
    public func linePosition(for position: TextPosition?) -> CGPoint {
        let lineIndex = self.lineIndex(for: position)
        guard lineIndex != NSNotFound, let position = position else {
            return CGPoint.zero
        }
        let line = lines[lineIndex]
        let offset = self.offset(for: position.offset, lineIndex: lineIndex)
        if offset == CGFloat.greatestFiniteMagnitude {
            return .zero
        }
        if container.isVerticalForm {
            return CGPoint(x: line.position.x, y: offset)
        } else {
            return CGPoint(x: offset, y: line.position.y)
        }
    }
    
    /// Returns a rectangle used to draw the caret at a given insertion point.
    ///
    /// - Parameters:
    ///     - position: An object that identifies a location in the layout.
    ///
    /// - Returns: A rectangle that defines the area for drawing the caret. The width is
    /// always zero in normal container, the height is always zero in vertical form container.
    /// If not found, it returns CGRectNull.
    public func caretRect(for position: TextPosition) -> CGRect {
        let lineIndex = self.lineIndex(for: position)
        if lineIndex == NSNotFound {
            return CGRect.null
        }
        let line = lines[lineIndex]
        let offset = self.offset(for: position.offset, lineIndex: lineIndex)
        if offset == CGFloat.greatestFiniteMagnitude {
            return CGRect.null
        }
        if container.isVerticalForm {
            return CGRect(x: line.bounds.origin.x, y: offset, width: line.bounds.size.width, height: 0)
        } else {
            return CGRect(x: offset, y: line.bounds.origin.y, width: 0, height: line.bounds.size.height)
        }
    }
    
    /// Returns the first rectangle that encloses a range of text in the layout.
    ///
    /// - Parameters:
    ///     - range: An object that represents a range of text in layout.
    ///
    /// - Returns: The first rectangle in a range of text. You might use this rectangle to
    /// draw a correction rectangle. The "first" in the name refers the rectangle
    /// enclosing the first line when the range encompasses multiple lines of text.
    /// If not found, it returns CGRectNull.
    public func firstRect(for range: TextRange) -> CGRect {
        guard let fixdRange = _correctedRange(withEdge: range) else {
            return .null
        }
        let startLineIndex: Int = lineIndex(for: fixdRange.start)
        let endLineIndex: Int = lineIndex(for: fixdRange.end)
        if startLineIndex == NSNotFound || endLineIndex == NSNotFound {
            return .null
        }
        if startLineIndex > endLineIndex {
            return .null
        }
        let startLine = lines[startLineIndex]
        let endLine = lines[endLineIndex]
        var tmpLines = [TextLine]()
        for index in startLineIndex...startLineIndex {
            let line = lines[index]
            if line.row != startLine.row {
                break
            }
            tmpLines.append(line)
        }
        if container.isVerticalForm {
            if tmpLines.count == 1 {
                var top: CGFloat = offset(for: fixdRange.start.offset, lineIndex: startLineIndex)
                var bottom: CGFloat = 0
                if startLine == endLine {
                    bottom = offset(for: fixdRange.end.offset, lineIndex: startLineIndex)
                } else {
                    bottom = startLine.bottom
                }
                if top == CGFloat.greatestFiniteMagnitude || bottom == CGFloat.greatestFiniteMagnitude {
                    return CGRect.null
                }
                if top > bottom {
                    (top, bottom) = (bottom, top)
                }
                return CGRect(x: startLine.left, y: top, width: startLine.width, height: bottom - top)
            } else {
                var top: CGFloat = offset(for: fixdRange.start.offset, lineIndex: startLineIndex)
                var bottom: CGFloat = startLine.bottom
                if top == CGFloat.greatestFiniteMagnitude || bottom == CGFloat.greatestFiniteMagnitude {
                    return CGRect.null
                }
                if top > bottom {
                    (top, bottom) = (bottom, top)
                }
                var rect = CGRect(x: startLine.left, y: top, width: startLine.width, height: bottom - top)
                for index in 1..<tmpLines.count {
                    let line = tmpLines[index]
                    rect = rect.union(line.bounds)
                }
                return rect
            }
        } else {
            if tmpLines.count == 1 {
                var left: CGFloat = offset(for: fixdRange.start.offset, lineIndex: startLineIndex)
                var right: CGFloat = 0
                if startLine == endLine {
                    right = offset(for: fixdRange.end.offset, lineIndex: startLineIndex)
                } else {
                    right = startLine.right
                }
                if left == CGFloat.greatestFiniteMagnitude || right == CGFloat.greatestFiniteMagnitude {
                    return CGRect.null
                }
                if left > right {
                    (left, right) = (right, left)
                }
                return CGRect(x: left, y: startLine.top, width: right - left, height: startLine.height)
            } else {
                var left: CGFloat = offset(for: fixdRange.start.offset, lineIndex: startLineIndex)
                var right: CGFloat = startLine.right
                if left == CGFloat.greatestFiniteMagnitude || right == CGFloat.greatestFiniteMagnitude {
                    return CGRect.null
                }
                if left > right {
                    (left, right) = (right, left)
                }
                var rect = CGRect(x: left, y: startLine.top, width: right - left, height: startLine.height)
                for index in 1..<tmpLines.count {
                    let line = tmpLines[index]
                    rect = rect.union(line.bounds)
                }
                return rect
            }
        }
    }
    
    /// Returns the rectangle union that encloses a range of text in the layout.
    ///
    /// - Parameters:
    ///     - range: An object that represents a range of text in layout.
    ///
    /// - Returns: A rectangle that defines the area than encloses the range.
    /// If not found, it returns CGRectNull.
    public func rect(for range: TextRange?) -> CGRect {
        var rects: [UITextSelectionRect]?
        if let aRange = range {
            rects = selectionRects(for: aRange)
        }
        guard let rects = rects, var rectUnion = rects.first?.rect else {
            return CGRect.null
        }
        for rect in rects {
            rectUnion = rectUnion.union(rect.rect)
        }
        return rectUnion
    }
    
    /// Returns an array of selection rects corresponding to the range of text.
    /// The start and end rect can be used to show grabber.
    ///
    /// - Parameters:
    ///     - range: An object representing a range in text.
    ///
    /// - Returns: An array of `TextSelectionRect` objects that encompass the selection.
    /// If not found, the array is empty.
    public func selectionRects(for range: TextRange) -> [TextSelectionRect] {
        guard let fixedRange = _correctedRange(withEdge: range) else {
            return []
        }
        let isVertical = container.isVerticalForm
        var rects: [TextSelectionRect] = []
        
        var startLineIndex: Int = lineIndex(for: fixedRange.start)
        var endLineIndex: Int = lineIndex(for: fixedRange.end)
        if startLineIndex == NSNotFound || endLineIndex == NSNotFound {
            return rects
        }
        if startLineIndex > endLineIndex {
            TextUtilities.swap(&startLineIndex, &endLineIndex)
        }
        let startLine = lines[startLineIndex]
        let endLine = lines[endLineIndex]
        var offsetStart: CGFloat = offset(for: fixedRange.start.offset, lineIndex: startLineIndex)
        var offsetEnd: CGFloat = offset(for: fixedRange.end.offset, lineIndex: endLineIndex)
        let start = TextSelectionRect()
        if isVertical {
            start.rect = CGRect(x: startLine.left, y: offsetStart, width: startLine.width, height: 0)
        } else {
            start.rect = CGRect(x: offsetStart, y: startLine.top, width: 0, height: startLine.height)
        }
        start.containsStart = true
        start.isVertical = isVertical
        rects.append(start)
        let end = TextSelectionRect()
        if isVertical {
            end.rect = CGRect(x: endLine.left, y: offsetEnd, width: endLine.width, height: 0)
        } else {
            end.rect = CGRect(x: offsetEnd, y: endLine.top, width: 0, height: endLine.height)
        }
        end.containsEnd = true
        end.isVertical = isVertical
        rects.append(end)
        
        if startLine.row == endLine.row {
            // same row
            if offsetStart > offsetEnd {
                TextUtilities.swap(&offsetStart, &offsetEnd)
            }
            let rect = TextSelectionRect()
            if isVertical {
                rect.rect = CGRect(
                    x: startLine.bounds.origin.x,
                    y: offsetStart,
                    width: max(startLine.width, endLine.width),
                    height: offsetEnd - offsetStart
                )
            } else {
                rect.rect = CGRect(
                    x: offsetStart,
                    y: startLine.bounds.origin.y,
                    width: offsetEnd - offsetStart,
                    height: max(startLine.height, endLine.height)
                )
            }
            rect.isVertical = isVertical
            rects.append(rect)
        } else { // more than one row
            // start line select rect
            let topRect = TextSelectionRect()
            topRect.isVertical = isVertical
            let topOffset: CGFloat = offset(for: fixedRange.start.offset, lineIndex: startLineIndex)
            let topRun = _run(for: startLine, position: fixedRange.start)
            if let topRun = topRun,
               (CTRunGetStatus(topRun).rawValue & CTRunStatus.rightToLeft.rawValue) != 0 {
                if isVertical {
                    topRect.rect = CGRect(
                        x: startLine.left,
                        y: self.container.path != nil ? startLine.top : self.container.insets.top,
                        width: startLine.width,
                        height: topOffset - startLine.top
                    )
                } else {
                    topRect.rect = CGRect(
                        x: self.container.path != nil ? startLine.left : self.container.insets.left,
                        y: startLine.top,
                        width: topOffset - startLine.left,
                        height: startLine.height
                    )
                }
                topRect.writingDirection = .rightToLeft
            } else {
                if isVertical {
                    let tmpHeight: CGFloat = {
                        if self.container.path != nil {
                            return startLine.bottom
                        }
                        return self.container.size.height - self.container.insets.bottom
                    }()
                    topRect.rect = CGRect(
                        x: startLine.left,
                        y: topOffset,
                        width: startLine.width,
                        height: tmpHeight - topOffset
                    )
                } else {
                    let tmpWidth: CGFloat = {
                        if self.container.path != nil {
                            return startLine.right
                        }
                        return self.container.size.width - self.container.insets.right
                    }()
                    topRect.rect = CGRect(
                        x: topOffset,
                        y: startLine.top,
                        width: tmpWidth - topOffset,
                        height: startLine.height
                    )
                }
            }
            rects.append(topRect)
            // end line select rect
            let bottomRect = TextSelectionRect()
            bottomRect.isVertical = isVertical
            let bottomOffset: CGFloat = offset(for: fixedRange.end.offset, lineIndex: endLineIndex)
            let bottomRun = _run(for: endLine, position: fixedRange.end)
            
            if let bottomRun = bottomRun,
               (CTRunGetStatus(bottomRun).rawValue & CTRunStatus.rightToLeft.rawValue) != 0 {
                if isVertical {
                    let tmpHeight: CGFloat = {
                        if self.container.path != nil {
                            return endLine.bottom
                        }
                        return self.container.size.height - self.container.insets.bottom
                    }()
                    bottomRect.rect = CGRect(
                        x: endLine.left,
                        y: bottomOffset,
                        width: endLine.width,
                        height: tmpHeight - bottomOffset
                    )
                } else {
                    let tmpWidth: CGFloat = {
                        if self.container.path != nil {
                            return endLine.right
                        }
                        return self.container.size.width - self.container.insets.right
                    }()
                    bottomRect.rect = CGRect(
                        x: bottomOffset,
                        y: endLine.top,
                        width: tmpWidth - bottomOffset,
                        height: endLine.height
                    )
                }
                bottomRect.writingDirection = .rightToLeft
            } else {
                if isVertical {
                    let top: CGFloat = (container.path != nil) ? endLine.top : container.insets.top
                    bottomRect.rect = CGRect(x: endLine.left, y: top, width: endLine.width, height: bottomOffset - top)
                } else {
                    let left: CGFloat = (container.path != nil) ? endLine.left : container.insets.left
                    bottomRect.rect = CGRect(x: left, y: endLine.top, width: bottomOffset - left, height: endLine.height)
                }
            }
            rects.append(bottomRect)
            
            if endLineIndex - startLineIndex >= 2 {
                var tmpRect = CGRect.zero
                var startLineDetected = false
                for index in startLineIndex + 1..<endLineIndex {
                    let line = lines[index]
                    if line.row == startLine.row || line.row == endLine.row {
                        continue
                    }
                    if !startLineDetected {
                        tmpRect = line.bounds
                        startLineDetected = true
                    } else {
                        tmpRect = tmpRect.union(line.bounds)
                    }
                }
                if startLineDetected {
                    if isVertical {
                        if container.path == nil {
                            tmpRect.origin.y = container.insets.top
                            tmpRect.size.height = container.size.height - container.insets.bottom - container.insets.top
                        }
                        tmpRect.size.width = topRect.rect.minX - bottomRect.rect.maxX
                        tmpRect.origin.x = bottomRect.rect.maxX
                    } else {
                        if container.path == nil {
                            tmpRect.origin.x = container.insets.left
                            tmpRect.size.width = container.size.width - container.insets.right - container.insets.left
                        }
                        tmpRect.origin.y = topRect.rect.maxY
                        tmpRect.size.height = bottomRect.rect.origin.y - tmpRect.origin.y
                    }
                    let rect = TextSelectionRect()
                    rect.rect = tmpRect
                    rect.isVertical = isVertical
                    rects.append(rect)
                }
            } else {
                if isVertical {
                    var r0: CGRect = bottomRect.rect
                    var r1: CGRect = topRect.rect
                    let mid: CGFloat = (r0.maxX + r1.minX) * 0.5
                    r0.size.width = mid - r0.origin.x
                    let r1ofs: CGFloat = r1.origin.x - mid
                    r1.origin.x -= r1ofs
                    r1.size.width += r1ofs
                    topRect.rect = r1
                    bottomRect.rect = r0
                } else {
                    var r0: CGRect = topRect.rect
                    var r1: CGRect = bottomRect.rect
                    let mid: CGFloat = (r0.maxY + r1.minY) * 0.5
                    r0.size.height = mid - r0.origin.y
                    let r1ofs: CGFloat = r1.origin.y - mid
                    r1.origin.y -= r1ofs
                    r1.size.height += r1ofs
                    topRect.rect = r0
                    bottomRect.rect = r1
                }
            }
        }
        
        return rects
    }
    
    /// Returns an array of selection rects corresponding to the range of text.
    ///
    /// - Parameters:
    ///     - range: An object representing a range in text.
    ///
    /// - Returns: An array of `TextSelectionRect` objects that encompass the selection.
    /// If not found, the array is empty.
    public func selectionRectsWithoutStartAndEnd(for range: TextRange) -> [TextSelectionRect] {
        var rects = selectionRects(for: range)
        var index = 0
        var max = rects.count
        while index < max {
            let rect = rects[index]
            if rect.containsStart || rect.containsEnd {
                rects.remove(at: index)
                index -= 1
                max -= 1
            }
            index += 1
        }
        return rects
    }
    
    /// Returns the start and end selection rects corresponding to the range of text.
    /// The start and end rect can be used to show grabber.
    ///
    /// - Parameters:
    ///     - range: An object representing a range in text.
    ///
    /// - Returns: An array of `TextSelectionRect` objects contains the start and end to
    /// the selection. If not found, the array is empty.
    public func selectionRectsWithOnlyStartAndEnd(for range: TextRange) -> [TextSelectionRect] {
        var rects = selectionRects(for: range)
        var index = 0
        var max = rects.count
        while index < max {
            let rect = rects[index]
            if rect.containsStart, rect.containsEnd {
                rects.remove(at: index)
                index -= 1
                max -= 1
            }
            index += 1
        }
        return rects
    }
    
    // MARK: - Draw text layout

    /// Draw the layout and show the attachments.
    ///
    /// If the `view` parameter is not nil, then the attachment views will
    /// add to this `view`, and if the `layer` parameter is not nil, then the attachment
    /// layers will add to this `layer`.
    ///
    /// - Warning: This method should be called on main thread if `view` or `layer` parameter
    /// is not nil and there's UIView or CALayer attachments in layout.
    /// Otherwise, it can be called on any thread.
    ///
    /// - Parameters:
    ///     - context: The draw context. Pass nil to avoid text and image drawing.
    ///     - size:    The context size.
    ///     - point:   The point at which to draw the layout.
    ///     - view:    The attachment views will add to this view.
    ///     - layer:   The attachment layers will add to this layer.
    ///     - debug:   The debug option. Pass nil to avoid debug drawing.
    ///     - cancel:  The cancel checker block. It will be called in drawing progress.
    ///
    /// If it returns `true`, the further draw progress will be canceled.
    /// Pass nil to ignore this feature.
    public func draw(
        in context: CGContext?,
        size: CGSize,
        point: CGPoint,
        view: UIView?,
        layer: CALayer?,
        debug: TextDebugOption?,
        cancel: (() -> Bool)? = nil
    ) {
        if needDrawBlockBorder, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawBlockBorder(
                self,
                context: context,
                size: size,
                point: point,
                cancel: cancel
            )
        }
        
        if needDrawBackgroundBorder, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawBorder(
                self,
                context: context,
                size: size,
                point: point,
                type: .backgound,
                cancel: cancel
            )
        }
        
        if needDrawShadow, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawShadow(
                self,
                context: context,
                size: size,
                point: point,
                cancel: cancel
            )
        }
        
        if needDrawUnderline, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawDecoration(
                self,
                context: context,
                size: size,
                point: point,
                type: .underline,
                cancel: cancel
            )
        }
        
        if needDrawText, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawText(
                self,
                context: context,
                size: size,
                point: point,
                cancel: cancel
            )
        }
        
        if needDrawAttachment, context != nil || view != nil || layer != nil {
            if let cancel = cancel, cancel() { return }
            textDrawAttachment(
                self,
                context: context,
                size: size,
                point: point,
                targetView: view,
                targetLayer: layer,
                cancel: cancel
            )
        }
        
        if needDrawInnerShadow, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawInnerShadow(
                self,
                context: context,
                size: size,
                point: point,
                cancel: cancel
            )
        }
        
        if needDrawStrikethrough, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawDecoration(
                self,
                context: context,
                size: size,
                point: point,
                type: .strikethrough,
                cancel: cancel
            )
        }
        
        if needDrawBorder, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawBorder(
                self,
                context: context,
                size: size,
                point: point,
                type: .normal,
                cancel: cancel
            )
        }
        
        if let need = debug?.needDrawDebug, need, let context = context {
            if let cancel = cancel, cancel() { return }
            textDrawDebug(
                self,
                context: context,
                size: size,
                point: point,
                option: debug
            )
        }
    }
    
    /// Draw the layout text and image (without view or layer attachments).
    ///
    /// This method is thread safe and can be called on any thread.
    ///
    /// - Parameters:
    ///     - context: The draw context. Pass nil to avoid text and image drawing.
    ///     - size: The context size.
    ///     - debug: The debug option. Pass nil to avoid debug drawing.
    public func draw(in context: CGContext?, size: CGSize, debug: TextDebugOption?) {
        draw(in: context, size: size, point: CGPoint.zero, view: nil, layer: nil, debug: debug, cancel: nil)
    }
    
    /// Show view and layer attachments.
    ///
    /// - Warning: This method must be called on main thread.
    ///
    /// - Parameters:
    ///     - view: The attachment views will add to this view.
    ///     - layer: The attachment layers will add to this layer.
    public func addAttachment(to view: UIView?, layer: CALayer?) {
        #if DEBUG
        assert(Thread.isMainThread, "⚠️ This method must be called on the main thread")
        #else
        if Thread.isMainThread.toggled {
            print("⚠️ This method must be called on the main thread")
            return
        }
        #endif
        draw(in: nil, size: CGSize.zero, point: CGPoint.zero, view: view, layer: layer, debug: nil, cancel: nil)
    }
    
    /// Remove attachment views and layers from their super container.
    ///
    /// - Warning: This method must be called on main thread.
    public func removeAttachmentFromViewAndLayer() {
        #if DEBUG
        assert(Thread.isMainThread, "⚠️ This method must be called on the main thread")
        #else
        if Thread.isMainThread.toggled {
            print("⚠️ This method must be called on the main thread")
            return
        }
        #endif
        guard let attachments = attachments else {
            return
        }
        for attachment in attachments {
            if let view = attachment.content as? UIView {
                view.removeFromSuperview()
            } else if let layer = attachment.content as? CALayer {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    deinit {
        lineRowsEdge?.deallocate()
        lineRowsIndex?.deallocate()
    }
}
// swiftlint:enable type_body_length

private func textMergeRectInSameLine(rect1: CGRect, rect2: CGRect, isVertical: Bool) -> CGRect {
    if isVertical {
        let top = min(rect1.origin.y, rect2.origin.y)
        let bottom = max(rect1.origin.y + rect1.size.height, rect2.origin.y + rect2.size.height)
        let width = max(rect1.size.width, rect2.size.width)
        return CGRect(x: rect1.origin.x, y: top, width: width, height: bottom - top)
    } else {
        let left = min(rect1.origin.x, rect2.origin.x)
        let right = max(rect1.origin.x + rect1.size.width, rect2.origin.x + rect2.size.width)
        let height = max(rect1.size.height, rect2.size.height)
        return CGRect(x: left, y: rect1.origin.y, width: right - left, height: height)
    }
}

private func textGetRunsMaxMetric(
    runs: CFArray,
    xHeight: UnsafeMutablePointer<CGFloat>,
    underlinePosition: UnsafeMutablePointer<CGFloat>?,
    lineThickness: UnsafeMutablePointer<CGFloat>
) {
    let xHeight = xHeight
    let underlinePosition = underlinePosition
    let lineThickness = lineThickness
    var maxXHeight: CGFloat = 0
    var maxUnderlinePos: CGFloat = 0
    var maxLineThickness: CGFloat = 0
    let max = CFArrayGetCount(runs)
    for index in 0..<max {
        let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, index), to: CTRun.self)
        if let attrs = CTRunGetAttributes(run) as? [String: AnyObject] {
            // swiftlint:disable:next force_cast
            if let font = attrs[kCTFontAttributeName as String] as! CTFont? {
                let xHeight = CTFontGetXHeight(font)
                if xHeight > maxXHeight {
                    maxXHeight = xHeight
                }
                let underlinePos = CTFontGetUnderlinePosition(font)
                if underlinePos < maxUnderlinePos {
                    maxUnderlinePos = underlinePos
                }
                let lineThickness = CTFontGetUnderlineThickness(font)
                if lineThickness > maxLineThickness {
                    maxLineThickness = lineThickness
                }
            }
        }
    }
    if xHeight.pointee != 0 {
        xHeight.pointee = maxXHeight
    }
    if underlinePosition != nil {
        underlinePosition?.pointee = maxUnderlinePos
    }
    if lineThickness.pointee != 0 {
        lineThickness.pointee = maxLineThickness
    }
}

private func textDrawRun(
    line: TextLine,
    run: CTRun,
    context: CGContext,
    size: CGSize,
    isVertical: Bool,
    runRanges: [TextRunGlyphRange]?,
    verticalOffset: CGFloat
) {
    let runTextMatrix: CGAffineTransform = CTRunGetTextMatrix(run)
    let runTextMatrixIsID = runTextMatrix.isIdentity
    guard let runAttrs = CTRunGetAttributes(run) as? [String: AnyObject] else {
        return
    }
    
    let glyphTransformValue = runAttrs[TextAttribute.textGlyphTransform.rawValue] as? NSValue
    if !isVertical, glyphTransformValue == nil {
        // draw run
        if !runTextMatrixIsID {
            context.saveGState()
            let trans: CGAffineTransform = context.textMatrix
            context.textMatrix = trans.concatenating(runTextMatrix)
        }
        CTRunDraw(run, context, CFRangeMake(0, 0))
        if !runTextMatrixIsID {
            context.restoreGState()
        }
    } else {
        // swiftlint:disable:next force_cast
        guard let runFont = runAttrs[kCTFontAttributeName as String] as! CTFont? else {
            return
        }
        
        let glyphCount: Int = CTRunGetGlyphCount(run)
        if glyphCount <= 0 {
            return
        }
        let glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: glyphCount)
        let glyphPositions = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
        CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs)
        CTRunGetPositions(run, CFRangeMake(0, 0), glyphPositions)
        
        // swiftlint:disable:next force_cast
        let fillColor = (runAttrs[kCTForegroundColorAttributeName as String] as! CGColor?) ?? UIColor.black.cgColor
        let strokeWidth = runAttrs[kCTStrokeWidthAttributeName as String] as? Int ?? 0
        
        context.saveGState()
        do {
            context.setFillColor(fillColor)
            if strokeWidth == 0 {
                context.setTextDrawingMode(.fill)
            } else {
                // swiftlint:disable:next force_cast
                var strokeColor = runAttrs[kCTStrokeColorAttributeName as String] as! CGColor?
                if strokeColor == nil {
                    strokeColor = fillColor
                }
                if let aColor = strokeColor {
                    context.setStrokeColor(aColor)
                }
                context.setLineWidth(CTFontGetSize(runFont) * CGFloat(abs(Float(strokeWidth) * 0.01)))
                if strokeWidth > 0 {
                    context.setTextDrawingMode(.stroke)
                } else {
                    context.setTextDrawingMode(.fillStroke)
                }
            }
            
            if isVertical {
                let runStrIdx = UnsafeMutablePointer<CFIndex>.allocate(capacity: glyphCount + 1)
                CTRunGetStringIndices(run, CFRangeMake(0, 0), runStrIdx)
                let runStrRange: CFRange = CTRunGetStringRange(run)
                runStrIdx[glyphCount] = runStrRange.location + runStrRange.length
                let glyphAdvances = UnsafeMutablePointer<CGSize>.allocate(capacity: glyphCount)
                CTRunGetAdvances(run, CFRangeMake(0, 0), glyphAdvances)
                let ascent: CGFloat = CTFontGetAscent(runFont)
                let descent: CGFloat = CTFontGetDescent(runFont)
                let glyphTransform = glyphTransformValue?.cgAffineTransformValue
                let zeroPoint = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
                zeroPoint.pointee = CGPoint.zero
                
                for oneRange in runRanges ?? [] {
                    let range = oneRange.glyphRangeInRun
                    let rangeMax = range.location + range.length
                    let mode: TextRunGlyphDrawMode = oneRange.drawMode
                    
                    for glyph in range.location..<rangeMax {
                        context.saveGState()
                        do {
                            context.textMatrix = .identity
                            if let glyphTransform {
                                context.textMatrix = glyphTransform
                            }
                            if mode != .horizontal {
                                // CJK glyph, need rotated
                                let ofs = (ascent - descent) * 0.5
                                let width = glyphAdvances[glyph].width * 0.5
                                var left = line.position.x +
                                    verticalOffset +
                                    (glyphPositions + glyph).pointee.y +
                                    (ofs - width)
                                var top = -line.position.y + size.height - glyphPositions[glyph].x - (ofs + width)
                                if mode == TextRunGlyphDrawMode.verticalRotateMove {
                                    left += width
                                    top += width
                                }
                                context.textPosition = CGPoint(x: left, y: top)
                            } else {
                                context.rotate(by: CGFloat(-90).toRadians())
                                context.textPosition = CGPoint(
                                    x: line.position.y - size.height + glyphPositions[glyph].x,
                                    y: line.position.x + verticalOffset + glyphPositions[glyph].y
                                )
                            }
                            if TextUtilities.isContainsColorBitmapGlyphs(of: runFont) {
                                CTFontDrawGlyphs(runFont, glyphs + glyph, zeroPoint, 1, context)
                            } else {
                                let cgFont = CTFontCopyGraphicsFont(runFont, nil)
                                context.setFont(cgFont)
                                context.setFontSize(CTFontGetSize(runFont))
                                context.showGlyphs(
                                    Array(UnsafeBufferPointer(start: glyphs + glyph, count: 1)),
                                    at: Array(UnsafeBufferPointer(start: zeroPoint, count: 1))
                                )
                            }
                        }
                        context.restoreGState()
                    }
                }
                
                runStrIdx.deallocate()
                glyphAdvances.deallocate()
                zeroPoint.deallocate()
                
            } else {
                if let glyphTransform = glyphTransformValue?.cgAffineTransformValue {
                    let runStrIdx = UnsafeMutablePointer<CFIndex>.allocate(capacity: glyphCount + 1)
                    CTRunGetStringIndices(run, CFRangeMake(0, 0), runStrIdx)
                    let runStrRange: CFRange = CTRunGetStringRange(run)
                    (runStrIdx + glyphCount).pointee = runStrRange.location + runStrRange.length
                    let glyphAdvances = UnsafeMutablePointer<CGSize>.allocate(capacity: glyphCount)
                    CTRunGetAdvances(run, CFRangeMake(0, 0), glyphAdvances)
                    let zeroPoint = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
                    zeroPoint.pointee = CGPoint.zero
                
                    for glyph in 0..<glyphCount {
                        context.saveGState()
                        do {
                            context.textMatrix = .identity
                            context.textMatrix = glyphTransform
                            context.textPosition = CGPoint(
                                x: line.position.x + glyphPositions[glyph].x,
                                y: size.height - (line.position.y + glyphPositions[glyph].y)
                            )
                            if TextUtilities.isContainsColorBitmapGlyphs(of: runFont) {
                                CTFontDrawGlyphs(runFont, glyphs + glyph, zeroPoint, 1, context)
                            } else {
                                let cgFont = CTFontCopyGraphicsFont(runFont, nil)
                                context.setFont(cgFont)
                                context.setFontSize(CTFontGetSize(runFont))
                                context.showGlyphs(
                                    Array(UnsafeBufferPointer(start: glyphs + glyph, count: 1)),
                                    at: Array(UnsafeBufferPointer(start: zeroPoint, count: 1))
                                )
                            }
                        }
                        context.restoreGState()
                    }
                    
                    runStrIdx.deallocate()
                    glyphAdvances.deallocate()
                    zeroPoint.deallocate()
                    
                } else {
                    if TextUtilities.isContainsColorBitmapGlyphs(of: runFont) {
                        CTFontDrawGlyphs(runFont, glyphs, glyphPositions, glyphCount, context)
                    } else {
                        let cgFont = CTFontCopyGraphicsFont(runFont, nil)
                        context.setFont(cgFont)
                        context.setFontSize(CTFontGetSize(runFont))
                        context.showGlyphs(
                            Array(UnsafeBufferPointer(start: glyphs, count: glyphCount)),
                            at: Array(UnsafeBufferPointer(start: glyphPositions, count: glyphCount))
                        )
                    }
                }
            }
        }
        context.restoreGState()
        
        glyphs.deallocate()
        glyphPositions.deallocate()
    }
}

private func textSetLinePatternInContext(
    style: TextLineStyle,
    width: CGFloat,
    phase: CGFloat,
    context: CGContext
) {
    context.setLineWidth(width)
    context.setLineCap(CGLineCap.butt)
    context.setLineJoin(CGLineJoin.miter)
    let dash: CGFloat = 12
    let dot: CGFloat = 5
    let space: CGFloat = 3
    let pattern = style.rawValue & 0xf00
    if pattern == TextLineStyle.none.rawValue {
        // TextLineStylePatternSolid
        context.setLineDash(phase: phase, lengths: [])
    } else if pattern == TextLineStyle.patternDot.rawValue {
        let lengths = [width * dot, width * space]
        context.setLineDash(phase: phase, lengths: lengths)
    } else if pattern == TextLineStyle.patternDash.rawValue {
        let lengths = [width * dash, width * space]
        context.setLineDash(phase: phase, lengths: lengths)
    } else if pattern == TextLineStyle.patternDashDot.rawValue {
        let lengths = [width * dash, width * space, width * dot, width * space]
        context.setLineDash(phase: phase, lengths: lengths)
    } else if pattern == TextLineStyle.patternDashDotDot.rawValue {
        let lengths = [width * dash, width * space, width * dot, width * space, width * dot, width * space]
        context.setLineDash(phase: phase, lengths: lengths)
    } else if pattern == TextLineStyle.patternCircleDot.rawValue {
        let lengths = [width * 0, width * 3]
        context.setLineDash(phase: phase, lengths: lengths)
        context.setLineCap(CGLineCap.round)
        context.setLineJoin(CGLineJoin.round)
    }
}

private func textDrawBorderRects(
    context: CGContext,
    size: CGSize,
    border: TextBorder,
    rects: [NSValue],
    isVertical: Bool
) {
    guard !rects.isEmpty else {
        return
    }
    
    if let shadow = border.shadow, let color = shadow.color {
        context.saveGState()
        context.setShadow(offset: shadow.offset, blur: shadow.radius, color: color.cgColor)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
    }
    var paths = [UIBezierPath]()
    for value in rects {
        var rect = value.cgRectValue
        if isVertical {
            rect = rect.inset(by: border.insets.rotate())
        } else {
            rect = rect.inset(by: border.insets)
        }
        rect = rect.roundFlattened()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: border.cornerRadius)
        path.close()
        paths.append(path)
    }
    if let color = border.fillColor {
        context.saveGState()
        context.setFillColor(color.cgColor)
        for path in paths {
            context.addPath(path.cgPath)
        }
        context.fillPath()
        context.restoreGState()
    }
    if border.strokeColor != nil, border.lineStyle.rawValue > 0, border.strokeWidth > 0 {
        // -------------------------- single line ------------------------------//
        context.saveGState()
        for path in paths {
            var bounds: CGRect = path.bounds.union(CGRect(origin: CGPoint.zero, size: size))
            bounds = bounds.insetBy(dx: -2 * border.strokeWidth, dy: -2 * border.strokeWidth)
            context.addRect(bounds)
            context.addPath(path.cgPath)
            context.clip(using: .evenOdd)
        }
        border.strokeColor?.setStroke()
        textSetLinePatternInContext(style: border.lineStyle, width: border.strokeWidth, phase: 0, context: context)
        var inset: CGFloat = -border.strokeWidth * 0.5
        if (border.lineStyle.rawValue & 0xff) == TextLineStyle.thick.rawValue {
            inset *= 2
            context.setLineWidth(border.strokeWidth * 2)
        }
        var radiusDelta: CGFloat = -inset
        if border.cornerRadius <= 0 {
            radiusDelta = 0
        }
        context.setLineJoin(border.lineJoin)
        for value in rects {
            var rect = value.cgRectValue
            if isVertical {
                rect = rect.inset(by: border.insets.rotate())
            } else {
                rect = rect.inset(by: border.insets)
            }
            rect = rect.insetBy(dx: inset, dy: inset)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: border.cornerRadius + radiusDelta)
            path.close()
            context.addPath(path.cgPath)
        }
        context.strokePath()
        context.restoreGState()
        
        // ------------------------- second line ------------------------------//
        if (border.lineStyle.rawValue & 0xff) == TextLineStyle.double.rawValue {
            context.saveGState()
            var inset: CGFloat = -border.strokeWidth * 2
            for value in rects {
                var rect = value.cgRectValue
                rect = rect.inset(by: border.insets)
                rect = rect.insetBy(dx: inset, dy: inset)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: border.cornerRadius + 2 * border.strokeWidth)
                path.close()
                
                var bounds: CGRect = path.bounds.union(CGRect(origin: CGPoint.zero, size: size))
                bounds = bounds.insetBy(dx: -2 * border.strokeWidth, dy: -2 * border.strokeWidth)
                context.addRect(bounds)
                context.addPath(path.cgPath)
                context.clip(using: .evenOdd)
            }
            if let aColor = border.strokeColor?.cgColor {
                context.setStrokeColor(aColor)
            }
            textSetLinePatternInContext(style: border.lineStyle, width: border.strokeWidth, phase: 0, context: context)
            context.setLineJoin(border.lineJoin)
            inset = -border.strokeWidth * 2.5
            radiusDelta = border.strokeWidth * 2
            if border.cornerRadius <= 0 {
                radiusDelta = 0
            }
            for value in rects {
                var rect = value.cgRectValue
                rect = rect.inset(by: border.insets)
                rect = rect.insetBy(dx: inset, dy: inset)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: border.cornerRadius + radiusDelta)
                path.close()
                context.addPath(path.cgPath)
            }
            context.strokePath()
            context.restoreGState()
        }
    }
    
    if border.shadow?.color != nil {
        context.endTransparencyLayer()
        context.restoreGState()
    }
}

private func textDrawLineStyle(
    context: CGContext,
    length: CGFloat,
    lineWidth: CGFloat,
    style: TextLineStyle,
    position: CGPoint,
    color: CGColor,
    isVertical: Bool
) {
    let styleBase = style.rawValue & 0xff
    if styleBase == 0 {
        return
    }
    context.saveGState()
    do {
        if isVertical {
            var left: CGFloat
            var y1: CGFloat
            var y2: CGFloat
            var width: CGFloat
            y1 = position.y.roundFlattened()
            y2 = (position.y + length).roundFlattened()
            width = styleBase == TextLineStyle.thick.rawValue ? lineWidth * 2 : lineWidth
            let linePixel = width.toPixel()
            if abs(Float(linePixel - floor(linePixel))) < 0.1 {
                let iPixel = Int(linePixel)
                if iPixel == 0 || (iPixel % 2) != 0 {
                    // odd line pixel
                    left = position.x.halfPixelFlattened()
                } else {
                    left = position.x.floorFlattened()
                }
            } else {
                left = position.x
            }
            
            context.setStrokeColor(color)
            
            textSetLinePatternInContext(style: style, width: lineWidth, phase: position.y, context: context)
            context.setLineWidth(width)
            if styleBase == TextLineStyle.single.rawValue {
                context.move(to: CGPoint(x: left, y: y1))
                context.addLine(to: CGPoint(x: left, y: y2))
                context.strokePath()
            } else if styleBase == TextLineStyle.thick.rawValue {
                context.move(to: CGPoint(x: left, y: y1))
                context.addLine(to: CGPoint(x: left, y: y2))
                context.strokePath()
            } else if styleBase == TextLineStyle.double.rawValue {
                context.move(to: CGPoint(x: left - width, y: y1))
                context.addLine(to: CGPoint(x: left - width, y: y2))
                context.strokePath()
                context.move(to: CGPoint(x: left + width, y: y1))
                context.addLine(to: CGPoint(x: left + width, y: y2))
                context.strokePath()
            }
        } else {
            var x1: CGFloat = 0
            var x2: CGFloat = 0
            var top: CGFloat = 0
            var width: CGFloat = 0
            x1 = position.x.roundFlattened()
            x2 = (position.x + length).roundFlattened()
            width = styleBase == TextLineStyle.thick.rawValue ? lineWidth * 2 : lineWidth
            let linePixel = width.toPixel()
            if abs(Float(linePixel - floor(linePixel))) < 0.1 {
                let iPixel = Int(linePixel)
                if iPixel == 0 || (iPixel % 2) != 0 {
                    // odd line pixel
                    top = position.y.halfPixelFlattened()
                } else {
                    top = position.y.floorFlattened()
                }
            } else {
                top = position.y
            }
            context.setStrokeColor(color)
            textSetLinePatternInContext(style: style, width: lineWidth, phase: position.x, context: context)
            context.setLineWidth(width)
            if styleBase == TextLineStyle.single.rawValue {
                context.move(to: CGPoint(x: x1, y: top))
                context.addLine(to: CGPoint(x: x2, y: top))
                context.strokePath()
            } else if styleBase == TextLineStyle.thick.rawValue {
                context.move(to: CGPoint(x: x1, y: top))
                context.addLine(to: CGPoint(x: x2, y: top))
                context.strokePath()
            } else if styleBase == TextLineStyle.double.rawValue {
                context.move(to: CGPoint(x: x1, y: top - width))
                context.addLine(to: CGPoint(x: x2, y: top - width))
                context.strokePath()
                context.move(to: CGPoint(x: x1, y: top + width))
                context.addLine(to: CGPoint(x: x2, y: top + width))
                context.strokePath()
            }
        }
    }
    
    context.restoreGState()
}

private func textDrawText(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    cancel: (() -> Bool)? = nil
) {
    context.saveGState()
    do {
        context.translateBy(x: point.x, y: point.y)
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        let isVertical = layout.container.isVerticalForm
        let verticalOffset = isVertical ? (size.width - layout.container.size.width) : 0
        let lines = layout.lines
        
        for line in lines {
            var newLine = line
            if let tmpL = layout.truncatedLine, tmpL.index == newLine.index {
                newLine = tmpL
            }
            let lineRunRanges = newLine.verticalRotateRange
            let posX: CGFloat = newLine.position.x
            let posY: CGFloat = size.height - newLine.position.y
            guard let ctLine = newLine.ctLine else {
                continue
            }
            let runs = CTLineGetGlyphRuns(ctLine)
            let runMax = CFArrayGetCount(runs)
            for runIndex in 0..<runMax {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
                context.textMatrix = .identity
                context.textPosition = CGPoint(x: posX, y: posY)
                textDrawRun(
                    line: newLine,
                    run: run,
                    context: context,
                    size: size,
                    isVertical: isVertical,
                    runRanges: lineRunRanges?[runIndex],
                    verticalOffset: verticalOffset
                )
            }
            if let cancel = cancel, cancel() {
                break
            }
        }
        // Use this to draw frame for test/debug.
        // context.translateBy(x: verticalOffset, y: size.height)
        // CTFrameDraw(layout.frame, context)
    }
    context.restoreGState()
}

private func textDrawBlockBorder(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    cancel: (() -> Bool)? = nil
) {
    context.saveGState()
    context.translateBy(x: point.x, y: point.y)
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = isVertical ? (size.width - layout.container.size.width) : 0
    let lines = layout.lines
    
    var index = 0
    let lineMax = lines.count
    while index < lineMax {
        if let cancel = cancel, cancel() {
            break
        }
        var line = lines[index]
        if let tmpL = layout.truncatedLine, tmpL.index == line.index {
            line = tmpL
        }
        guard let ctLine = line.ctLine else {
            break
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        let runMax = CFArrayGetCount(runs)
        for runIndex in 0..<runMax {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 {
                continue
            }
            let attrs = CTRunGetAttributes(run) as? [AnyHashable: Any]
            
            guard let border = attrs?[TextAttribute.textBlockBorder] as? TextBorder else {
                continue
            }
            var lineStartIndex = line.index
            while lineStartIndex > 0 {
                if lines[lineStartIndex - 1].row == line.row {
                    lineStartIndex = (lineStartIndex - 1)
                } else {
                    break
                }
            }
            var unionRect: CGRect = .zero
            let lineStartRow = lines[lineStartIndex].row
            var lineContinueIndex = lineStartIndex
            var lineContinueRow = lineStartRow
            
            repeat {
                let one = lines[lineContinueIndex]
                if lineContinueIndex == lineStartIndex {
                    unionRect = one.bounds
                } else {
                    unionRect = unionRect.union(one.bounds)
                }
                if lineContinueIndex + 1 == lineMax {
                    break
                }
                let next = lines[lineContinueIndex + 1]
                if next.row != lineContinueRow {
                    let nextBorder = layout.text?.attribute(
                        for: TextAttribute.textBlockBorder,
                        at: next.range.location
                    ) as? TextBorder
                    if nextBorder == border {
                        lineContinueRow += 1
                    } else {
                        break
                    }
                }
                lineContinueIndex += 1
            } while true
            
            if isVertical {
                let insets: UIEdgeInsets = layout.container.insets
                unionRect.origin.y = insets.top
                unionRect.size.height = layout.container.size.height - insets.top - insets.bottom
            } else {
                let insets: UIEdgeInsets = layout.container.insets
                unionRect.origin.x = insets.left
                unionRect.size.width = layout.container.size.width - insets.left - insets.right
            }
            unionRect.origin.x += verticalOffset
            textDrawBorderRects(
                context: context,
                size: size,
                border: border,
                rects: [NSValue(cgRect: unionRect)],
                isVertical: isVertical
            )
            index = lineContinueIndex
            break
        }
        index += 1
    }
    context.restoreGState()
}

private func textDrawBorder(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    type: TextBorderType,
    cancel: (() -> Bool)? = nil
) {
    context.saveGState()
    context.translateBy(x: point.x, y: point.y)
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = isVertical ? (size.width - layout.container.size.width) : 0
    let lines = layout.lines
    let borderKey = type == .normal ? TextAttribute.textBorder : TextAttribute.textBackgroundBorder
    var needJumpRun = false
    var jumpRunIndex = 0
    
    var index = 0
    let lineMax = lines.count
    while index < lineMax {
        if let cancel = cancel, cancel() {
            break
        }
        var line = lines[index]
        if let tmpL = layout.truncatedLine, tmpL.index == line.index {
            line = tmpL
        }
        guard let ctLine = line.ctLine else {
            break
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        var runIndex = 0
        let runMax = CFArrayGetCount(runs)
        while runIndex < runMax {
            if needJumpRun {
                needJumpRun = false
                runIndex = jumpRunIndex + 1
                if runIndex >= runMax {
                    break
                }
            }
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 {
                runIndex += 1
                continue
            }
            let attrs = CTRunGetAttributes(run) as? [AnyHashable: AnyObject]
            guard let border = attrs?[borderKey.rawValue] as? TextBorder else {
                runIndex += 1
                continue
            }
            let runRange: CFRange = CTRunGetStringRange(run)
            if runRange.location == kCFNotFound || runRange.length == 0 {
                runIndex += 1
                continue
            }
            if runRange.location + runRange.length > layout.text?.length ?? 0 {
                runIndex += 1
                continue
            }
            var runRects = [NSValue]()
            var endLineIndex = index
            var endRunIndex: Int = runIndex
            var endFound = false
            for lineIndex in index..<lineMax {
                if endFound {
                    break
                }
                let iLine = lines[lineIndex]
                guard let ctLine = iLine.ctLine else {
                    break
                }
                let iRuns = CTLineGetGlyphRuns(ctLine)
                var extLineRect = CGRect.null
                
                let rrunStart = (lineIndex == index) ? runIndex : 0
                let rrunMax = CFArrayGetCount(iRuns)
                for rrunIndex in rrunStart..<rrunMax {
                    let iRun = unsafeBitCast(CFArrayGetValueAtIndex(iRuns, rrunIndex), to: CTRun.self)
                    let iAttrs = CTRunGetAttributes(iRun) as? [AnyHashable: Any]
                    let iBorder = iAttrs?[borderKey] as? TextBorder
                    if !(border == iBorder) {
                        endFound = true
                        break
                    }
                    endLineIndex = lineIndex
                    endRunIndex = rrunIndex
                    var iRunPosition = CGPoint.zero
                    CTRunGetPositions(iRun, CFRangeMake(0, 1), &iRunPosition)
                    var ascent: CGFloat = 0
                    var descent: CGFloat = 0
                    let iRunWidth = CGFloat(CTRunGetTypographicBounds(iRun, CFRangeMake(0, 0), &ascent, &descent, nil))
                    if isVertical {
                        TextUtilities.swap(&iRunPosition.x, &iRunPosition.y)
                        iRunPosition.y += iLine.position.y
                        let iRect = CGRect(
                            x: verticalOffset + line.position.x - descent,
                            y: iRunPosition.y, width: ascent + descent, height: iRunWidth
                        )
                        if extLineRect.isNull {
                            extLineRect = iRect
                        } else {
                            extLineRect = extLineRect.union(iRect)
                        }
                    } else {
                        iRunPosition.x += iLine.position.x
                        let iRect = CGRect(
                            x: iRunPosition.x,
                            y: iLine.position.y - ascent, width: iRunWidth, height: ascent + descent
                        )
                        if extLineRect.isNull {
                            extLineRect = iRect
                        } else {
                            extLineRect = extLineRect.union(iRect)
                        }
                    }
                }
                if !extLineRect.isNull {
                    runRects.append(NSValue(cgRect: extLineRect))
                }
            }
            var drawRects = [NSValue]()
            guard var curRect = runRects.first?.cgRectValue else {
                break
            }
            let reMax = runRects.count
            for re in 0..<reMax {
                let rect = runRects[re].cgRectValue
                if isVertical {
                    if abs(Float((rect.origin.x) - (curRect.origin.x))) < 1 {
                        curRect = textMergeRectInSameLine(rect1: rect, rect2: curRect, isVertical: isVertical)
                    } else {
                        drawRects.append(NSValue(cgRect: curRect))
                        curRect = rect
                    }
                } else {
                    if abs(Float((rect.origin.y) - (curRect.origin.y))) < 1 {
                        curRect = textMergeRectInSameLine(rect1: rect, rect2: curRect, isVertical: isVertical)
                    } else {
                        drawRects.append(NSValue(cgRect: curRect))
                        curRect = rect
                    }
                }
            }
            if curRect != .zero {
                drawRects.append(NSValue(cgRect: curRect))
            }
            textDrawBorderRects(
                context: context,
                size: size,
                border: border,
                rects: drawRects,
                isVertical: isVertical
            )
            if index == endLineIndex {
                runIndex = endRunIndex
            } else {
                index = endLineIndex - 1
                needJumpRun = true
                jumpRunIndex = endRunIndex
                break
            }
            runIndex += 1
        }
        index += 1
    }
    context.restoreGState()
}

private func textDrawDecoration(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    type: TextDecorationType,
    cancel: (() -> Bool)? = nil
) {
    let lines = layout.lines
    context.saveGState()
    context.translateBy(x: point.x, y: point.y)
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = isVertical ? (size.width - layout.container.size.width) : 0
    context.translateBy(x: verticalOffset, y: 0)
    
    let lineMax = layout.lines.count
    for index in 0..<lineMax {
        if let cancel = cancel, cancel() {
            break
        }
        var line = lines[index]
        if let tmpL = layout.truncatedLine, tmpL.index == line.index {
            line = tmpL
        }
        guard let ctLine = line.ctLine else {
            break
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        let runMax = CFArrayGetCount(runs)
        for runIndex in 0..<runMax {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            let glyphCount = CTRunGetGlyphCount(run)
            if glyphCount == 0 {
                continue
            }
            let attrs = CTRunGetAttributes(run) as? [AnyHashable: Any]
            let underline = attrs?[TextAttribute.textUnderline] as? TextDecoration
            let strikethrough = attrs?[TextAttribute.textStrikethrough] as? TextDecoration
            var needDrawUnderline = false
            var needDrawStrikethrough = false
            if (type.rawValue & TextDecorationType.underline.rawValue) != 0 && underline?.style.rawValue ?? 0 > 0 {
                needDrawUnderline = true
            }
            if (type.rawValue & TextDecorationType.strikethrough.rawValue) != 0 &&
                strikethrough?.style.rawValue ?? 0 > 0 {
                needDrawStrikethrough = true
            }
            if !needDrawUnderline && !needDrawStrikethrough {
                continue
            }
            let runRange: CFRange = CTRunGetStringRange(run)
            if runRange.location == kCFNotFound || runRange.length == 0 {
                continue
            }
            if runRange.location + runRange.length > (layout.text?.length ?? 0) {
                continue
            }
            guard let runStr = layout.text?.attributedSubstring(
                from: NSRange(location: runRange.location, length: runRange.length)
            ).string else {
                continue
            }
            if TextUtilities.isLinebreakString(of: runStr) {
                continue // may need more checks...
            }
            var xHeight: CGFloat = 0
            var underlinePosition: CGFloat = 0
            var lineThickness: CGFloat = 0
            textGetRunsMaxMetric(
                runs: runs,
                xHeight: &xHeight,
                underlinePosition: &underlinePosition,
                lineThickness: &lineThickness
            )
            var underlineStart: CGPoint = .zero
            var strikethroughStart: CGPoint = .zero
            var length: CGFloat = 0
            if isVertical {
                underlineStart.x = line.position.x + underlinePosition
                strikethroughStart.x = line.position.x + xHeight / 2
                var runPosition = CGPoint.zero
                CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition)
                strikethroughStart.y = runPosition.x + line.position.y
                underlineStart.y = strikethroughStart.y
                length = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), nil, nil, nil))
            } else {
                underlineStart.y = line.position.y - underlinePosition
                strikethroughStart.y = line.position.y - xHeight / 2
                var runPosition = CGPoint.zero
                CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition)
                strikethroughStart.x = runPosition.x + line.position.x
                underlineStart.x = strikethroughStart.x
                length = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), nil, nil, nil))
            }
            
            if needDrawUnderline {
                var color = underline?.color?.cgColor
                if color == nil {
                    // swiftlint:disable:next force_cast
                    if let cgColor = attrs?[kCTForegroundColorAttributeName] as! CGColor? {
                        color = cgColor
                    }
                }
                
                let thickness: CGFloat = {
                    if let width = underline?.width?.floatValue {
                        return CGFloat(width)
                    }
                    return lineThickness
                }()
                var shadow = underline?.shadow
                while shadow != nil {
                    guard let tmpShadow = shadow, let shadowColor = tmpShadow.color else {
                        shadow = shadow?.subShadow
                        continue
                    }
                    let offsetAlterX: CGFloat = size.width + 0xffff
                    context.saveGState()
                    do {
                        var offset = tmpShadow.offset
                        offset.width -= offsetAlterX
                        context.saveGState()
                        do {
                            context.setShadow(
                                offset: offset,
                                blur: tmpShadow.radius,
                                color: shadowColor.cgColor
                            )
                            context.setBlendMode(tmpShadow.blendMode)
                            context.translateBy(x: offsetAlterX, y: 0)
                            textDrawLineStyle(
                                context: context,
                                length: length,
                                lineWidth: thickness,
                                style: underline?.style ?? .none,
                                position: underlineStart,
                                color: color ?? UIColor.black.cgColor,
                                isVertical: isVertical
                            )
                        }
                        context.restoreGState()
                    }
                    context.restoreGState()
                    shadow = tmpShadow.subShadow
                }
                textDrawLineStyle(
                    context: context,
                    length: length,
                    lineWidth: thickness,
                    style: underline?.style ?? .none,
                    position: underlineStart,
                    color: color ?? UIColor.black.cgColor,
                    isVertical: isVertical
                )
            }
            
            if needDrawStrikethrough {
                var color = strikethrough?.color?.cgColor
                if color == nil {
                    // swiftlint:disable:next force_cast
                    if let cgColor = attrs?[kCTForegroundColorAttributeName] as! CGColor? {
                        color = cgColor
                    }
                }
                let thickness: CGFloat = {
                    if let width = strikethrough?.width?.floatValue {
                        return CGFloat(width)
                    }
                    return lineThickness
                }()
                var shadow = underline?.shadow
                while shadow != nil {
                    guard let tmpShadow = shadow, let shadowColor = tmpShadow.color else {
                        shadow = shadow?.subShadow
                        continue
                    }
                    let offsetAlterX: CGFloat = size.width + 0xffff
                    context.saveGState()
                    do {
                        var offset: CGSize = tmpShadow.offset
                        offset.width -= offsetAlterX
                        context.saveGState()
                        do {
                            context.setShadow(offset: offset, blur: tmpShadow.radius, color: shadowColor.cgColor)
                            context.setBlendMode(tmpShadow.blendMode)
                            context.translateBy(x: offsetAlterX, y: 0)
                            textDrawLineStyle(
                                context: context,
                                length: length,
                                lineWidth: thickness,
                                style: underline?.style ?? .none,
                                position: underlineStart,
                                color: color ?? UIColor.black.cgColor,
                                isVertical: isVertical
                            )
                        }
                        context.restoreGState()
                    }
                    context.restoreGState()
                    shadow = tmpShadow.subShadow
                }
                textDrawLineStyle(
                    context: context,
                    length: length,
                    lineWidth: thickness,
                    style: strikethrough?.style ?? .none,
                    position: strikethroughStart,
                    color: color ?? UIColor.black.cgColor,
                    isVertical: isVertical
                )
            }
        }
    }
    context.restoreGState()
}

private func textDrawAttachment(
    _ layout: TextLayout,
    context: CGContext?,
    size: CGSize,
    point: CGPoint,
    targetView: UIView?,
    targetLayer: CALayer?,
    cancel: (() -> Bool)? = nil
) {
    guard let attachments = layout.attachments else {
        return
    }
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = isVertical ? (size.width - layout.container.size.width) : 0
    let maxCount = attachments.count
    for index in 0..<maxCount {
        let attachment = attachments[index]
        if attachment.content == nil {
            continue
        }
        var image: UIImage?
        var view: UIView?
        var layer: CALayer?
        if let img = attachment.content as? UIImage {
            image = img
        } else if let vw = attachment.content as? UIView {
            view = vw
        } else if let lyr = attachment.content as? CALayer {
            layer = lyr
        }
        if image == nil, view == nil, layer == nil {
            continue
        }
        if image != nil, context == nil {
            continue
        }
        if view != nil, targetView == nil {
            continue
        }
        if layer != nil, targetLayer == nil {
            continue
        }
        if let cancel = cancel, cancel() {
            break
        }
        let size: CGSize = image?.size ?? view?.frame.size ?? layer?.frame.size ?? .zero
        var rect: CGRect = layout.attachmentRects?[index].cgRectValue ?? .zero
        if isVertical {
            rect = rect.inset(by: attachment.contentInsets.rotate())
        } else {
            rect = rect.inset(by: attachment.contentInsets)
        }
        rect = TextUtilities.fitRect(for: attachment.contentMode, rect: rect, size: size)
        rect = rect.roundFlattened()
        rect = rect.standardized
        rect.origin.x += point.x + verticalOffset
        rect.origin.y += point.y
        if let img = image {
            if let cgImage = img.cgImage {
                context?.saveGState()
                context?.translateBy(x: 0, y: rect.maxY + rect.minY)
                context?.scaleBy(x: 1, y: -1)
                context?.draw(cgImage, in: rect)
                context?.restoreGState()
            }
        } else if let view = view {
            view.frame = rect
            targetView?.addSubview(view)
        } else if let layer = layer {
            layer.frame = rect
            targetLayer?.addSublayer(layer)
        }
    }
}

private func textDrawShadow(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    cancel: (() -> Bool)? = nil
) {
    // move out of context. (0xFFFF is just a random large number)
    let offsetAlterX: CGFloat = size.width + 0xffff
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = isVertical ? (size.width - layout.container.size.width) : 0
    context.saveGState()
    do {
        context.translateBy(x: point.x, y: point.y)
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        let lines = layout.lines
        let lineMax = layout.lines.count
        for index in 0..<lineMax {
            if let cancel = cancel, cancel() {
                break
            }
            var line = lines[index]
            if let tmp = layout.truncatedLine, tmp.index == line.index {
                line = tmp
            }
            let lineRunRanges = line.verticalRotateRange
            let linePosX = line.position.x
            let linePosY: CGFloat = size.height - line.position.y
            guard let ctLine = line.ctLine else {
                break
            }
            let runs = CTLineGetGlyphRuns(ctLine)
            let runMax = CFArrayGetCount(runs)
            for runIndex in 0..<runMax {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
                context.textMatrix = .identity
                context.textPosition = CGPoint(x: linePosX, y: linePosY)
                let attrs = CTRunGetAttributes(run) as? [AnyHashable: Any]
                var shadow = attrs?[TextAttribute.textShadow] as? TextShadow
                // NSShadow compatible
                let nsShadow = TextShadow(nsShadow: attrs?[NSAttributedString.Key.shadow] as? NSShadow)
                
                if nsShadow != nil {
                    nsShadow?.subShadow = shadow
                    shadow = nsShadow
                }
            
                while shadow != nil {
                    guard let tmpShadow = shadow, let shadowColor = shadow?.color else {
                        shadow = shadow?.subShadow
                        continue
                    }
                    var offset: CGSize = tmpShadow.offset
                    offset.width -= offsetAlterX
                    context.saveGState()
                    do {
                        context.setShadow(
                            offset: offset,
                            blur: tmpShadow.radius,
                            color: shadowColor.cgColor
                        )
                        context.setBlendMode(tmpShadow.blendMode)
                        context.translateBy(x: offsetAlterX, y: 0)
                        textDrawRun(
                            line: line,
                            run: run,
                            context: context,
                            size: size,
                            isVertical: isVertical,
                            runRanges: lineRunRanges?[runIndex],
                            verticalOffset: verticalOffset
                        )
                    }
                    context.restoreGState()
                    shadow = tmpShadow.subShadow
                }
            }
        }
    }
    context.restoreGState()
}

private func textDrawInnerShadow(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    cancel: (() -> Bool)? = nil
) {
    context.saveGState()
    context.translateBy(x: point.x, y: point.y)
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)
    context.textMatrix = .identity
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = isVertical ? (size.width - layout.container.size.width) : 0
    let lines = layout.lines
    
    let lineMax = lines.count
    for index in 0..<lineMax {
        if let cancel = cancel, cancel() {
            break
        }
        var line = lines[index]
        if let tmp = layout.truncatedLine, tmp.index == line.index {
            line = tmp
        }
        let lineRunRanges = line.verticalRotateRange
        let linePosX = line.position.x
        let linePosY: CGFloat = size.height - line.position.y
        guard let ctLine = line.ctLine else {
            break
        }
        let runs = CTLineGetGlyphRuns(ctLine)
        let runMax = CFArrayGetCount(runs)
        for runIndex in 0..<runMax {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            if CTRunGetGlyphCount(run) == 0 {
                continue
            }
            context.textMatrix = .identity
            context.textPosition = CGPoint(x: linePosX, y: linePosY)
            let attrs = CTRunGetAttributes(run) as? [AnyHashable: Any]
            var shadow = attrs?[TextAttribute.textInnerShadow] as? TextShadow
            while shadow != nil {
                guard let tmpShadow = shadow, let shadowColor = tmpShadow.color else {
                    shadow = shadow?.subShadow
                    continue
                }
                var runPosition = CGPoint.zero
                CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition)
                var runImageBounds: CGRect = CTRunGetImageBounds(run, context, CFRangeMake(0, 0))
                runImageBounds.origin.x += runPosition.x
                if runImageBounds.size.width < 0.1 || runImageBounds.size.height < 0.1 {
                    continue
                }
                guard let runAttrs = CTRunGetAttributes(run) as? [String: AnyObject] else {
                    continue
                }
                let glyphTransformValue = runAttrs[TextAttribute.textGlyphTransform.rawValue] as? NSValue
                if glyphTransformValue != nil {
                    runImageBounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                }
                // text inner shadow
                context.saveGState()
                do {
                    context.setBlendMode(tmpShadow.blendMode)
                    context.setShadow(offset: CGSize.zero, blur: 0, color: nil)
                    context.setAlpha(shadowColor.cgColor.alpha)
                    context.clip(to: runImageBounds)
                    context.beginTransparencyLayer(auxiliaryInfo: nil)
                    do {
                        let opaqueShadowColor = shadowColor.withAlphaComponent(1)
                        context.setShadow(
                            offset: tmpShadow.offset,
                            blur: tmpShadow.radius,
                            color: opaqueShadowColor.cgColor
                        )
                        context.setFillColor(opaqueShadowColor.cgColor)
                        context.setBlendMode(CGBlendMode.sourceOut)
                        context.beginTransparencyLayer(auxiliaryInfo: nil)
                        do {
                            context.fill(runImageBounds)
                            context.setBlendMode(CGBlendMode.destinationIn)
                            context.beginTransparencyLayer(auxiliaryInfo: nil)
                            do {
                                textDrawRun(
                                    line: line,
                                    run: run,
                                    context: context,
                                    size: size,
                                    isVertical: isVertical,
                                    runRanges: lineRunRanges?[runIndex],
                                    verticalOffset: verticalOffset
                                )
                            }
                            context.endTransparencyLayer()
                        }
                        context.endTransparencyLayer()
                    }
                    context.endTransparencyLayer()
                }
                context.restoreGState()
                shadow = tmpShadow.subShadow
            }
        }
    }
    context.restoreGState()
}

private func textDrawDebug(
    _ layout: TextLayout,
    context: CGContext,
    size: CGSize,
    point: CGPoint,
    option: TextDebugOption?
) {
    UIGraphicsPushContext(context)
    context.saveGState()
    context.translateBy(x: point.x, y: point.y)
    context.setLineWidth(1.0 / TextUtilities.screenScale)
    context.setLineDash(phase: 0, lengths: [])
    context.setLineJoin(CGLineJoin.miter)
    context.setLineCap(CGLineCap.butt)
    let isVertical = layout.container.isVerticalForm
    let verticalOffset: CGFloat = (isVertical ? (size.width - layout.container.size.width) : 0)
    context.translateBy(x: verticalOffset, y: 0)
    
    if option?.ctFrameBorderColor != nil || option?.ctFrameFillColor != nil {
        var path = layout.container.path
        if path == nil {
            var rect = CGRect.zero
            rect.size = layout.container.size
            rect = rect.inset(by: layout.container.insets)
            if option?.ctFrameBorderColor != nil {
                rect = rect.halfPixelFlattened()
            } else {
                rect = rect.roundFlattened()
            }
            path = UIBezierPath(rect: rect)
        }
        path?.close()
        for exclusionPath in layout.container.exclusionPaths ?? [] {
            path?.append(exclusionPath)
        }
        if let fillColor = option?.ctFrameFillColor, let path = path {
            fillColor.setFill()
            if layout.container.pathLineWidth > 0 {
                context.saveGState()
                do {
                    context.beginTransparencyLayer(auxiliaryInfo: nil)
                    do {
                        context.addPath(path.cgPath)
                        if layout.container.isPathFillEvenOdd {
                            context.fillPath(using: .evenOdd)
                        } else {
                            context.fillPath()
                        }
                        context.setBlendMode(CGBlendMode.destinationOut)
                        UIColor.black.setFill()
                        let cgPath = path.cgPath.copy(
                            strokingWithWidth: layout.container.pathLineWidth,
                            lineCap: .butt,
                            lineJoin: .miter,
                            miterLimit: 0,
                            transform: .identity
                        )
                        // if cgPath
                        context.addPath(cgPath)
                        context.fillPath()
                    }
                    context.endTransparencyLayer()
                }
                context.restoreGState()
            } else {
                context.addPath(path.cgPath)
                if layout.container.isPathFillEvenOdd {
                    context.fillPath(using: .evenOdd)
                } else {
                    context.fillPath()
                }
            }
        }
        if let borderColor = option?.ctFrameBorderColor, let path = path {
            context.saveGState()
            do {
                if layout.container.pathLineWidth > 0 {
                    context.setLineWidth(layout.container.pathLineWidth)
                }
                borderColor.setStroke()
                context.addPath(path.cgPath)
                context.strokePath()
            }
            context.restoreGState()
        }
    }
    
    let lines = layout.lines
    let lineMax = lines.count
    for index in 0..<lineMax {
        var line = lines[index]
        if let tmp = layout.truncatedLine, tmp.index == line.index {
            line = tmp
        }
        let lineBounds = line.bounds
        if let fillColor = option?.ctLineFillColor {
            fillColor.setFill()
            context.addRect(lineBounds.roundFlattened())
            context.fillPath()
        }
        if let borderColor = option?.ctLineBorderColor {
            borderColor.setStroke()
            context.addRect(lineBounds.halfPixelFlattened())
            context.strokePath()
        }
        if let baselineColor = option?.baselineColor {
            baselineColor.setStroke()
            if isVertical {
                let left: CGFloat = line.position.x.halfPixelFlattened()
                let top1: CGFloat = line.top.halfPixelFlattened()
                let top2: CGFloat = line.bottom.halfPixelFlattened()
                context.move(to: CGPoint(x: left, y: top1))
                context.addLine(to: CGPoint(x: left, y: top2))
                context.strokePath()
            } else {
                let left1: CGFloat = lineBounds.origin.x.halfPixelFlattened()
                let left2: CGFloat = (lineBounds.origin.x + lineBounds.size.width).halfPixelFlattened()
                let top: CGFloat = line.position.y.halfPixelFlattened()
                context.move(to: CGPoint(x: left1, y: top))
                context.addLine(to: CGPoint(x: left2, y: top))
                context.strokePath()
            }
        }
        if let numberColor = option?.ctLineNumberColor {
            numberColor.set()
            let num = NSMutableAttributedString(string: index.description)
            num.setTextColor(numberColor)
            num.setFont(UIFont.systemFont(ofSize: 6))
            num.draw(at: CGPoint(x: line.position.x, y: line.position.y - (isVertical ? 1 : 6)))
        }
        if option?.ctRunFillColor != nil ||
            option?.ctRunBorderColor != nil ||
            option?.ctRunNumberColor != nil ||
            option?.cgGlyphFillColor != nil ||
            option?.cgGlyphBorderColor != nil {
            guard let ctLine = line.ctLine else {
                break
            }
            let runs = CTLineGetGlyphRuns(ctLine)
            let runMax = CFArrayGetCount(runs)
            for runIndex in 0..<runMax {
                let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
                let glyphCount: CFIndex = CTRunGetGlyphCount(run)
                if glyphCount == 0 {
                    continue
                }
                let glyphPositions = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
                CTRunGetPositions(run, CFRangeMake(0, glyphCount), glyphPositions)
                let glyphAdvances = UnsafeMutablePointer<CGSize>.allocate(capacity: glyphCount)
                CTRunGetAdvances(run, CFRangeMake(0, glyphCount), glyphAdvances)
                var runPosition: CGPoint = glyphPositions[0]
                
                if isVertical {
                    TextUtilities.swap(&runPosition.x, &runPosition.y)
                    runPosition.x = line.position.x
                    runPosition.y += line.position.y
                } else {
                    runPosition.x += line.position.x
                    runPosition.y = line.position.y - runPosition.y
                }
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                let width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading))
                var runTypoBounds: CGRect = .zero
                if isVertical {
                    runTypoBounds = CGRect(
                        x: runPosition.x - descent,
                        y: runPosition.y,
                        width: ascent + descent,
                        height: width
                    )
                } else {
                    runTypoBounds = CGRect(
                        x: runPosition.x,
                        y: line.position.y - ascent,
                        width: width,
                        height: ascent + descent
                    )
                }
                if let fillColor = option?.ctRunFillColor {
                    fillColor.setFill()
                    context.addRect(runTypoBounds.roundFlattened())
                    context.fillPath()
                }
                if let borderColor = option?.ctRunBorderColor {
                    borderColor.setStroke()
                    context.addRect(runTypoBounds.halfPixelFlattened())
                    context.strokePath()
                }
                if let numberColor = option?.ctRunNumberColor {
                    numberColor.set()
                    let num = NSMutableAttributedString(string: runIndex.description)
                    num.setTextColor(numberColor)
                    num.setFont(UIFont.systemFont(ofSize: 6))
                    num.draw(at: CGPoint(x: runTypoBounds.origin.x, y: runTypoBounds.origin.y - 1))
                }
                if option?.cgGlyphBorderColor != nil || option?.cgGlyphFillColor != nil {
                    for glyph in 0..<glyphCount {
                        var pos: CGPoint = glyphPositions[glyph]
                        let adv: CGSize = glyphAdvances[glyph]
                        var rect = CGRect.zero
                        if isVertical {
                            TextUtilities.swap(&pos.x, &pos.y)
                            pos.x = runPosition.x
                            pos.y += line.position.y
                            rect = CGRect(x: pos.x - descent, y: pos.y, width: runTypoBounds.size.width, height: adv.width)
                        } else {
                            pos.x += line.position.x
                            pos.y = runPosition.y
                            rect = CGRect(x: pos.x, y: pos.y - ascent, width: adv.width, height: runTypoBounds.size.height)
                        }
                        if let fillColor = option?.cgGlyphFillColor {
                            fillColor.setFill()
                            context.addRect(rect.roundFlattened())
                            context.fillPath()
                        }
                        if let borderColor = option?.cgGlyphBorderColor {
                            borderColor.setStroke()
                            context.addRect(rect.halfPixelFlattened())
                            context.strokePath()
                        }
                    }
                }
                glyphPositions.deallocate()
                glyphAdvances.deallocate()
            }
        }
    }
    context.restoreGState()
    UIGraphicsPopContext()
}
// swiftlint:enable function_body_length

private extension UIEdgeInsets {
    /// 顺时针旋转 90°
    @inline(__always)
    func rotate() -> UIEdgeInsets {
        return UIEdgeInsets(top: left, left: bottom, bottom: right, right: top)
    }
}

private extension CGSize {
    @inline(__always)
    func clipped() -> CGSize {
        var size = self
        if size.width > TextContainer.maxSize.width {
            size.width = TextContainer.maxSize.width
        }
        if size.height > TextContainer.maxSize.height {
            size.height = TextContainer.maxSize.height
        }
        return size
    }
}
