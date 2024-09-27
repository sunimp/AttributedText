//
//  TextAsyncLayer.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import Dispatch
import UIKit

private var textAsyncQueueCount: Int = 1
private var textAsyncThreadCounter: Int64 = 0

private var textAsyncLayerGetDisplayQueues: [DispatchQueue] = {
    var result = [DispatchQueue]()
    let queueCount = max(min(ProcessInfo.processInfo.activeProcessorCount, 1), 16)
    textAsyncQueueCount = queueCount
    return [Int](0 ..< queueCount).map { _ in
        DispatchQueue(label: "com.webull.AttributedText.render", qos: .userInitiated)
    }
}()

/// 全局显示队列, 用于内容渲染
private func textAsyncLayerGetDisplayQueue() -> DispatchQueue {
    let newValue = Int(OSAtomicIncrement64(&textAsyncThreadCounter))
    return textAsyncLayerGetDisplayQueues[newValue % textAsyncQueueCount]
}

/// TextAsyncLayer 的委托协议
///
/// 委托通常是一个 UIView, 必须实现该协议中的方法
public protocol TextAsyncLayerDelegate: NSObjectProtocol {
    /// 当图层的内容需要更新时, 调用此方法以返回新的显示任务
    func newAsyncDisplayTask() -> TextAsyncLayerDisplayTask?
}

/// TextAsyncLayer 用于在后台队列中呈现内容的显示任务
public class TextAsyncLayerDisplayTask: NSObject {
    /// 此闭包将在异步绘制之前调用
    ///
    /// 它将在主线程上被调用
    public var willDisplay: ((_ layer: CALayer?) -> Void)?
    
    /// 调用此闭包来绘制图层的内容
    ///
    /// 此闭包可以在主线程或后台线程上调用, 所以它应该是线程安全的
    ///
    /// - Parameters:
    ///     - context: 由 layer 创建的新的位图内容
    ///     - size: 内容大小(通常与 layer 的 bound 大小相同)
    ///     - isCancelled: 如果此闭包返回 `true`, 那么该方法应该取消绘制过程并尽快 return
    public var display: ((_ context: CGContext?, _ size: CGSize, _ isCancelled: @escaping () -> Bool) -> Void)?
    
    /// 此闭包将在异步绘制完成后被调用
    ///
    /// 它将在主线程上被调用
    ///
    /// - Parameters:
    ///     - layer：图层
    ///     - finished: 如果绘制过程被取消, 则为`false`, 否则为`true`
    public var didDisplay: ((_ layer: CALayer, _ finished: Bool) -> Void)?
}

/// 一个线程安全的递增计数器
private struct TextSentinel {
    private(set) var value: Int32 = 0
    
    @discardableResult
    mutating func increase() -> Int32 {
        OSAtomicIncrement32(&self.value)
    }
}

/// TextAsyncLayer 类是 CALayer 的一个子类, 用于异步渲染内容
///
/// 当该 Layer 需要更新它的内容时, 它将向委托请求一个异步显示任务, 以在后台队列中渲染内容
///
public class TextAsyncLayer: CALayer {
    /// 渲染代码是否在后台执行
    ///
    /// 此属性默认为 true
    ///
    public var isDisplaysAsynchronously = true
    
    /// 哨兵
    private var sentinel = TextSentinel()
    
    override public init() {
        super.init()
        
        self.setup()
    }
    
    override public init(layer: Any) {
        super.init(layer: layer)
        
        self.setup()
    }
    
    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public class func defaultValue(forKey key: String) -> Any? {
        if key == "isDisplaysAsynchronously" {
            return true
        } else {
            return super.defaultValue(forKey: key)
        }
    }
    
    private func setup() {
        self.contentsScale = UIScreen.main.scale
    }
    
    override public func setNeedsDisplay() {
        self.cancelAsyncDisplay()
        super.setNeedsDisplay()
    }
    
    override public func display() {
        super.contents = super.contents
        self.displayAsync(self.isDisplaysAsynchronously)
    }
    
