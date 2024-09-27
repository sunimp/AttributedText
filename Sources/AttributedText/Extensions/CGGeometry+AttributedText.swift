//
//  CGGeometry+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import Darwin

extension CGFloat {
    
    // MARK: - CGFloat
    
    /// 将角度转换为弧度
    @inline(__always)
    public func toRadians() -> CGFloat {
        return self * .pi / 180
    }
    
    /// 将弧度转换为角度
    @inline(__always)
    public func toDegrees() -> CGFloat {
        return self * 180 / .pi
    }
    
    /// 将点转为像素
    @inline(__always)
    public func toPixel() -> CGFloat {
        return self * TextUtilities.screenScale
    }
    
    /// 将像素转为点
    @inline(__always)
    public func toPoint() -> CGFloat {
        return self / TextUtilities.screenScale
    }
    
    /// 获取以像素对齐的 floor 后的点值
    @inline(__always)
    public func floorFlattened() -> CGFloat {
        let scale = TextUtilities.screenScale
        return Darwin.floor(self * scale) / scale
    }
    
    /// 获取以像素对齐的 round 后的点值
    @inline(__always)
    public func roundFlattened() -> CGFloat {
        let scale = TextUtilities.screenScale
        return Darwin.round(self * scale) / scale
    }
    
    /// 获取以像素对齐的 ceil 后的点值
    @inline(__always)
    public func ceilFlattened() -> CGFloat {
        let scale = TextUtilities.screenScale
        return Darwin.ceil(self * scale) / scale
    }
    
    /// 将点值四舍五入为 0.5 像素
    ///
    /// 用于路径描边(奇数像素线宽像素对齐)
    @inline(__always)
    public func halfPixelFlattened() -> CGFloat {
        let scale = TextUtilities.screenScale
        return (Darwin.floor(self * scale) + 0.5) / scale
    }
    
}

extension CGPoint {
    
    // MARK: - CGPoint
    
    /// 获取以像素对齐的 floor 后的点值
    @inline(__always)
    public func floorFlattened() -> CGPoint {
        return CGPoint(x: self.x.floorFlattened(), y: self.y.floorFlattened())
    }
    
    /// 获取以像素对齐的 round 后的点值
    @inline(__always)
    public func roundFlattened() -> CGPoint {
        return CGPoint(x: self.x.roundFlattened(), y: self.y.roundFlattened())
    }
    
    /// 获取以像素对齐的 ceil 后的点值
    @inline(__always)
    public func ceilFlattened() -> CGPoint {
        return CGPoint(x: self.x.ceilFlattened(), y: self.y.ceilFlattened())
    }
    
    /// 将点值四舍五入为 0.5 像素
    ///
    /// 用于路径描边(奇数像素线宽像素对齐)
    @inline(__always)
    public func halfPixelFlattened() -> CGPoint {
        return CGPoint(x: self.x.halfPixelFlattened(), y: self.y.halfPixelFlattened())
    }
 
    /// Returns the distance between two points.
    @inline(__always)
    public func distance(toPoint other: CGPoint) -> CGFloat {
        return sqrt((self.x - other.x) * (self.x - other.x) + (self.y - other.y) * (self.y - other.y))
    }
    
    /// Returns the minmium distance between a point to a rectangle.
    @inline(__always)
    public func distance(toRect rect: CGRect) -> CGFloat {
        let newRect = rect.standardized
        if newRect.contains(self) {
            return 0
        }
        var distV: CGFloat
        var distH: CGFloat
        if newRect.minY <= self.y && self.y <= newRect.maxY {
            distV = 0
        } else {
            distV = self.y < newRect.minY ? newRect.minY - self.y : self.y - newRect.maxY
        }
        if newRect.minX <= self.x && self.x <= newRect.maxX {
            distH = 0
        } else {
            distH = self.x < newRect.minX ? newRect.minX - self.x : self.x - newRect.maxX
        }
        return max(distV, distH)
    }
}

extension CGSize {
    
    // MARK: - CGSize
    
    /// 获取以像素对齐的 floor 后的点值
    @inline(__always)
    public func floorFlattened() -> CGSize {
        return CGSize(width: self.width.floorFlattened(), height: self.height.floorFlattened())
    }
    
    /// 获取以像素对齐的 round 后的点值
    @inline(__always)
    public func roundFlattened() -> CGSize {
        return CGSize(width: self.width.roundFlattened(), height: self.height.roundFlattened())
    }
    
    /// 获取以像素对齐的 ceil 后的点值
    @inline(__always)
    public func ceilFlattened() -> CGSize {
        return CGSize(width: self.width.ceilFlattened(), height: self.height.ceilFlattened())
    }
    
