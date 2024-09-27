//
//  UIImage+Additionals.swift
//  AttributedText
//
//  Created by Sun on 2023/6/29.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

extension UIImage {
    
    /// Create UIImage from color and size.
    ///
    /// - Parameters:
    ///   - color: image fill color.
    ///   - size: image size.
    convenience init(color: UIColor, size: CGSize) {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        guard let aCgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else {
            self.init()
            return
        }
        
        self.init(cgImage: aCgImage)
    }
    
    static func image(with size: CGSize, drawBlock: ((CGContext) -> Void)?) -> UIImage? {
        guard let drawBlock = drawBlock else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            drawBlock(context.cgContext)
        }
    }
}
