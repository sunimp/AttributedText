//
//  TextTransaction.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import CoreFoundation

private var transactionSet = Set<TextTransaction>()

private let runLoopObserverCallBack: CFRunLoopObserverCallBack = { _, _, _ in
    
    if transactionSet.isEmpty {
        return
    }
    let currentSet = transactionSet
    transactionSet = Set<TextTransaction>()
    
    for transaction in currentSet {
        _ = transaction.target.perform(transaction.selector)
    }
}

private let textTransactionSetup: Int = {
    
    let runloop = CFRunLoopGetMain()
    let observer = CFRunLoopObserverCreate(
        kCFAllocatorDefault,
        CFRunLoopActivity.beforeWaiting.rawValue | CFRunLoopActivity.exit.rawValue,
        true,
        0,
        runLoopObserverCallBack,
        nil
    )
    CFRunLoopAddObserver(runloop, observer, .commonModes)
    return 0
}()

/// 事务
public class TextTransaction: NSObject {
    
    fileprivate var target: AnyObject
    fileprivate var selector: Selector
  
    /// 哈希
    override public var hash: Int {
        let v1 = selector.hashValue
        let v2 = target.hash ?? 0
        return v1 ^ v2
    }
    
    /// 构造方法
    public init(target: AnyObject, selector: Selector) {
        
        self.target = target
        self.selector = selector
        
        super.init()
    }
    
    /// 提交
    public func commit() {
        
        _ = textTransactionSetup
        transactionSet.insert(self)
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        
        guard let other = (object as? Self) else {
            return false
        }
        if self === other {
            return true
        }

        return other.selector == selector && other.target === self.target
    }
}
