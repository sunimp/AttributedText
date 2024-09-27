//
//  AttributeExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/28.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

import SnapKit

class AttributeExample: UIViewController {
    
    // swiftlint:disable:next function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        let text = NSMutableAttributedString()
        
        do {
            let one = NSMutableAttributedString(string: "Shadow")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor.white)
            let shadow = TextShadow()
            shadow.color = UIColor(white: 0.000, alpha: 0.490)
            shadow.offset = CGSize(width: 0, height: 1)
            shadow.radius = 5
            one.setTextShadow(shadow)
            text.append(one)
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Inner Shadow")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor.white)
            let shadow = TextShadow()
            shadow.color = UIColor(white: 0.000, alpha: 0.40)
            shadow.offset = CGSize(width: 0, height: 1)
            shadow.radius = 1
            one.setTextInnerShadow(shadow)
            text.append(one)
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Multiple Shadows")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor(red: 1.000, green: 0.795, blue: 0.014, alpha: 1.000))
            
            let shadow = TextShadow()
            shadow.color = UIColor(white: 0.000, alpha: 0.20)
            shadow.offset = CGSize(width: 0, height: -1)
            shadow.radius = 1.5
            let subShadow = TextShadow()
            subShadow.color = UIColor(white: 1, alpha: 0.99)
            subShadow.offset = CGSize(width: 0, height: 1)
            subShadow.radius = 1.5
            shadow.subShadow = subShadow
            one.setTextShadow(shadow)
            
            let innerShadow = TextShadow()
            innerShadow.color = UIColor(red: 0.851, green: 0.311, blue: 0.000, alpha: 0.780)
            innerShadow.offset = CGSize(width: 0, height: 1)
            innerShadow.radius = 1
            one.setTextInnerShadow(innerShadow)
            
            text.append(one)
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Background Image")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor(red: 1.000, green: 0.795, blue: 0.014, alpha: 1.000))
            
            let size = CGSize(width: 20, height: 20)
            let background = UIImage.image(with: size) { context in
                let c0 = UIColor(red: 0.054, green: 0.879, blue: 0.000, alpha: 1.000)
                let c1 = UIColor(red: 0.869, green: 1.000, blue: 0.030, alpha: 1.000)
                c0.setFill()
                context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
                c1.setStroke()
                context.setLineWidth(2)
                var index: CGFloat = 0
                while index < size.width * 2 {
                    context.move(to: CGPoint(x: index, y: -2))
                    context.addLine(to: CGPoint(x: index - size.height, y: size.height + 2))
                    index += 4
                }
                context.strokePath()
            }
            if let background = background {
                one.setTextColor(UIColor(patternImage: background))
            }
            
            text.append(one)
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Border")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor(red: 1.000, green: 0.029, blue: 0.651, alpha: 1.000))
            
            let border = TextBorder()
            border.strokeColor = UIColor(red: 1.000, green: 0.029, blue: 0.651, alpha: 1.000)
            border.strokeWidth = 3
            border.lineStyle = TextLineStyle.patternCircleDot
            border.cornerRadius = 3
            border.insets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
            one.setTextBackgroundBorder(border)
            
            text.append(padding())
            text.append(one)
            text.append(padding())
            text.append(padding())
            text.append(padding())
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Link")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setUnderlineStyle(NSUnderlineStyle.single)
            
            // 1. you can set a highlight with these code
            /*
             one.setTextColor(UIColor(red: 0.093, green: 0.492, blue: 1.000, alpha: 1.000))
             
             let border = TextBorder()
             border.cornerRadius = 3
             border.insets = UIEdgeInsets(top: -2, left: -1, bottom: -2, right: -1)
             border.fillColor = UIColor(white: 0, alpha: 0.22)
             
             let highlight = TextHighlight()
             highlight.border = border
             highlight.tapAction = { containerView, text, range, rect in
                _self?.showMessage("Tap: \((text?.string as NSString?)?.substring(with: range) ?? "")")
             }
             one.setTextHighlight(highlight, range: one.rangeOfAll)
             */
            
            // 2. or you can use the convenience method
            one.setTextHighlightRange(
                one.rangeOfAll,
                color: UIColor(red: 0.093, green: 0.492, blue: 1.000, alpha: 1.000),
                backgroundColor: UIColor(white: 0.000, alpha: 0.220),
                tapAction: { [weak self] _, text, range, _ in
                    guard let self else { return }
                    self.showMessage("Tap: \((text.string as NSString).substring(with: range))")
                }
            )
            
