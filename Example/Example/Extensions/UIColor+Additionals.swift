//
//  UIColor+Additionals.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

extension UIColor {
    
    /// Hex Value convert to UIColor
    ///
    /// - Parameter hex: Hex Value
    public convenience init(hex: Int) {
        self.init(
            red: CGFloat((Float((hex & 0xff0000) >> 16)) / 255.0),
            green: CGFloat((Float((hex & 0xff00) >> 8)) / 255.0),
            blue: CGFloat((Float(hex & 0xff)) / 255.0),
            alpha: 1.0
        )
    }
    
    /// Hex String convert to UIColor
    ///
    /// - Parameter hexString: Hex String
    public static func colorWith(hexString: String?) -> UIColor {
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if let hexString = hexString, hexString.hexToRGBA(red: &red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        return UIColor.black
    }
    
    /// Hex Value convert to UIColor
    ///
    /// - Parameter hex: Hex Value
    public static func color(with hex: Int) -> UIColor {
        return UIColor(
            red: CGFloat((Float((hex & 0xff0000) >> 16)) / 255.0),
            green: CGFloat((Float((hex & 0xff00) >> 8)) / 255.0),
            blue: CGFloat((Float(hex & 0xff)) / 255.0),
            alpha: 1.0
        )
    }
    
    /// 颜色叠加
    public func color(byAdd add: UIColor?, blendMode: CGBlendMode) -> UIColor? {
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        )
        var pixel = [0]
        let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        context?.setFillColor(self.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        context?.setBlendMode(blendMode)
        context?.setFillColor(self.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        
        return UIColor(
            red: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0,
            alpha: CGFloat(pixel[3]) / 255.0
        )
    }
}
