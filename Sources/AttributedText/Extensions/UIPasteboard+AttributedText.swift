//
//  UIPasteboard+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreServices
import UniformTypeIdentifiers

#if canImport(SDWebImage)
import SDWebImage
#endif

/// 扩展 UIPasteboard, 支持图片和属性字符串
extension UIPasteboard {
    /// 富文本类型
    public static let kUTTypeAttributedString = "com.webull.NSAttributedString"
    /// WebP 类型
    public static let kUTTypeWebP = "com.google.webp"
}

extension UIPasteboard {
    
    /// PNG file data
    public var pngData: Data? {
        get {
            return self.data(forPasteboardType: UTType.png.identifier)
        }
        set {
            if let data = newValue {
                self.setData(data, forPasteboardType: UTType.png.identifier)
            }
        }
    }
    
    /// JPEG file data
    public var jpgData: Data? {
        get {
            return self.data(forPasteboardType: UTType.jpeg.identifier)
        }
        set {
            if let data = newValue {
                self.setData(data, forPasteboardType: UTType.jpeg.identifier)
            }
        }
    }
    
    /// GIF file data
    public var gifData: Data? {
        get {
            return self.data(forPasteboardType: UTType.gif.identifier)
        }
        set {
            if let data = newValue {
                self.setData(data, forPasteboardType: UTType.gif.identifier)
            }
        }
    }
    
    /// WebP file data
    public var webpData: Data? {
        get {
            return self.data(forPasteboardType: UTType.webP.identifier)
        }
        set {
            if let data = newValue {
                self.setData(data, forPasteboardType: UTType.webP.identifier)
            }
        }
    }
    
    /// image file data
    public var imageData: Data? {
        get {
            return self.data(forPasteboardType: UTType.image.identifier)
        }
        set {
            if let data = newValue {
                self.setData(data, forPasteboardType: UTType.image.identifier)
            }
        }
    }
    
    /// Attributed string,
    /// Set this attributed will also set the string property which is copy from the attributed string.
    /// If the attributed string contains one or more image, it will also set the `images` property.
    public var attributedString: NSAttributedString? {
        get {
            for item in self.items {
                if let data = item[UIPasteboard.kUTTypeAttributedString] as? Data {
                    return NSAttributedString.unarchive(from: data)
                }
            }
            return nil
        }
        set {
            guard let newValue = newValue else {
                return
            }
            
            self.string = newValue.plainText(for: newValue.rangeOfAll)
            if let data = newValue.archiveToData() {
                self.addItems([[UIPasteboard.kUTTypeAttributedString: data]])
            }
            
            newValue.enumerateAttribute(
                TextAttribute.textAttachment,
                in: NSRange(location: 0, length: newValue.length),
                options: .longestEffectiveRangeNotRequired
            ) { attachment, _, _ in
                guard let attachment = attachment as? TextAttachment else {
                    return
                }
                
                // save image
                var simpleImage: UIImage?
                if let image = attachment.content as? UIImage {
                    simpleImage = image
                } else if let imageView = attachment.content as? UIImageView {
                    simpleImage = imageView.image
                }

                if let image = simpleImage {
                    let item = ["com.apple.uikit.image": image]
                    self.addItems([item])
                }
                
                #if canImport(SDWebImage)
                // save animated image
                if let imageView = attachment.content as? UIImageView,
                   let image = imageView.image as? SDAnimatedImage {
                    if let data = image.animatedImageData {
                        let format = image.animatedImageFormat
                        switch format.rawValue {
                        case SDImageFormat.GIF.rawValue:
                            let key: String = {
                                if #available(iOS 14.0, *) {
                                    return UTType.gif.identifier
                                } else {
                                    return kUTTypeGIF as String
                                }
                            }()
                            let item = [key: data]
                            self.addItems([item])
                            
                        case SDImageFormat.PNG.rawValue:
                            // APNG
                            let key: String = {
                                if #available(iOS 14.0, *) {
                                    return UTType.png.identifier
                                } else {
                                    return kUTTypePNG as String
                                }
                            }()
                            let item = [key: data]
                            self.addItems([item])
                            
                        case SDImageFormat.webP.rawValue:
                            let key: String = {
                                if #available(iOS 14.0, *) {
                                    return UTType.webP.identifier
                                } else {
                                    return UIPasteboard.kUTTypeWebP
                                }
                            }()
                            let item = [key: data]
                            self.addItems([item])
                            
                        default:
                            break
                        }
                    }
                }
                #endif
            }
        }
        
    }
}
