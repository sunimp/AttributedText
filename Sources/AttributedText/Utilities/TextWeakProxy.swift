//
//  TextWeakProxy.swift
//  AttributedText
//
//  Created by Sun on 2023/6/30.
//  Copyright © 2023 Webull. All rights reserved.
//

import Foundation
import QuartzCore

/// Timer
public protocol TimerTarget: NSObjectProtocol {
    
    func invalidate()
}

/// 处理 NSTimer、CADisplayLink 引用循环的代理类
public class TextWeakProxy<T: TimerTarget>: NSObject {
    
    /// 被转发的对象
    public weak var target: NSObject?
    /// Selector 中不能带参数, 否则会 crash
    public var selector: Selector?
    
    /// 实例化 timer 之后需要将 timer 赋值给 proxy, 否则就算 target 释放了, timer 本身依然会继续运行
    public weak var timer: T?
    
    /// 构造方法
    public required init(_ target: NSObject, selector: Selector?) {
        self.target = target
        self.selector = selector
        super.init()
        
        // 加强安全保护
        guard let selector = selector, target.responds(to: selector) else {
            return
        }
        
        // 将 target 的 selector 替换 为 redirectionMethod, 该方法会重新处理事件
        guard let method = class_getInstanceMethod(self.classForCoder, #selector(redirectionMethod)) else {
            return
        }
        class_replaceMethod(
            self.classForCoder,
            selector,
            method_getImplementation(method),
            method_getTypeEncoding(method)
        )
    }
    
    @objc
    private func redirectionMethod() {
        // 如果 target 未被释放, 则调用 target 方法, 否则释放 timer
        if let target = self.target, let selector = self.selector {
            target.perform(selector)
        } else {
            self.timer?.invalidate()
        }
    }
    
    override public func forwardingTarget(for aSelector: Selector?) -> Any? {
        if self.target?.responds(to: aSelector) == true {
            return self.target
        } else {
            self.timer?.invalidate()
            return self
        }
    }
}

extension Timer: TimerTarget { }
extension CADisplayLink: TimerTarget { }

extension Timer {
    
    /// NSTimer, 此方法不会造成循环引用
    public static func scheduled(
        interval: TimeInterval,
        target: NSObject,
        selector: Selector,
        repeats: Bool
    ) -> Timer {
        
        let proxy = TextWeakProxy<Timer>(target, selector: selector)
        let timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: proxy,
            selector: selector,
            userInfo: nil,
            repeats: repeats
        )
        proxy.timer = timer
        
        return timer
    }
}

extension CADisplayLink {
    
    /// CADisplayLink, 此方法不会造成循环引用
    public static func displayLink(target: NSObject, selector: Selector) -> CADisplayLink {
        
        let proxy = TextWeakProxy<CADisplayLink>(target, selector: selector)
        let displayLink = CADisplayLink(target: proxy, selector: selector)
        displayLink.add(to: RunLoop.main, forMode: .common)
        proxy.timer = displayLink
        
        return displayLink
    }
}
