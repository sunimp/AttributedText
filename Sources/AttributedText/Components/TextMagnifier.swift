//
//  TextMagnifier.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

private let magnifierCaptureDisableFadeTime = 0.1

/// A magnifier view which can be displayed in `TextEffectWindow`.
///
/// Use `magnifier(for:)` to create instance.
/// Typically, you should not use this class directly.
public class TextMagnifier: UIView {
    
    public static let magnification: CGFloat = 1.38
    public static let coverSize = CGSize(width: 115, height: 85)
    public static let innerPadding = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    public static var contentSize: CGSize {
        return CGSize(
            width: self.coverSize.width - self.innerPadding.left - self.innerPadding.right,
            height: self.coverSize.height - self.innerPadding.top - self.innerPadding.bottom
        )
    }
    public static var strokeBorderColor: UIColor = .systemBlue
    
    public private(set) static var image: UIImage?
    
    /// The 'best' size for magnifier view.
    public var fitSize: CGSize {
        return self.sizeThatFits(.zero)
    }
    
    /// The 'best' snapshot image size for magnifier.
    public var snapshotSize: CGSize {
        let width = floor(Self.coverSize.width / Self.magnification)
        let height = floor(Self.coverSize.height / Self.magnification)
        return CGSize(width: width, height: height)
    }
    
    /// The image in magnifier
    public var snapshot: UIImage? {
        get {
            return contentView.image
        }
        set {
            if isCaptureFadeAnimation {
                contentView.layer.removeAnimation(forKey: "contents")
                let animation = CABasicAnimation()
                animation.duration = magnifierCaptureDisableFadeTime
                animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
                contentView.layer.add(animation, forKey: "contents")
            }
            contentView.image = newValue
        }
    }
    
    /// The coordinate based view.
    public weak var hostView: UIView?
    /// The snapshot capture center in `hostView`.
    public var hostCaptureCenter: CGPoint = .zero
    /// The popover center in `hostView`.
    public var hostPopoverCenter: CGPoint = .zero
    /// The host view is vertical form.
    public var isHostVerticalForm: Bool = false
    /// A hint for `TextEffectWindow` to disable capture.
    public var isCaptureDisabled: Bool = false
    /// Show fade animation when the snapshot image changed.
    public var isCaptureFadeAnimation = false
    
    /// 内容
    public private(set) var contentView: UIImageView = UIImageView()
    /// 外形
    public private(set) var coverView: UIImageView = UIImageView()
    
    /// 构造方法
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let coverRect = CGRect(origin: .zero, size: Self.coverSize)
        let contentRect = coverRect.inset(by: Self.innerPadding)
        self.contentView.frame = contentRect
        self.contentView.layer.cornerRadius = contentRect.height / 2
        self.contentView.clipsToBounds = true
        self.addSubview(self.contentView)
        
        self.coverView.frame = coverRect
        self.coverView.image = Self.coverImage()
        self.addSubview(self.coverView)
    }
    
    /// 遍历构造方法
    public convenience init() {
        self.init(frame: .zero)
        
        self.frame = CGRect(origin: .zero, size: self.sizeThatFits(.zero))
    }
    
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func coverImage() -> UIImage? {
        if let image = self.image {
            return image
        }
        
        let boxRect: CGRect = CGRect(origin: .zero, size: Self.coverSize)
        let fillRect = boxRect.inset(by: Self.innerPadding)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 0
        let renderer = UIGraphicsImageRenderer(size: boxRect.size, format: format)
        return renderer.image { context in
            let cgContext = context.cgContext
            let boxPath = CGPath(
                rect: boxRect,
                transform: nil
            )
            let fillPath = CGPath(
                roundedRect: fillRect,
                cornerWidth: fillRect.height / 2,
                cornerHeight: fillRect.height / 2,
                transform: nil
            )
            let strokeRect = fillRect.halfPixelFlattened()
            let strokePath = CGPath(
                roundedRect: strokeRect,
                cornerWidth: strokeRect.height / 2,
                cornerHeight: strokeRect.height / 2,
                transform: nil
            )
            
            // outer shadow
            cgContext.saveGState()
            do {
                let blurRadius: CGFloat = 18
                let offset = CGSize(width: 0, height: 4)
                let shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
                let opaqueShadowColor = shadowColor.copy(alpha: 1)
                cgContext.addPath(fillPath)
                cgContext.clip()
                cgContext.setAlpha(shadowColor.alpha)
                cgContext.beginTransparencyLayer(auxiliaryInfo: nil)
                if let opaqueShadowColor {
                    cgContext.setShadow(offset: offset, blur: blurRadius, color: opaqueShadowColor)
                    cgContext.setBlendMode(CGBlendMode.sourceOut)
                    cgContext.setFillColor(opaqueShadowColor)
                    cgContext.addPath(fillPath)
                    cgContext.fillPath()
                }
                cgContext.endTransparencyLayer()
            }
            cgContext.restoreGState()
            
            // outer shadow
            cgContext.saveGState()
            do {
                let blurRadius: CGFloat = 8
                let offset: CGSize = .zero
                let shadowColor = UIColor.black.withAlphaComponent(0.24).cgColor
                cgContext.addPath(boxPath)
                cgContext.addPath(fillPath)
                cgContext.clip(using: .evenOdd)
                cgContext.setShadow(offset: offset, blur: blurRadius, color: shadowColor)
                cgContext.beginTransparencyLayer(auxiliaryInfo: nil)
                do {
                    cgContext.addPath(fillPath)
                    UIColor(white: 0.7, alpha: 1).setFill()
                    cgContext.fillPath()
                }
                cgContext.endTransparencyLayer()
            }
            cgContext.restoreGState()
            
            // stroke
            cgContext.saveGState()
            cgContext.addPath(strokePath)
            Self.strokeBorderColor.setStroke()
            cgContext.setLineWidth(2)
            cgContext.strokePath()
            cgContext.restoreGState()
        }
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return Self.coverSize
    }
}
