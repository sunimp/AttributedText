//
//  RubyExample.swift
//  AttributedText
//
//  Created by Sun on 2023/6/28.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

import SnapKit

class RubyExample: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground

        let text = NSMutableAttributedString()
        
        var one = NSMutableAttributedString(string: "这是用汉语写的一段文字。")
        one.setFont(UIFont.boldSystemFont(ofSize: 30))
        
        var ruby: TextRubyAnnotation
        ruby = TextRubyAnnotation()
        ruby.textBefore = "hàn yŭ"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "汉语"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "wén"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "文"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "zì"
        ruby.alignment = CTRubyAlignment.center
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "字"))
        
        text.append(one)
        text.append(padding())
        
        one = NSMutableAttributedString(string: "日本語で書いた作文です。")
        one.setFont(UIFont.boldSystemFont(ofSize: 30))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "に"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "日"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "ほん"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "本"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "ご"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "語"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "か"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "書"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "さく"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "作"))
        
        ruby = TextRubyAnnotation()
        ruby.textBefore = "ぶん"
        one.setTextRubyAnnotation(ruby, range: (one.string as NSString).range(of: "文"))
        text.append(one)
        
        let label = AttributedLabel()
        label.attributedText = text
        label.textAlignment = .center
        label.textVerticalAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = UIColor(white: 0.933, alpha: 1.000)
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(30)
            make.top.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(30)
        }
    }

    func padding() -> NSAttributedString {
        let pad = NSMutableAttributedString(string: "\n\n")
        pad.setFont(UIFont.systemFont(ofSize: 30))
        return pad
    }
}