    private func displayAsync(_ async: Bool) {
        guard let delegate = self.delegate as? TextAsyncLayerDelegate,
              let task = delegate.newAsyncDisplayTask()
        else {
            return
        }
        guard let displayAction = task.display else {
            task.willDisplay?(self)
            contents = nil
            task.didDisplay?(self, true)
            return
        }
        
        // 异步
        if async {
            task.willDisplay?(self)
            let currentSentinel = self.sentinel
            let previousValue = currentSentinel.value
            let isCancelled: (() -> Bool) = {
                previousValue != currentSentinel.value
            }
            let drawSize: CGSize = self.bounds.size
            let drawOpaque: Bool = self.isOpaque
            let drawScale: CGFloat = self.contentsScale
            let drawBackgroundColor = (drawOpaque && self.backgroundColor != nil) ? self.backgroundColor : nil
            
            guard drawSize.width >= 1, drawSize.height >= 1 else { // 宽度或者高度小于1时, 不绘制
                task.didDisplay?(self, true)
                return
            }
            
            // 异步绘制
            textAsyncLayerGetDisplayQueue().async {
                if isCancelled() {
                    return
                }
                let format = UIGraphicsImageRendererFormat()
                format.opaque = drawOpaque
                format.scale = drawScale
                let renderer = UIGraphicsImageRenderer(size: drawSize, format: format)
                let image = renderer.image { context in
                    let cgContext = context.cgContext
                    // 不透明的才绘制
                    if drawOpaque {
                        cgContext.saveGState()
                        defer {
                            cgContext.restoreGState()
                        }
                        let fillColor: CGColor = {
                            if let color = drawBackgroundColor, color.alpha == 1.0 { // 背景色 alpha 通道的值为 1.0
                                return color
                            }
                            return UIColor.white.cgColor
                        }()
                        cgContext.setFillColor(fillColor)
                        cgContext.addRect(
                            CGRect(
                                x: 0,
                                y: 0,
                                width: drawSize.width * drawScale,
                                height: drawSize.height * drawScale
                            )
                        )
                        cgContext.fillPath()
                    }
                    displayAction(cgContext, drawSize, isCancelled)
                    
                    if isCancelled() {
                        DispatchQueue.main.async {
                            task.didDisplay?(self, false)
                        }
                        return
                    }
                }
                // 回调主线程渲染
                DispatchQueue.main.async {
                    if isCancelled() {
                        task.didDisplay?(self, false)
                    } else {
                        self.contents = image.cgImage
                        task.didDisplay?(self, true)
                    }
                }
            }
        } else {
            // 同步绘制
            self.sentinel.increase()
            task.willDisplay?(self)
            let format = UIGraphicsImageRendererFormat()
            format.opaque = self.isOpaque
            format.scale = self.contentsScale
            let renderer = UIGraphicsImageRenderer(size: self.bounds.size, format: format)
            let image = renderer.image { context in
                let cgContext = context.cgContext
                // 不透明的才绘制
                if self.isOpaque {
                    cgContext.saveGState()
                    defer {
                        cgContext.restoreGState()
                    }
                    let fillColor: CGColor = {
                        if let color = self.backgroundColor, color.alpha == 1.0 { // 背景色 alpha 通道的值为 1.0
                            return color
                        }
                        return UIColor.white.cgColor
                    }()
                    cgContext.setFillColor(fillColor)
                    cgContext.addRect(
                        CGRect(
                            x: 0,
                            y: 0,
                            width: self.bounds.width * self.contentsScale,
                            height: self.bounds.height * self.contentsScale
                        )
                    )
                    cgContext.fillPath()
                }
                displayAction(cgContext, self.bounds.size) { false }
            }
            
            self.contents = image.cgImage
            task.didDisplay?(self, true)
        }
    }
    
    private func cancelAsyncDisplay() {
        self.sentinel.increase()
    }
    
    deinit {
        sentinel.increase()
    }
}
