//
//  UndoRedoExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class UndoRedoExample: UIViewController, AttributedTextViewDelegate {
    
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
        
        let text = "You can shake the device to undo and redo."
        
        textView.text = text
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.size = view.size
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.delegate = self
        textView.isAllowsUndoAndRedo = true // Undo and Redo
        textView.maximumUndoLevel = 10 // Undo level
        textView.keyboardDismissMode = UIScrollView.KeyboardDismissMode.interactive
        
        let topBarHeight = (self.navigationController?.navigationBar.frame.maxY ?? 0)
        textViewInsets = UIEdgeInsets(top: topBarHeight, left: 0, bottom: 0, right: 0)
        textView.contentInset = textViewInsets
        textView.scrollIndicatorInsets = textView.contentInset
        view.addSubview(textView)
        
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.selectedRange = NSRange(location: text.length, length: 0)
        textView.becomeFirstResponder()
    }
    
    @objc
    func edit(_ item: UIBarButtonItem?) {
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
