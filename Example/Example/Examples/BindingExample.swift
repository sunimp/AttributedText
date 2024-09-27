//
//  BindingExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

private class TextExampleEmailBindingParser: NSObject, TextParser {
    var regex: NSRegularExpression?
    
    override init() {
        super.init()
        
        let pattern = "[-_a-zA-Z@\\.]+[ ,\\n]"
        regex = try? NSRegularExpression(pattern: pattern, options: [])
    }
    
    func parseText(_ text: NSMutableAttributedString?, selectedRange range: NSRangePointer?) -> Bool {
        let text = text
        var changed = false
        if let rangeOfAll = text?.rangeOfAll {
            regex?.enumerateMatches(
                in: text?.string ?? "",
                options: .withoutAnchoringBounds,
                range: rangeOfAll,
                using: { result, _, _ in
                    if result == nil {
                        return
                    }
                    let range: NSRange? = result?.range
                    if (range?.location ?? 0) == NSNotFound || (range?.length ?? 0) < 1 {
                        return
                    }
                    if text?.attribute(TextAttribute.textBinding, at: range?.location ?? 0, effectiveRange: nil) != nil {
                        return
                    }
                    
                    let bindlingRange = NSRange(location: range?.location ?? 0, length: (range?.length ?? 0) - 1)
                    let binding = TextBinding(isDeleteConfirm: true)
                    text?.setTextBinding(binding, range: bindlingRange) // Text binding
                    text?.setTextColor(UIColor(red: 0.000, green: 0.519, blue: 1.000, alpha: 1.000), range: bindlingRange)
                    changed = true
                }
            )
        }
        return changed
    }
}

class BindingExample: UIViewController, AttributedTextViewDelegate {
    private var textView = AttributedTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        
        if #available(iOS 11.0, *) {
            textView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let text = NSMutableAttributedString(string: "sjobs@apple.com, apple@apple.com, banana@banana.com, pear@pear.com ")
        text.setFont(UIFont.systemFont(ofSize: 17))
        text.setLineSpacing(5)
        text.setTextColor(UIColor.black)
        
        textView.attributedText = text
        textView.textParser = TextExampleEmailBindingParser()
        textView.size = view.size
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.delegate = self
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
        let topBarHeight = (self.navigationController?.navigationBar.frame.maxY ?? 0)
        textView.contentInset = UIEdgeInsets(top: topBarHeight, left: 0, bottom: 0, right: 0)
        textView.scrollIndicatorInsets = textView.contentInset
        view.addSubview(textView)
        
        textView.becomeFirstResponder()
    }
    
    @objc
    private func edit(_ item: UIBarButtonItem?) {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        } else {
            textView.becomeFirstResponder()
        }
    }
    
    // MARK: - AttributedTextViewDelegate
    
    func textViewDidChange(_ textView: AttributedTextView) {
        if textView.text.length == 0 {
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidBeginEditing(_ textView: AttributedTextView) {
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(edit(_:)))
        navigationItem.rightBarButtonItem = buttonItem
    }
    
    func textViewDidEndEditing(_ textView: AttributedTextView) {
        navigationItem.rightBarButtonItem = nil
    }
}
