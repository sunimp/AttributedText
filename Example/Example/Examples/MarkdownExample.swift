//
//  MarkdownExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class MarkdownExample: UIViewController, AttributedTextViewDelegate {
    
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
        #Markdown Editor\nThis is a simple markdown editor based on\
        `AttributedTextView`.\n\n*********************************************\n\
        It\'s *italic* style.\n\n\
        It\'s also _italic_ style.\n\n\
        It\'s **bold** style.\n\n\
        It\'s ***italic and bold*** style.\n\n\
        It\'s __underline__ style.\n\n\
        It\'s ~~deleteline~~ style.\n\n\n\
        Here is a link: [github](https://github.com/)\n\n\
        Here is some code:\n\n\tif(a){\n\t\tif(b){\n\t\t\tif(c){\n\t\t\t\tprintf(\"haha\");\n\t\t\t}\n\t\t}\n\t}\n
        """
        
        let parser = TextSimpleMarkdownParser()
//        parser.setColorWithDarkTheme()
        
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textParser = parser
        textView.size = view.size
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.delegate = self
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
        textView.backgroundColor = .systemBackground
        textViewInsets = UIEdgeInsets(
            top: self.navigationController?.navigationBar.frame.maxY ?? 0,
            left: 0,
            bottom: 0,
            right: 0
        )
        textView.contentInset = textViewInsets
        textView.scrollIndicatorInsets = textView.contentInset
        textView.selectedRange = NSRange(location: text.length, length: 0)
        view.addSubview(textView)
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
        let buttonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.edit(_:)))
        navigationItem.rightBarButtonItem = buttonItem

        textView.contentInset = textViewInsets
    }
    
    func textViewDidEndEditing(_ textView: AttributedTextView) {
        navigationItem.rightBarButtonItem = nil

        textView.contentInset = textViewInsets
    }
}