    /// 将点值四舍五入为 0.5 像素
    ///
    /// 用于路径描边(奇数像素线宽像素对齐)
    @inline(__always)
    public func halfPixelFlattened() -> CGSize {
        return CGSize(width: self.width.halfPixelFlattened(), height: self.height.halfPixelFlattened())
    }
}

extension CGRect {
    
    // MARK: - CGRect
    
    /// 获取以像素对齐的 floor 后的点值
    @inline(__always)
    public func floorFlattened() -> CGRect {
        return CGRect(origin: self.origin.floorFlattened(), size: self.size.floorFlattened())
    }
    
    /// 获取以像素对齐的 round 后的点值
    @inline(__always)
    public func roundFlattened() -> CGRect {
        return CGRect(origin: self.origin.roundFlattened(), size: self.size.roundFlattened())
    }
    
    /// 获取以像素对齐的 ceil 后的点值
    @inline(__always)
    public func ceilFlattened() -> CGRect {
        return CGRect(origin: self.origin.ceilFlattened(), size: self.size.ceilFlattened())
    }
    
    /// 将点值四舍五入为 0.5 像素
    ///
    /// 用于路径描边(奇数像素线宽像素对齐)
    @inline(__always)
    public func halfPixelFlattened() -> CGRect {
        return CGRect(origin: self.origin.halfPixelFlattened(), size: self.size.halfPixelFlattened())
    }
    
    /// Returns the area of the rectangle.
    @inline(__always)
    public func getArea() -> CGFloat {
        var rect = self
        if rect.isNull {
            return 0
        }
        rect = rect.standardized
        return rect.size.width * rect.size.height
    }
}

extension UIEdgeInsets {
    
    // MARK: - UIEdgeInsets
    
    /// 获取以像素对齐的 floor 后的点值
    @inline(__always)
    public func floorFlattened() -> UIEdgeInsets {
        return UIEdgeInsets(
            top: self.top.floorFlattened(),
            left: self.left.floorFlattened(),
            bottom: self.bottom.floorFlattened(),
            right: self.right.floorFlattened()
        )
    }
    
    /// 获取以像素对齐的 round 后的点值
    @inline(__always)
    public func roundFlattened() -> UIEdgeInsets {
        return UIEdgeInsets(
            top: self.top.roundFlattened(),
            left: self.left.roundFlattened(),
            bottom: self.bottom.roundFlattened(),
            right: self.right.roundFlattened()
        )
    }
    
    /// 获取以像素对齐的 ceil 后的点值
    @inline(__always)
    public func ceilFlattened() -> UIEdgeInsets {
        return UIEdgeInsets(
            top: self.top.ceilFlattened(),
            left: self.left.ceilFlattened(),
            bottom: self.bottom.ceilFlattened(),
            right: self.right.ceilFlattened()
        )
    }
    
    /// 将点值四舍五入为 0.5 像素
    ///
    /// 用于路径描边(奇数像素线宽像素对齐)
    @inline(__always)
    public func halfPixelFlattened() -> UIEdgeInsets {
        return UIEdgeInsets(
            top: self.top.halfPixelFlattened(),
            left: self.left.halfPixelFlattened(),
            bottom: self.bottom.halfPixelFlattened(),
            right: self.right.halfPixelFlattened()
        )
    }
    
    /// 翻转一个 `UIEdgeInsets`
    @inline(__always)
    public func inverted() -> UIEdgeInsets {
        return UIEdgeInsets(top: -self.top, left: -self.left, bottom: -self.bottom, right: -self.right)
    }
}

extension CFRange {
    
    // MARK: - CFRange
    
    /// 转成 NSRange
    @inline(__always)
    public func nsRange() -> NSRange {
        return NSRange(location: self.location, length: self.length)
    }
}

extension NSRange {
    
    // MARK: - NSRange
    
    /// 转成 CFRange
    @inline(__always)
    public func cfRange() -> CFRange {
        return CFRangeMake(self.location, self.length)
    }
    
}

extension CGAffineTransform {
    
    // MARK: - CGAffineTransform
    
    /// 获取 `CGAffineTransform` 的旋转度数
    ///
    /// 以弧度为单位的旋转 [-PI, PI] ([-180°, 180°])
    ///
    @inline(__always)
    public func rotation() -> CGFloat {
        return atan2(self.b, self.a)
    }
    
    /// 获取 `CGAffineTransform` 的 scale.x
    @inline(__always)
    public func scaleX() -> CGFloat {
        return sqrt(self.a * self.a + self.c * self.c)
    }
    
    /// 获取 `CGAffineTransform` 的 scale.y
    @inline(__always)
    public func scaleY() -> CGFloat {
        return sqrt(self.b * self.b + self.d * self.d)
    }
}
