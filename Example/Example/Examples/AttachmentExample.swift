//
//  AttachmentExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

import SDWebImage

class AttachmentExample: UIViewController, UIGestureRecognizerDelegate {
    
    private let label = MyAttributedLabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let text = NSMutableAttributedString()
        let font = UIFont.systemFont(ofSize: 16)
        
        do {
            let title = "This is UIImage attachment:"
            text.append(NSAttributedString(string: title, attributes: nil))
            
            var image = UIImage(named: "dribbble64_imageio")
            if let CGImage = image?.cgImage {
                image = UIImage(cgImage: CGImage, scale: 2, orientation: .up)
            }
            let attachText = NSMutableAttributedString.attachmentString(
                content: image,
                contentMode: .center,
                attachmentSize: image?.size ?? .zero,
                alignTo: font,
                alignment: .center
            )
            text.append(attachText)
            text.append(NSAttributedString(string: "\n", attributes: nil))
        }
        
        do {
            let title = "This is UIView attachment: "
            text.append(NSAttributedString(string: title, attributes: nil))
            
            let switcher = UISwitch()
            switcher.sizeToFit()
            
            let attachText = NSMutableAttributedString.attachmentString(
                content: switcher,
                contentMode: .center,
                attachmentSize: switcher.size,
                alignTo: font,
                alignment: .center
            )
            text.append(attachText)
            text.append(NSAttributedString(string: "\n", attributes: nil))
        }
        
        do {
            
            let title = "This is Animated Image attachment:"
            text.append(NSAttributedString(string: title, attributes: nil))
            
            let names = ["001@2x", "022@2x", "019@2x", "056@2x", "085@2x"]
            for name in names {
                guard let path = Bundle.main.path(
                    forResource: name,
                    ofType: "gif",
                    inDirectory: "Emoticon.bundle") else {
                    continue
                }
                guard let data = NSData(contentsOfFile: path) as Data? else {
                    continue
                }
                let image = SDAnimatedImage(data: data, scale: 2)
                image?.preloadAllFrames()
                let imageView = SDAnimatedImageView(image: image)
                let attachText = NSMutableAttributedString.attachmentString(
                    content: imageView,
                    contentMode: .center,
                    attachmentSize: imageView.size,
                    alignTo: font,
                    alignment: .center
                )
                text.append(attachText)
            }
            
            let image = SDAnimatedImage(named: "pia")
            image?.preloadAllFrames()
            let imageView = SDAnimatedImageView(image: image)
            imageView.autoPlayAnimatedImage = true
            imageView.startAnimating()
            
            let attachText = NSMutableAttributedString.attachmentString(
                content: imageView,
                contentMode: .center,
                attachmentSize: imageView.size,
                alignTo: font,
                alignment: .bottom
            )
            text.append(attachText)
            
            text.append(NSAttributedString(string: "\n", attributes: nil))
        }
        text.setFont(font)
        
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        label.textVerticalAlignment = TextVerticalAlignment.top
        label.size = CGSize(width: 260, height: 260)
        label.center = CGPoint(x: view.width / 2, y: view.height / 2)
        label.attributedText = text
        addSeeMoreButton()
        view.addSubview(label)
        
        label.layer.borderWidth = 0.5
        label.layer.borderColor = UIColor(red: 0.000, green: 0.463, blue: 1.000, alpha: 1.000).cgColor
        
        weak var wlabel = label
        let dot: UIView? = newDotView()
        dot?.center = CGPoint(x: label.width, y: label.height)
        dot?.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        if let dot = dot {
            label.addSubview(dot)
        }
        let gesture = MyGestureRecognizer()
        gesture.targetView = label
        gesture.action = { gesture, state in
            if state != MyGestureRecognizerState.moved {
                return
            }
            let width: CGFloat = gesture?.currentPoint.x ?? .zero
            let height: CGFloat = gesture?.currentPoint.y ?? .zero
            wlabel?.width = width < 30 ? 30 : width
            wlabel?.height = height < 30 ? 30 : height
        }
        gesture.delegate = self
        
        dot?.addGestureRecognizer(gesture)
    }
    
    func addSeeMoreButton() {
        let text = NSMutableAttributedString(string: "...more")
        
        let hi = TextHighlight()
        hi.color = UIColor(red: 0.578, green: 0.790, blue: 1.000, alpha: 1.000)
        hi.tapAction = { [weak self] _, _, _, _ in
            guard let self else { return }
            self.label.sizeToFit()
        }
        
        text.setTextColor(UIColor(red: 0.000, green: 0.449, blue: 1.000, alpha: 1.000),
            range: (text.string as NSString).range(of: "more")
        )
        text.setTextHighlight(
            hi,
            range: (text.string as NSString).range(of: "more")
        )
        text.setFont(self.label.font)
        
        let seeMore = AttributedLabel()
        seeMore.attributedText = text
        seeMore.sizeToFit()
        
        let truncationToken = NSAttributedString.attachmentString(
            content: seeMore,
            contentMode: .center,
            attachmentSize: seeMore.size,
            alignTo: text.font,
            alignment: .center
        )
        self.label.truncationToken = truncationToken
    }
    
    func newDotView() -> UIView? {
        let view = UIView()
        view.size = CGSize(width: 50, height: 50)
        
        let dot = UIView()
        dot.size = CGSize(width: 10, height: 10)
        dot.backgroundColor = UIColor(red: 0.000, green: 0.463, blue: 1.000, alpha: 1.000)
        dot.clipsToBounds = true
        dot.layer.cornerRadius = dot.height / 2
        dot.center = CGPoint(x: view.width / 2, y: view.height / 2)
        view.addSubview(dot)
        
        return view
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point: CGPoint = gestureRecognizer.location(in: label)
        if point.x < label.width - 20 {
            return false
        }
        if point.y < label.height - 20 {
            return false
        }
        return true
    }
}
