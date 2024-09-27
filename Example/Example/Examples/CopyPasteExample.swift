//
//  CopyPasteExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/28.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class CopyPasteExample: UIViewController, AttributedTextViewDelegate {
    private var textView = AttributedTextView()
    private var textViewInsets = UIEdgeInsets.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground

        if #available(iOS 11.0, *) {
            textView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let text = """
        You can copy image from browser or photo album and paste it to here. \
        It support animated GIF and APNG. \n\nYou can also copy attributed string from other AttributedTextView.\n
        """
        
        let parser = TextSimpleMarkdownParser()
        parser.setColorWithDarkTheme()
        
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.size = view.size
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.delegate = self
        textView.isAllowsPasteImage = true // Pasts image
        textView.isAllowsPasteAttributedString = true // Paste attributed string
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
        let topBarHeight = (self.navigationController?.navigationBar.frame.maxY ?? 0)
        textViewInsets = UIEdgeInsets(top: topBarHeight, left: 0, bottom: 0, right: 0)
        textView.contentInset = textViewInsets
        textView.scrollIndicatorInsets = textView.contentInset
        view.addSubview(textView)
        
        textView.selectedRange = NSRange(location: text.length, length: 0)
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
    
    func textViewDidBeginEditing(_ textView: AttributedTextView) {
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(edit(_:)))
        navigationItem.rightBarButtonItem = buttonItem

        textView.contentInset = textViewInsets
    }
    
    func textViewDidEndEditing(_ textView: AttributedTextView) {
        navigationItem.rightBarButtonItem = nil
        
        textView.contentInset = textViewInsets
    }
}
