//
//  DebugSwitch.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class DebugSwitch: UISwitch {
    
    private static let isDebugOnKey = "com.sunimp.attributedText.isDebugEnabled"
    
    override var isOn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Self.isDebugOnKey)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Self.isDebugOnKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        self.addTarget(self, action: #selector(self.checkDebug), for: .valueChanged)
        
        self.isOn = self.isOn
        updateDebug()
    }
    
    @objc
    private func checkDebug(_ sender: UISwitch) {
        self.isOn = !self.isOn
        updateDebug()
    }
    
    private func updateDebug() {

        let debugOptions = TextDebugOption()
        if self.isOn {
            debugOptions.baselineColor = .red
            debugOptions.ctFrameBorderColor = .red
            debugOptions.ctLineFillColor = UIColor(red: 0.000, green: 0.463, blue: 1.000, alpha: 0.180)
            debugOptions.cgGlyphBorderColor = UIColor(red: 1.000, green: 0.524, blue: 0.000, alpha: 0.200)
        } else {
            debugOptions.clear()
        }
        TextDebugOption.setSharedDebugOption(debugOptions)
    }
}
