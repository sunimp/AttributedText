//
//  MyAttributedLabel.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class MyAttributedLabel: AttributedLabel {

    /// 子视图超出本视图的部分也能接收事件
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    
        if !self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.01 {
            return nil
        }
        let resultView = super.hitTest(point, with: event)
        if resultView != nil {
            return resultView
        } else {
            for subView in self.subviews.reversed() {
                // 这里根据层级的不同，需要遍历的次数可能不同，看需求来写，我写的例子是一层的
                let convertPoint: CGPoint = subView.convert(point, from: self)
                let hitView = subView.hitTest(convertPoint, with: event)
                if hitView != nil {
                    return hitView
                }
            }
        }
        return nil
    }
}
