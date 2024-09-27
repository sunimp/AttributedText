//
//  UIControl+Additionals.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

private var alBlockTargets: Int = 0

private class ControlBlockTarget: NSObject {
    
    var block: ((_ sender: Any?) -> Void)?
    var events: UIControl.Event?
    
    init(block: @escaping (_ sender: Any?) -> Void, events: UIControl.Event) {
        super.init()
        
        self.block = block
        self.events = events
    }
    
    @objc
    func invoke(_ sender: Any?) {
        block?(sender)
    }
}

extension UIControl {
    
    /**
     Removes all targets and actions for a particular event (or events)
     from an internal dispatch table.
     */
    @objc
    func removeAllTargets() {
        for object in allTargets {
            self.removeTarget(object, action: nil, for: .allEvents)
        }
    }
    
    /**
     Adds or replaces a target and action for a particular event (or events)
     to an internal dispatch table.
     
     @param target         The target object—that is, the object to which the
     action message is sent. If this is nil, the responder
     chain is searched for an object willing to respond to the
     action message.
     
     @param action         A selector identifying an action message. It cannot be NULL.
     
     @param controlEvents  A bitmask specifying the control events for which the
     action message is sent.
     */
    @objc
    func setTarget(_ target: Any?, action: Selector, forControlEvents controlEvents: UIControl.Event) {
        let targets = allTargets
        for currentTarget: Any? in targets {
            let actions = self.actions(forTarget: currentTarget, forControlEvent: controlEvents)
            for currentAction in actions ?? [] {
                removeTarget(currentTarget, action: NSSelectorFromString(currentAction), for: controlEvents)
            }
        }
        addTarget(target, action: action, for: controlEvents)
    }
    
    /**
     Adds a block for a particular event (or events) to an internal dispatch table.
     It will cause a strong reference to @a block.
     
     @param block          The block which is invoked then the action message is
     sent  (cannot be nil). The block is retained.
     
     @param controlEvents  A bitmask specifying the control events for which the
     action message is sent.
     */
    func addBlock(forControlEvents controlEvents: UIControl.Event, block: @escaping (_ sender: Any?) -> Void) {
        let target = ControlBlockTarget(block: block, events: controlEvents)
        addTarget(target, action: #selector(target.invoke(_:)), for: controlEvents)
        
        let targets = allUIControlBlockTargets()
        targets.add(target)
    }
    
    /**
     Adds or replaces a block for a particular event (or events) to an internal
     dispatch table. It will cause a strong reference to @a block.
     
     @param block          The block which is invoked then the action message is
     sent (cannot be nil). The block is retained.
     
     @param controlEvents  A bitmask specifying the control events for which the
     action message is sent.
     */
    @objc
    func setBlockForControlEvents(_ controlEvents: UIControl.Event, block: @escaping (_ sender: Any?) -> Void) {
        removeAllBlocks(forControlEvents: controlEvents)
        addBlock(forControlEvents: controlEvents, block: block)
    }
    
    /**
     Removes all blocks for a particular event (or events) from an internal
     dispatch table.
     
     @param controlEvents  A bitmask specifying the control events for which the
     action message is sent.
     */
    func removeAllBlocks(forControlEvents controlEvents: UIControl.Event) {
        
        let targets = allUIControlBlockTargets()
        var removes: [AnyHashable] = []
        for target in targets {
            if let target = target as? ControlBlockTarget, target.events == controlEvents {
                removes.append(target)
                self.removeTarget(target, action: #selector(target.invoke(_:)), for: controlEvents)
            }
        }
        
        targets.removeObjects(in: removes)
    }
    
    private func allUIControlBlockTargets() -> NSMutableArray {
        var targets = objc_getAssociatedObject(self, &alBlockTargets) as? NSMutableArray
        
        if targets == nil {
            targets = NSMutableArray()
            objc_setAssociatedObject(self, &alBlockTargets, targets, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return targets ?? NSMutableArray()
    }
}
