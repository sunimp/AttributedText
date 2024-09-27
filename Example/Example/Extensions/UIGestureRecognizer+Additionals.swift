//
//  UIGestureRecognizer+Additionals.swift
//  AttributedText
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

private var blockKey: Int = 0

private class GestureRecognizerBlockTarget: NSObject {
    var block: ((_ sender: Any?) -> Void)?
    
    init(block: @escaping (_ sender: Any?) -> Void) {
        super.init()
        
        self.block = block
    }
    
    @objc
    func invoke(_ sender: Any?) {
        block?(sender)
    }
}

extension UIGestureRecognizer {
    /**
     Initializes an allocated gesture-recognizer object with a action block.
     
     @param block  An action block that to handle the gesture recognized by the
     receiver. nil is invalid. It is retained by the gesture.
     
     @return An initialized instance of a concrete UIGestureRecognizer subclass or
     nil if an error occurred in the attempt to initialize the object.
     */
    convenience init(actionBlock block: @escaping (_ sender: Any?) -> Void) {
        self.init()
        addActionBlock(block)
    }
    
    /**
     Adds an action block to a gesture-recognizer object. It is retained by the
     gesture.
     
     @param block A block invoked by the action message. nil is not a valid value.
     */
    func addActionBlock(_ block: @escaping (_ sender: Any?) -> Void) {
        let target = GestureRecognizerBlockTarget(block: block)
        addTarget(target, action: #selector(target.invoke(_:)))
        
        let targets = allUIGestureRecognizerBlockTargets()
        targets.add(target)
    }
    
    /**
     Remove all action blocks.
     */
    func removeAllActionBlocks() {
        let targets = allUIGestureRecognizerBlockTargets()
        for target in targets {
            guard let target = target as? GestureRecognizerBlockTarget else {
                return
            }
            self.removeTarget(target, action: #selector(target.invoke(_:)))
        }
        targets.removeAllObjects()
    }
    
    private func allUIGestureRecognizerBlockTargets() -> NSMutableArray {
        var targets = objc_getAssociatedObject(self, &blockKey) as? NSMutableArray
        
        if targets == nil {
            targets = NSMutableArray()
            objc_setAssociatedObject(self, &blockKey, targets, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return targets ?? []
    }
}