            text.append(one)
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Another Link")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor.red)
            
            let border = TextBorder()
            border.cornerRadius = 50
            border.insets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
            border.strokeWidth = 0.5
            border.strokeColor = one.textColor
            border.lineStyle = TextLineStyle.single
            one.setTextBackgroundBorder(border)
            
            // swiftlint:disable:next force_cast
            let highlightBorder = border.copy() as! TextBorder
            highlightBorder.strokeWidth = 0
            highlightBorder.strokeColor = one.textColor
            highlightBorder.fillColor = one.textColor
            
            let highlight = TextHighlight()
            highlight.color = UIColor.white
            highlight.backgroundBorder = highlightBorder
            highlight.tapAction = { [weak self] _, text, range, _ in
                guard let self else { return }
                self.showMessage("Tap: \((text.string as NSString).substring(with: range))")
            }
            one.setTextHighlight(highlight, range: one.rangeOfAll)
            
            text.append(one)
            text.append(padding())
        }
        
        do {
            let one = NSMutableAttributedString(string: "Yet Another Link")
            one.setFont(UIFont.boldSystemFont(ofSize: 30))
            one.setTextColor(UIColor.white)
            
            let shadow = TextShadow()
            shadow.color = UIColor(white: 0.000, alpha: 0.490)
            shadow.offset = CGSize(width: 0, height: 1)
            shadow.radius = 5
            one.setTextShadow(shadow)
            
            let shadow0 = TextShadow()
            shadow0.color = UIColor(white: 0.000, alpha: 0.20)
            shadow0.offset = CGSize(width: 0, height: -1)
            shadow0.radius = 1.5
            let shadow1 = TextShadow()
            shadow1.color = UIColor(white: 1, alpha: 0.99)
            shadow1.offset = CGSize(width: 0, height: 1)
            shadow1.radius = 1.5
            shadow0.subShadow = shadow1
            
            let innerShadow0 = TextShadow()
            innerShadow0.color = UIColor(red: 0.851, green: 0.311, blue: 0.000, alpha: 0.780)
            innerShadow0.offset = CGSize(width: 0, height: 1)
            innerShadow0.radius = 1
            
            let highlight = TextHighlight()
            highlight.color = UIColor(red: 1.000, green: 0.795, blue: 0.014, alpha: 1.000)
            highlight.shadow = shadow0
            highlight.innerShadow = innerShadow0
            one.setTextHighlight(highlight, range: one.rangeOfAll)
            
            text.append(one)
        }
        
        let label = AttributedLabel()
        label.attributedText = text
        label.textAlignment = .center
        label.textVerticalAlignment = TextVerticalAlignment.center
        label.numberOfLines = 0
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.top.bottom.equalTo(self.view.safeAreaLayoutGuide)
        }
        
        /*
         If the 'highlight.tapAction' is not nil, the label will invoke 'highlight.tapAction'
         and ignore 'label.highlightTapAction'.
         
         If the 'highlight.tapAction' is nil, you can use 'highlightTapAction' to handle
         all tap action in this label.
         */
        label.highlightTapAction = { [weak self] _, text, range, _ in
            guard let self else { return }
            self.showMessage("Tap: \((text.string as NSString).substring(with: range))")
        }
    }
    
    func padding() -> NSAttributedString {
        let pad = NSMutableAttributedString(string: "\n\n")
        pad.setFont(UIFont.systemFont(ofSize: 4))
        return pad
    }
    
    func showMessage(_ msg: String) {
        let padding: CGFloat = 10
        
        let label = AttributedLabel()
        label.text = msg
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = NSTextAlignment.center
        label.textColor = UIColor.white
        label.backgroundColor = UIColor(red: 0.033, green: 0.685, blue: 0.978, alpha: 0.730)
        label.width = view.width
        label.textContainerInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        label.height = msg.height(for: label.font, width: label.width) + 2 * padding
        
        let topBarHeight = (self.navigationController?.navigationBar.frame.maxY ?? 0)
        label.bottom = topBarHeight
        view.addSubview(label)
        UIView.animate(withDuration: 0.3, animations: {
            label.top = topBarHeight
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 2, options: .curveEaseInOut, animations: {
                label.bottom = topBarHeight
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}
