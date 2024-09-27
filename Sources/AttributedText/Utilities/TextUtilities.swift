//
//  TextUtilities.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//

import UIKit
import Accelerate

/// 文本工具
public enum TextUtilities {
    
    /// 是否是 App 扩展
    public static let isAppExtension: Bool = {
        
        guard let cls = NSClassFromString("UIApplication") else {
            return true
        }
        guard cls.responds(to: #selector(getter: UIApplication.shared)) else {
            return true
        }
        if Bundle.main.bundlePath.hasSuffix(".appex") {
            return true
        }
        
        return false
    }()
    
    /// App
    public static var sharedApp: UIApplication? {
        return self.isAppExtension ? nil : UIApplication.shared
    }
    
    /// windowScene
    public static var windowScene: UIWindowScene? {
        guard let allScenes = self.sharedApp?.connectedScenes else {
            return nil
        }
        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }
            return windowScene
        }
        return nil
    }
    
    /// keyWindow
    public static var keyWindow: UIWindow? {
        guard let windowScene = self.windowScene else {
            return nil
        }
        for window in windowScene.windows where window.isKeyWindow {
            return window
        }
        return nil
    }
    
    /// 最顶层的 ViewController
    public static var topVC: UIViewController? {
        var window = self.keyWindow
        if window == nil {
            window = self.windowScene?.windows.first(where: { $0.rootViewController != nil })
        }
        return window?.rootViewController?.topVC
    }
    
    /// 获取应以垂直形式旋转的字符集
    public static let verticalFormRotateCharacterSet: NSMutableCharacterSet = {
        
        let tmpSet = NSMutableCharacterSet()
        tmpSet.addCharacters(in: NSRange(location: 0x1100, length: 256)) // Hangul Jamo
        tmpSet.addCharacters(in: NSRange(location: 0x2460, length: 160)) // Enclosed Alphanumerics
        tmpSet.addCharacters(in: NSRange(location: 0x2600, length: 256)) // Miscellaneous Symbols
        tmpSet.addCharacters(in: NSRange(location: 0x2700, length: 192)) // Dingbats
        tmpSet.addCharacters(in: NSRange(location: 0x2e80, length: 128)) // CJK Radicals Supplement
        tmpSet.addCharacters(in: NSRange(location: 0x2f00, length: 224)) // Kangxi Radicals
        tmpSet.addCharacters(in: NSRange(location: 0x2ff0, length: 16)) // Ideographic Description Characters
        tmpSet.addCharacters(in: NSRange(location: 0x3000, length: 64)) // CJK Symbols and Punctuation
        tmpSet.removeCharacters(in: NSRange(location: 0x3008, length: 10))
        tmpSet.removeCharacters(in: NSRange(location: 0x3014, length: 12))
        tmpSet.addCharacters(in: NSRange(location: 0x3040, length: 96)) // Hiragana
        tmpSet.addCharacters(in: NSRange(location: 0x30a0, length: 96)) // Katakana
        tmpSet.addCharacters(in: NSRange(location: 0x3100, length: 48)) // Bopomofo
        tmpSet.addCharacters(in: NSRange(location: 0x3130, length: 96)) // Hangul Compatibility Jamo
        tmpSet.addCharacters(in: NSRange(location: 0x3190, length: 16)) // Kanbun
        tmpSet.addCharacters(in: NSRange(location: 0x31a0, length: 32)) // Bopomofo Extended
        tmpSet.addCharacters(in: NSRange(location: 0x31c0, length: 48)) // CJK Strokes
        tmpSet.addCharacters(in: NSRange(location: 0x31f0, length: 16)) // Katakana Phonetic Extensions
        tmpSet.addCharacters(in: NSRange(location: 0x3200, length: 256)) // Enclosed CJK Letters and Months
        tmpSet.addCharacters(in: NSRange(location: 0x3300, length: 256)) // CJK Compatibility
        tmpSet.addCharacters(in: NSRange(location: 0x3400, length: 2_582)) // CJK Unified Ideographs Extension A
        tmpSet.addCharacters(in: NSRange(location: 0x4e00, length: 20_941)) // CJK Unified Ideographs
        tmpSet.addCharacters(in: NSRange(location: 0xac00, length: 11_172)) // Hangul Syllables
        tmpSet.addCharacters(in: NSRange(location: 0xd7b0, length: 80)) // Hangul Jamo Extended-B
        tmpSet.addCharacters(in: "") // U+F8FF (Private Use Area)
        tmpSet.addCharacters(in: NSRange(location: 0xf900, length: 512)) // CJK Compatibility Ideographs
        tmpSet.addCharacters(in: NSRange(location: 0xfe10, length: 16)) // Vertical Forms
        tmpSet.addCharacters(in: NSRange(location: 0xff00, length: 240)) // Halfwidth and Fullwidth Forms
        tmpSet.addCharacters(in: NSRange(location: 0x1f200, length: 256)) // Enclosed Ideographic Supplement
        tmpSet.addCharacters(in: NSRange(location: 0x1f300, length: 768)) // Enclosed Ideographic Supplement
        tmpSet.addCharacters(in: NSRange(location: 0x1f600, length: 80)) // Emoticons (Emoji)
        tmpSet.addCharacters(in: NSRange(location: 0x1f680, length: 128)) // Transport and Map Symbols
        // See http://unicode-table.com/ for more information.
        
        return tmpSet
    }()
    
    /// 获取应该以垂直形式旋转和移动的字符集
    public static let verticalFormRotateAndMoveCharacterSet: NSCharacterSet = {
        return NSCharacterSet(charactersIn: "，。、．")
    }()
    
    /// CALayerContentsGravity 和 UIView.ContentMode 对照
    private static let caGravityToUIViewContentModeMap: [CALayerContentsGravity: UIView.ContentMode] = {
        return [
            CALayerContentsGravity.center: UIView.ContentMode.center,
            CALayerContentsGravity.top: UIView.ContentMode.top,
            CALayerContentsGravity.bottom: UIView.ContentMode.bottom,
            CALayerContentsGravity.left: UIView.ContentMode.left,
            CALayerContentsGravity.right: UIView.ContentMode.right,
            CALayerContentsGravity.topLeft: UIView.ContentMode.topLeft,
            CALayerContentsGravity.topRight: UIView.ContentMode.topRight,
            CALayerContentsGravity.bottomLeft: UIView.ContentMode.bottomLeft,
            CALayerContentsGravity.bottomRight: UIView.ContentMode.bottomRight,
            CALayerContentsGravity.resize: UIView.ContentMode.scaleToFill,
            CALayerContentsGravity.resizeAspect: UIView.ContentMode.scaleAspectFit,
            CALayerContentsGravity.resizeAspectFill: UIView.ContentMode.scaleAspectFill
        ]
    }()
    
    /// 获取主屏幕的 scale
    public static var screenScale: CGFloat = UIScreen.main.scale
    
    /// 获取主屏幕的尺寸, 高度总是比宽度大
    public static var screenSize: CGSize = CGSize(
        width: min(UIScreen.main.bounds.height, UIScreen.main.bounds.width),
        height: max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
    )
    
    // swiftlint:disable identifier_name
    /// 交换两个参数
    public static func swap<T>(_ a: inout T, _ b: inout T) {
        (a, b) = (b, a)
    }
    
    /// 夹紧
    public static func clamp(x: CGFloat, low: CGFloat, high: CGFloat) -> CGFloat {
        return (x > high) ? high : ((x < low) ? low : x)
    }
    // swiftlint:enable identifier_name
    
    /// 该字符是否为'换行符'
    ///
    /// U+000D (\\r or CR)
    /// U+2028 (Unicode line separator)
    /// U+000A (\\n or LF)
    /// U+2029 (Unicode paragraph separator)
    ///
    @inline(__always)
    public static func isLinebreakChar(of char: unichar) -> Bool {
        switch char {
        case unichar(0x000D), unichar(0x2028), unichar(0x000A), unichar(0x2029):
            return true
        default:
            return false
        }
    }
    
    /// 该字符串是否为 "换行"
    ///
    /// U+000D (\\r or CR)
    /// U+2028 (Unicode line separator)
    /// U+000A (\\n or LF)
    /// U+2029 (Unicode paragraph separator)
    /// \\r\\n, in that order (also known as CRLF)
    ///
    @inline(__always)
    public static func isLinebreakString(of string: String) -> Bool {
        let nsString = string as NSString
        guard nsString.length > 0, nsString.length <= 2 else {
            return false
        }
        
        if nsString.length == 1 {
            let char = unichar(nsString.character(at: 0))
            return Self.isLinebreakChar(of: char)
        } else {
            return (nsString.substring(to: 1) == "\r") && (nsString.substring(from: 1) == "\n")
        }
    }
    
    /// 如果字符串有 "换行" 后缀, 返回 "换行" 的长度
    @inline(__always)
    public static func linebreakTailLength(of string: String) -> Int {
        let nsString = string as NSString
        guard !string.isEmpty else {
            return 0
        }
        if nsString.length == 1 {
            return Self.isLinebreakChar(of: nsString.character(at: 0)) ? 1 : 0
        } else {
            let char2 = nsString.character(at: nsString.length - 1)
            if Self.isLinebreakChar(of: char2) {
                let char1 = nsString.character(at: nsString.length - 2)
                if String(char1) == "\r" && String(char2) == "\n" {
                    return 2
                } else {
                    return 1
                }
            } else {
                return 0
            }
        }
    }
    
    /// 将 `UIDataDetectorTypes` 转换为 `NSTextCheckingType`
    @inline(__always)
    public static func checkingType(from types: UIDataDetectorTypes) -> NSTextCheckingResult.CheckingType {
        
        var result = NSTextCheckingResult.CheckingType(rawValue: 0)
        if types.rawValue & UIDataDetectorTypes.phoneNumber.rawValue != 0 {
            result.insert(.phoneNumber)
        }
        if types.rawValue & UIDataDetectorTypes.link.rawValue != 0 {
            result.insert(.link)
        }
        if types.rawValue & UIDataDetectorTypes.address.rawValue != 0 {
            result.insert(.address)
        }
        if types.rawValue & UIDataDetectorTypes.calendarEvent.rawValue != 0 {
            result.insert(.date)
        }
        return result
    }
    
    /// UIFont 字体是否为 `AppleColorEmoji`
    @inline(__always)
    public static func isEmojiUIFont(of font: UIFont) -> Bool {
        return font.fontName == "AppleColorEmoji"
    }
    
    /// CTFont 字体是否为 `AppleColorEmoji`
    @inline(__always)
    public static func isEmojiCTFont(of font: CTFont) -> Bool {
        return CFEqual("AppleColorEmoji" as CFTypeRef, CTFontCopyPostScriptName(font))
    }
    
    /// CGFont 字体是否为 `AppleColorEmoji`
    @inline(__always)
    public static func isEmojiCGFont(of font: CGFont) -> Bool {
        return CFEqual("AppleColorEmoji" as CFTypeRef, font.postScriptName)
    }
    
    /// 该字体是否包含彩色位图字形
    @inline(__always)
    public static func isContainsColorBitmapGlyphs(of font: CTFont) -> Bool {
        return (CTFontGetSymbolicTraits(font).rawValue & CTFontSymbolicTraits.traitColorGlyphs.rawValue) != 0
    }
    
    /// 字形是否是位图
    @inline(__always)
    public static func isBitmapCGGlyph(of font: CTFont, glyph: CGGlyph) -> Bool {
        guard Self.isContainsColorBitmapGlyphs(of: font) else {
            return false
        }
        if CTFontCreatePathForGlyph(font, glyph, nil) != nil {
            return false
        }
        return true
    }
    
    /// 获取指定字体大小的 `AppleColorEmoji` 字体的 Ascent
    ///
    /// 它可以用来创建自定义的表情符号
    @inline(__always)
    public static func getEmojiAscent(of fontSize: CGFloat) -> CGFloat {
        if fontSize < 16 {
            return 1.25 * fontSize
        } else if fontSize >= 16 && fontSize <= 24 {
            return 0.5 * fontSize + 12
        } else {
            return fontSize
        }
    }
    
    /// 获取指定字体大小的 `AppleColorEmoji` 字体的 Desent
    ///
    /// 它可以用来创建自定义的表情符号
    @inline(__always)
    public static func getEmojiDescent(of fontSize: CGFloat) -> CGFloat {
        if fontSize < 16 {
            return 0.390625 * fontSize
        } else if fontSize >= 16 && fontSize <= 24 {
            return 0.15625 * fontSize + 3.75
        } else {
            return 0.3125 * fontSize
        }
    }
    
    /// 获取 `AppleColorEmoji` 字体的字形边界矩形, 并指定字体大小
    ///
    /// 它可以用来创建自定义的表情符号
    @inline(__always)
    public static func getEmojiGlyphBoundingRect(of fontSize: CGFloat) -> CGRect {
        
        var rect = CGRect(x: 0.75, y: 0, width: 0, height: 0)
        
        rect.size.height = Self.getEmojiAscent(of: fontSize)
        rect.size.width = rect.size.height
        
        if fontSize < 16 {
            rect.origin.y = -0.2525 * fontSize
        } else if fontSize >= 16 && fontSize <= 24 {
            rect.origin.y = 0.1225 * fontSize - 6
        } else {
            rect.origin.y = -0.1275 * fontSize
        }
        return rect
    }
    
    // 矩阵求逆
    // swiftlint:disable identifier_name
    private static func invertMatrix(_ matrix: inout [Double]) -> Int {
        
        // 这样写矩阵中总元素个数大于 8 的时候会发生越界导致 Crash
        // var pivot : __CLPK_integer = 0
        // var workspace = 0
        // 这样写个数不受限制
        let pivot = UnsafeMutablePointer<__CLPK_integer>.allocate(capacity: matrix.count)
        let workspace = UnsafeMutablePointer<Double>.allocate(capacity: matrix.count)
        defer {
            pivot.deallocate()
            workspace.deallocate()
        }
        
        var error: __CLPK_integer = 0
        
        var n = __CLPK_integer(sqrt(Double(matrix.count)))
        var m = n
        var lda = n
        
        dgetrf_(&m, &n, &matrix, &lda, pivot, &error)
        
        if error != 0 {
            return Int(error)
        }
        
        dgetri_(&m, &matrix, &lda, pivot, workspace, &n, &error)
        
        return Int(error)
    }
    
    /// 该方法返回来自这3对点的原始变换矩阵
    ///
    /// p1 (transform->) q1
    /// p2 (transform->) q2
    /// p3 (transform->) q3
    ///
    public static func affineTransform(from before: [CGPoint], _ after: [CGPoint]) -> CGAffineTransform {
        
        var p1: CGPoint, p2: CGPoint, p3: CGPoint, q1: CGPoint, q2: CGPoint, q3: CGPoint
        
        p1 = before[0]
        p2 = before[1]
        p3 = before[2]
        q1 = after[0]
        q2 = after[1]
        q3 = after[2]
        
        var A = [Double](repeating: 0, count: 36)
        A[0] = Double(p1.x); A[1] = Double(p1.y); A[2] = 0; A[3] = 0; A[4] = 1; A[5] = 0
        A[6] = 0; A[7] = 0; A[8] = Double(p1.x); A[9] = Double(p1.y); A[10] = 0; A[11] = 1
        A[12] = Double(p2.x); A[13] = Double(p2.y); A[14] = 0; A[15] = 0; A[16] = 1; A[17] = 0
        A[18] = 0; A[19] = 0; A[20] = Double(p2.x); A[21] = Double(p2.y); A[22] = 0; A[23] = 1
        A[24] = Double(p3.x); A[25] = Double(p3.y); A[26] = 0; A[27] = 0; A[28] = 1; A[29] = 0
        A[30] = 0; A[31] = 0; A[32] = Double(p3.x); A[33] = Double(p3.y); A[34] = 0; A[35] = 1
        
        let error = invertMatrix(&A)
        if error != 0 {
            return .identity
        }
        var B = [Double](repeating: 0, count: 6)
        B[0] = Double(q1.x)
        B[1] = Double(q1.y)
        B[2] = Double(q2.x)
        B[3] = Double(q2.y)
        B[4] = Double(q3.x)
        B[5] = Double(q3.y)
        var M = [Double](repeating: 0, count: 6)
        M[0] = A[0] * B[0] + A[1] * B[1] + A[2] * B[2] + A[3] * B[3] + A[4] * B[4] + A[5] * B[5]
        M[1] = A[6] * B[0] + A[7] * B[1] + A[8] * B[2] + A[9] * B[3] + A[10] * B[4] + A[11] * B[5]
        M[2] = A[12] * B[0] + A[13] * B[1] + A[14] * B[2] + A[15] * B[3] + A[16] * B[4] + A[17] * B[5]
        M[3] = A[18] * B[0] + A[19] * B[1] + A[20] * B[2] + A[21] * B[3] + A[22] * B[4] + A[23] * B[5]
        M[4] = A[24] * B[0] + A[25] * B[1] + A[26] * B[2] + A[27] * B[3] + A[28] * B[4] + A[29] * B[5]
        M[5] = A[30] * B[0] + A[31] * B[1] + A[32] * B[2] + A[33] * B[3] + A[34] * B[4] + A[35] * B[5]
        
        let transform = CGAffineTransform(
            a: CGFloat(M[0]),
            b: CGFloat(M[2]),
            c: CGFloat(M[1]),
            d: CGFloat(M[3]),
            tx: CGFloat(M[4]),
            ty: CGFloat(M[5])
        )
        
        return transform
    }
    
    /// 获取可以将一个点从一个给定视图的坐标系转换到另一个坐标系的转换
    public static func affineTransform(from: UIView?, to: UIView?) -> CGAffineTransform {
        guard let from = from, let to = to else {
            return .identity
        }
        var before = [CGPoint](repeating: .zero, count: 3)
        var after = [CGPoint](repeating: .zero, count: 3)
        before[0] = .zero
        before[1] = CGPoint(x: 0, y: 1)
        before[2] = CGPoint(x: 1, y: 0)
        after[0] = from._convert(before[0], to: to)
        after[1] = from._convert(before[1], to: to)
        after[2] = from._convert(before[2], to: to)
        return affineTransform(from: before, after)
    }
    
    /// 创建一个斜度 `CGAffineTransform`
    @inline(__always)
    public static func skewAffineTransform(_ x: CGFloat, y: CGFloat) -> CGAffineTransform {
        var transform: CGAffineTransform = .identity
        transform.c = -x
        transform.b = y
        return transform
    }
    // swiftlint:enable identifier_name
    
    /// 将 `CALayerContentsGravity` 转为 `UIView.ContentMode`
    public static func contentMode(for gravity: CALayerContentsGravity) -> UIView.ContentMode {
        return caGravityToUIViewContentModeMap[gravity] ?? .scaleToFill
    }
    
    /// 将 `UIView.ContentMode` 转为 `CALayerContentsGravity`
    public static func gravity(for contentMode: UIView.ContentMode) -> CALayerContentsGravity {
        switch contentMode {
        case .scaleToFill:
            return .resize
        case .scaleAspectFit:
            return .resizeAspect
        case .scaleAspectFill:
            return .resizeAspectFill
        case .redraw:
            return .resize
        case .center:
            return .center
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .left:
            return .left
        case .right:
            return .right
        case .topLeft:
            return .topLeft
        case .topRight:
            return .topRight
        case .bottomLeft:
            return .bottomLeft
        case .bottomRight:
            return .bottomRight
        default:
            return .resize
        }
    }
    
    /// 返回一个适合指定内容模式的 `rect` 的矩形
    public static func fitRect(for contentMode: UIView.ContentMode, rect: CGRect, size: CGSize) -> CGRect {
        
        var standardized = rect.standardized
        var size = size
        
        size.width = size.width < 0 ? -size.width : size.width
        size.height = size.height < 0 ? -size.height : size.height
        let center = CGPoint(x: standardized.midX, y: standardized.midY)
        switch contentMode {
        case .scaleAspectFit, .scaleAspectFill:
            if standardized.size.width < 0.01 ||
                standardized.size.height < 0.01 ||
                size.width < 0.01 ||
                size.height < 0.01 {
                standardized.origin = center
                standardized.size = CGSize.zero
            } else {
                var scale: CGFloat
                if contentMode == .scaleAspectFit {
                    if size.width / size.height < standardized.size.width / standardized.size.height {
                        scale = standardized.size.height / size.height
                    } else {
                        scale = standardized.size.width / size.width
                    }
                } else {
                    if size.width / size.height < standardized.size.width / standardized.size.height {
                        scale = standardized.size.width / size.width
                    } else {
                        scale = standardized.size.height / size.height
                    }
                }
                size.width *= scale
                size.height *= scale
                standardized.size = size
                standardized.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
            }
        case .center:
            standardized.size = size
            standardized.origin = CGPoint(x: center.x - size.width * 0.5, y: center.y - size.height * 0.5)
        case .top:
            standardized.origin.x = center.x - size.width * 0.5
            standardized.size = size
        case .bottom:
            standardized.origin.x = center.x - size.width * 0.5
            standardized.origin.y += standardized.size.height - size.height
            standardized.size = size
        case .left:
            standardized.origin.y = center.y - size.height * 0.5
        case .right:
            standardized.origin.y = center.y - size.height * 0.5
            standardized.origin.x += standardized.size.width - size.width
            standardized.size = size
        case .topLeft:
            standardized.size = size
        case .topRight:
            standardized.origin.x += standardized.size.width - size.width
            standardized.size = size
        case .bottomLeft:
            standardized.origin.y += standardized.size.height - size.height
            standardized.size = size
        case .bottomRight:
            standardized.origin.x += standardized.size.width - size.width
            standardized.origin.y += standardized.size.height - size.height
            standardized.size = size
        case .scaleToFill, .redraw:
            return rect
        default:
            return rect
        }
        return standardized
    }
}

extension UIViewController {
    
    fileprivate var topVC: UIViewController {
        if let vc = self.presentedViewController {
            return vc.topVC
        } else if let vc = (self as? UITabBarController)?.selectedViewController {
            return vc.topVC
        } else if let vc = (self as? UINavigationController)?.visibleViewController {
            return vc.topVC
        }
        return self
    }
}
