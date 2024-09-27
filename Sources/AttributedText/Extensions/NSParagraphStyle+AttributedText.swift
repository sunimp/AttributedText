//
//  NSParagraphStyle+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreText

/// 提供 `NSParagraphStyle` 的扩展以与 CoreText 配合使用
extension NSParagraphStyle {
    
    // swiftlint:disable function_body_length
    /// 从 CoreText 样式创建一个新的 NSParagraphStyle 对象
    public static func create(ctStyle: CTParagraphStyle) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        
        var lineSpacing: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .lineSpacingAdjustment,
            MemoryLayout<CGFloat>.size, &lineSpacing
        ) {
            style.lineSpacing = lineSpacing
        }
        
        var paragraphSpacing: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .paragraphSpacing,
            MemoryLayout<CGFloat>.size,
            &paragraphSpacing
        ) {
            style.paragraphSpacing = paragraphSpacing
        }
        
        var ctTextAlignment: CTTextAlignment?
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .alignment,
            MemoryLayout<CTTextAlignment>.size,
            &ctTextAlignment
        ) {
            if let ctTextAlignment {
                style.alignment = NSTextAlignment(ctTextAlignment)
            }
        }
        
        var firstLineHeadIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .firstLineHeadIndent,
            MemoryLayout<CGFloat>.size,
            &firstLineHeadIndent
        ) {
            style.firstLineHeadIndent = firstLineHeadIndent
        }
        
        var headIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .headIndent,
            MemoryLayout<CGFloat>.size,
            &headIndent
        ) {
            style.headIndent = headIndent
        }
        
        var tailIndent: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .tailIndent,
            MemoryLayout<CGFloat>.size,
            &tailIndent
        ) {
            style.tailIndent = tailIndent
        }
        
        var ctLineBreakMode: CTLineBreakMode?
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .lineBreakMode,
            MemoryLayout<CTLineBreakMode>.size,
            &ctLineBreakMode
        ) {
            if let ctLineBreakMode = ctLineBreakMode,
               let lineBreakMode = NSLineBreakMode(rawValue: Int(ctLineBreakMode.rawValue)) {
                style.lineBreakMode = lineBreakMode
            }
        }
        
        var minimumLineHeight: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .minimumLineHeight,
            MemoryLayout<CGFloat>.size,
            &minimumLineHeight
        ) {
            style.minimumLineHeight = minimumLineHeight
        }
        
        var maximumLineHeight: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .maximumLineHeight,
            MemoryLayout<CGFloat>.size,
            &maximumLineHeight
        ) {
            style.maximumLineHeight = maximumLineHeight
        }
        
        var ctWritingDirection: CTWritingDirection?
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .baseWritingDirection,
            MemoryLayout<CTWritingDirection>.size,
            &ctWritingDirection
        ) {
            if let writingDirection = ctWritingDirection,
               let baseWritingDirection = NSWritingDirection(rawValue: Int(writingDirection.rawValue)) {
                style.baseWritingDirection = baseWritingDirection
            }
        }
        
        var lineHeightMultiple: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .lineHeightMultiple,
            MemoryLayout<CGFloat>.size,
            &lineHeightMultiple
        ) {
            style.lineHeightMultiple = lineHeightMultiple
        }
        
        var paragraphSpacingBefore: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .paragraphSpacingBefore,
            MemoryLayout<CGFloat>.size,
            &paragraphSpacingBefore
        ) {
            style.paragraphSpacingBefore = paragraphSpacingBefore
        }
        
        let tabStopsPointer = UnsafeMutablePointer<CFArray>.allocate(capacity: MemoryLayout<CFArray>.size)
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .tabStops,
            MemoryLayout<CFArray>.size,
            tabStopsPointer) {
            
            if let ctTabStops = tabStopsPointer.pointee as? [CTTextTab] {
                let textTabs = ctTabStops.compactMap { ctTabStop in
                    if let options = CTTextTabGetOptions(ctTabStop) as? [NSTextTab.OptionKey: Any] {
                        return NSTextTab(
                            textAlignment: NSTextAlignment(CTTextTabGetAlignment(ctTabStop)),
                            location: CGFloat(CTTextTabGetLocation(ctTabStop)),
                            options: options
                        )
                    }
                    return nil
                }
                style.tabStops = textTabs
            }
        }
        tabStopsPointer.deallocate()
        
        var defaultTabInterval: CGFloat = 0
        if CTParagraphStyleGetValueForSpecifier(
            ctStyle,
            .defaultTabInterval,
            MemoryLayout<CGFloat>.size,
            &defaultTabInterval
        ) {
            style.defaultTabInterval = defaultTabInterval
        }
        return style
    }
    
    /// 创建并返回 CoreText 段落样式
    public func ctStyle() -> CTParagraphStyle {
        var settings: [CTParagraphStyleSetting] = []
        
        let lineSpacing: CTParagraphStyleSetting? = withUnsafeBytes(of: self.lineSpacing) { spacing in
            if let baseAddress = spacing.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .lineSpacingAdjustment,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let lineSpacing {
            settings.append(lineSpacing)
        }
        
        let paragraphSpacing: CTParagraphStyleSetting? = withUnsafeBytes(of: self.paragraphSpacing) { spacing in
            if let baseAddress = spacing.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .paragraphSpacing,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let paragraphSpacing {
            settings.append(paragraphSpacing)
        }
        
        let ctAlignment = CTTextAlignment(self.alignment)
        let alignment: CTParagraphStyleSetting? = withUnsafeBytes(of: ctAlignment) { alignment in
            if let baseAddress = alignment.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .alignment,
                    valueSize: MemoryLayout<CTTextAlignment>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let alignment {
            settings.append(alignment)
        }
        
        let firstLineHeadIndent: CTParagraphStyleSetting? = withUnsafeBytes(of: self.firstLineHeadIndent) { indent in
            if let baseAddress = indent.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .firstLineHeadIndent,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let firstLineHeadIndent {
            settings.append(firstLineHeadIndent)
        }
        
        let headIndent: CTParagraphStyleSetting? = withUnsafeBytes(of: self.headIndent) { indent in
            if let baseAddress = indent.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .headIndent,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let headIndent {
            settings.append(headIndent)
        }
        
        let tailIndent: CTParagraphStyleSetting? = withUnsafeBytes(of: self.tailIndent) { indent in
            if let baseAddress = indent.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .tailIndent,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let tailIndent {
            settings.append(tailIndent)
        }
        
        let ctLineBreakMode = CTLineBreakMode(rawValue: UInt8(self.lineBreakMode.rawValue))
        let lineBreakMode: CTParagraphStyleSetting? = withUnsafeBytes(of: ctLineBreakMode) { breakMode in
            if let baseAddress = breakMode.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .lineBreakMode,
                    valueSize: MemoryLayout<CTLineBreakMode>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let lineBreakMode {
            settings.append(lineBreakMode)
        }
        
        let minimumLineHeight: CTParagraphStyleSetting? = withUnsafeBytes(of: self.minimumLineHeight) { lineHeight in
            if let baseAddress = lineHeight.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .minimumLineHeight,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let minimumLineHeight {
            settings.append(minimumLineHeight)
        }
        
        let maximumLineHeight: CTParagraphStyleSetting? = withUnsafeBytes(of: self.maximumLineHeight) { lineHeight in
            if let baseAddress = lineHeight.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .maximumLineHeight,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let maximumLineHeight {
            settings.append(maximumLineHeight)
        }
        
        let ctWritingDirection = CTWritingDirection(rawValue: Int8(self.baseWritingDirection.rawValue))
        let writingDirection: CTParagraphStyleSetting? = withUnsafeBytes(of: ctWritingDirection) { direction in
            if let baseAddress = direction.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .baseWritingDirection,
                    valueSize: MemoryLayout<CTWritingDirection>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let writingDirection {
            settings.append(writingDirection)
        }
        
        let lineHeightMultiple: CTParagraphStyleSetting? = withUnsafeBytes(of: self.lineHeightMultiple) { multiple in
            if let baseAddress = multiple.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .lineHeightMultiple,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let lineHeightMultiple {
            settings.append(lineHeightMultiple)
        }
        
        let paragraphSpacingBefore: CTParagraphStyleSetting? = withUnsafeBytes(of: self.paragraphSpacingBefore) { before in
            if let baseAddress = before.baseAddress {
                return CTParagraphStyleSetting(
                    spec: .paragraphSpacingBefore,
                    valueSize: MemoryLayout<CGFloat>.size,
                    value: baseAddress
                )
            } else {
                return nil
            }
        }
        if let paragraphSpacingBefore {
            settings.append(paragraphSpacingBefore)
        }
        
        if self.responds(to: #selector(getter: self.tabStops)) {
            let textTabs = self.tabStops.map { tabStop in
                return CTTextTabCreate(
                    CTTextAlignment(tabStop.alignment),
                    Double(tabStop.location),
                    tabStop.options as CFDictionary
                )
            }
            
            let tabStops: CTParagraphStyleSetting? = withUnsafeBytes(of: textTabs) { tabStops in
                if let baseAddress = tabStops.baseAddress {
                    return CTParagraphStyleSetting(
                        spec: .tabStops,
                        valueSize: MemoryLayout<[CTTextTab]>.size,
                        value: baseAddress
                    )
                } else {
                    return nil
                }
            }
            if let tabStops {
                settings.append(tabStops)
            }
            
            if self.responds(to: #selector(getter: self.defaultTabInterval)) {
                let defaultTabInterval: CTParagraphStyleSetting? = withUnsafeBytes(of: self.defaultTabInterval) { interval in
                    if let baseAddress = interval.baseAddress {
                        return CTParagraphStyleSetting(
                            spec: .defaultTabInterval,
                            valueSize: MemoryLayout<CGFloat>.size,
                            value: baseAddress
                        )
                    } else {
                        return nil
                    }
                }
                if let defaultTabInterval {
                    settings.append(defaultTabInterval)
                }
            }
        }
        
        return CTParagraphStyleCreate(settings, settings.count)
    }
    // swiftlint:enable function_body_length
}
