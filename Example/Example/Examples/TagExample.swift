//
//  TagExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class TagExample: UIViewController, AttributedTextViewDelegate {
    
    private let textView = AttributedTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        if #available(iOS 11.0, *) {
            textView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let text = NSMutableAttributedString()
        let tags = [
            "◉red",
            "◉orange",
            "◉yellow",
            "◉green",
            "◉blue",
            "◉purple",
            "◉gray"
        ]
        let tagStrokeColors: [UIColor] = [
            UIColor(hex: 0xfa3f39),
            UIColor(hex: 0xf48f25),
            UIColor(hex: 0xf1c02c),
            UIColor(hex: 0x54bc2e),
            UIColor(hex: 0x29a9ee),
            UIColor(hex: 0xc171d8),
            UIColor(hex: 0x818e91)
        ]
        let tagFillColors: [UIColor] = [
            UIColor(hex: 0xfb6560),
            UIColor(hex: 0xf6a550),
            UIColor(hex: 0xf3cc56),
            UIColor(hex: 0x76c957),
            UIColor(hex: 0x53baf1),
            UIColor(hex: 0xcd8ddf),
            UIColor(hex: 0xa4a4a7)
        ]
        let font = UIFont.boldSystemFont(ofSize: 16)
        for index in 0..<tags.count {
            let tag = tags[index]
            let tagStrokeColor: UIColor? = tagStrokeColors[index]
            let tagFillColor: UIColor? = tagFillColors[index]
            let tagText = NSMutableAttributedString(string: tag)
            tagText.insertString("   ", at: 0)
            tagText.appendString("   ")
            tagText.setFont(font)
            tagText.setTextColor(UIColor.white)
            tagText.setTextBinding(TextBinding(isDeleteConfirm: false), range: tagText.rangeOfAll)
            
            let border = TextBorder()
            border.strokeWidth = 1.5
            border.strokeColor = tagStrokeColor
            border.fillColor = tagFillColor
            border.cornerRadius = 100 // a huge value
            border.lineJoin = CGLineJoin.bevel
            
            border.insets = UIEdgeInsets(top: -2, left: -5.5, bottom: -2, right: -8)
            tagText.setTextBackgroundBorder(border, range: (tagText.string as NSString).range(of: tag))
            
            text.append(tagText)
        }
        text.setLineSpacing(10)
        text.setLineBreakMode(.byWordWrapping)
        
        text.appendString("\n")
        text.append(text) // repeat for test
        
        textView.attributedText = text
        textView.size = view.size
        let topBarHeight = (self.navigationController?.navigationBar.frame.maxY ?? 0)
        textView.textContainerInset = UIEdgeInsets(top: 10 + topBarHeight, left: 10, bottom: 10, right: 10)
        textView.isAllowsCopyAttributedString = true
        textView.isAllowsPasteAttributedString = true
        textView.delegate = self
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
        textView.scrollIndicatorInsets = textView.contentInset
        textView.selectedRange = NSRange(location: text.length, length: 0)
        view.addSubview(textView)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.6) {
            self.textView.becomeFirstResponder()
        }
    }
    
    @objc
    private func edit(_ item: UIBarButtonItem?) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    // MARK: AttributedTextViewDelegate
    
    func textViewDidBeginEditing(_ textView: AttributedTextView) {
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.edit(_:)))
        navigationItem.rightBarButtonItem = buttonItem
    }
    
    func textViewDidEndEditing(_ textView: AttributedTextView) {
        navigationItem.rightBarButtonItem = nil
    }
}
