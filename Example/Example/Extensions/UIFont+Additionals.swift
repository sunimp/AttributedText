//
//  UIFont+Additionals.swift
//  AttributedText-Example
//
//  Created by Sun on 2024/9/26.
//

import UIKit

extension UIFont {
    
    /// 获取字体的粗体版本
    @inline(__always)
    public func traitBold() -> UIFont? {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: descriptor, size: self.pointSize)
        }
        return nil
    }
    
    /// 获取字体的斜体版本
    @inline(__always)
    public func traitItalic() -> UIFont? {
        if let descriptor = self.fontDescriptor.withSymbolicTraits(.traitItalic) {
            return UIFont(descriptor: descriptor, size: self.pointSize)
        }
        return nil
    }
    
    /// 获取字体的粗斜体版本
    @inline(__always)
    public func traitBoldItalic() -> UIFont? {
        if let descriptor = self.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
            return UIFont(descriptor: descriptor, size: self.pointSize)
        }
        return nil
    }
    
}
