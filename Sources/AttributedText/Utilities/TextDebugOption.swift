//
//  TextDebugOption.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

/// The TextDebugTarget protocol defines the method a debug target should implement.
/// A debug target can be add to the global container to receive the shared debug
/// option changed notification.
public protocol TextDebugTarget: NSObjectProtocol {
    /// When the shared debug option changed, this method would be called on main thread.
    /// It should return as quickly as possible. The option's property should not be changed
    /// in this method.
    ///
    /// Setter: The shared debug option.
    var debugOption: TextDebugOption? { get set }
}

private var sharedDebugLock = DispatchSemaphore(value: 1)

/// A List Of TextDebugOption (Unsafe Unretain)
private var sharedDebugTargets = NSPointerArray(options: .weakMemory)

public class TextDebugOption: NSObject, NSCopying {
    
    private static let _shared = TextDebugOption()
    private static var sharedOption: TextDebugOption?
    
    public static var shared: TextDebugOption {
        get {
            if let option = sharedOption {
                return option
            }
            return _shared
        }
        set {
            sharedOption = newValue
        }
    }
    
    /// baseline color
    public var baselineColor: UIColor?
    /// CTFrame path border color
    public var ctFrameBorderColor: UIColor?
    /// CTFrame path fill color
    public var ctFrameFillColor: UIColor?
    /// CTLine bounds border color
    public var ctLineBorderColor: UIColor?
    /// CTLine bounds fill color
    public var ctLineFillColor: UIColor?
    /// CTLine line number color
    public var ctLineNumberColor: UIColor?
    /// CTRun bounds border color
    public var ctRunBorderColor: UIColor?
    /// CTRun bounds fill color
    public var ctRunFillColor: UIColor?
    /// CTRun number color
    public var ctRunNumberColor: UIColor?
    /// CGGlyph bounds border color
    public var cgGlyphBorderColor: UIColor?
    /// CGGlyph bounds fill color
    public var cgGlyphFillColor: UIColor?
    
    /// `true`: at least one debug color is visible. `false`: all debug color is invisible/nil.
    public var needDrawDebug: Bool {
        
        if self.baselineColor != nil ||
            self.ctFrameBorderColor != nil ||
            self.ctFrameFillColor != nil ||
            self.ctLineBorderColor != nil ||
            self.ctLineFillColor != nil ||
            self.ctLineNumberColor != nil ||
            self.ctRunBorderColor != nil ||
            self.ctRunFillColor != nil ||
            self.ctRunNumberColor != nil ||
            self.cgGlyphBorderColor != nil ||
            self.cgGlyphFillColor != nil {
            
            return true
        }
        return false
    }
    
    /// 构造方法
    public override init() {
        super.init()
    }
    
    /// Add a debug target.
    ///
    /// When `setSharedDebugOption:` is called, all added debug target will
    /// receive `setDebugOption:` in main thread. It maintains an unsafe_unretained
    /// reference to this target. The target must to removed before dealloc.
    ///
    /// - Parameters:
    ///     - target: A debug target.
    public static func add(_ target: TextDebugTarget) {
        
        sharedDebugLock.wait()
        sharedDebugTargets.addObject(target)
        sharedDebugLock.signal()
    }
    
    /// Remove a debug target which is added by `addDebugTarget:`.
    ///
    /// - Parameters:
    ///     - target: A debug target.
    public static func remove(_ target: TextDebugTarget) {
        
        sharedDebugLock.wait()
        sharedDebugTargets.remove(target)
        sharedDebugLock.signal()
    }
    
    /// Returns the shared debug option.
    ///
    /// - Returns: The shared debug option, default is nil.
    public static func sharedDebugOption() -> TextDebugOption? {
        
        sharedDebugLock.wait()
        let option = Self.shared
        sharedDebugLock.signal()
        return option
    }
    
    /// Set a debug option as shared debug option.
    /// This method must be called on main thread.
    ///
    /// When call this method, the new option will set to all debug target
    /// which is added by `addDebugTarget:`.
    ///
    /// - Parameters:
    ///     - option:  A new debug option (nil is valid).
    public static func setSharedDebugOption(_ option: TextDebugOption) {
        assert(Thread.isMainThread, "This method must be called on the main thread")
        
        sharedDebugLock.wait()
        Self.shared = option.copy() as? Self ?? TextDebugOption()
        for target in sharedDebugTargets.allObjects {
            (target as? TextDebugTarget)?.debugOption = Self.shared
        }
        sharedDebugLock.signal()
    }
    
    /// NSCopying
    public func copy(with zone: NSZone? = nil) -> Any {
        let op = TextDebugOption()
        op.baselineColor = baselineColor
        op.ctFrameBorderColor = ctFrameBorderColor
        op.ctFrameFillColor = ctFrameFillColor
        op.ctLineBorderColor = ctLineBorderColor
        op.ctLineFillColor = ctLineFillColor
        op.ctLineNumberColor = ctLineNumberColor
        op.ctRunBorderColor = ctRunBorderColor
        op.ctRunFillColor = ctRunFillColor
        op.ctRunNumberColor = ctRunNumberColor
        op.cgGlyphBorderColor = cgGlyphBorderColor
        op.cgGlyphFillColor = cgGlyphFillColor
        return op
    }
    
    /// Set all debug color to nil.
    public func clear() {
        self.baselineColor = nil
        self.ctFrameBorderColor = nil
        self.ctFrameFillColor = nil
        self.ctLineBorderColor = nil
        self.ctLineFillColor = nil
        self.ctLineNumberColor = nil
        self.ctRunBorderColor = nil
        self.ctRunFillColor = nil
        self.ctRunNumberColor = nil
        self.cgGlyphBorderColor = nil
        self.cgGlyphFillColor = nil
    }
}

extension NSPointerArray {
    
    fileprivate func addObject(_ object: NSObjectProtocol) {
        let pointer = Unmanaged.passUnretained(object).toOpaque()
        self.addPointer(pointer)
    }
    
    fileprivate func insertObject(_ object: NSObjectProtocol, at index: Int) {
        guard index < count else { return }
        let pointer = Unmanaged.passUnretained(object).toOpaque()
        self.insertPointer(pointer, at: index)
    }
    
    fileprivate func replaceObject(at index: Int, withObject object: NSObjectProtocol) {
        guard index < count else { return }
        let pointer = Unmanaged.passUnretained(object).toOpaque()
        self.replacePointer(at: index, withPointer: pointer)
    }
    
    fileprivate func object(at index: Int) -> NSObjectProtocol? {
        guard index < count, let pointer = self.pointer(at: index) else { return nil }
        return Unmanaged<NSObjectProtocol>.fromOpaque(pointer).takeUnretainedValue()
    }
    
    fileprivate func indexes(of object: NSObjectProtocol) -> IndexSet {
        var indexSet = IndexSet()
        for index in 0..<self.count where object.isEqual(self.object(at: index)) {
            indexSet.insert(index)
        }
        return indexSet
    }
    
    fileprivate func removeObject(at index: Int) {
        guard index < count else { return }
        self.removePointer(at: index)
    }
    
    fileprivate func removeObjects(at indexes: IndexSet) {
        for index in indexes.reversed() {
            self.removeObject(at: index)
        }
    }
    
    fileprivate func remove(_ object: NSObjectProtocol) {
        let indexes = self.indexes(of: object)
        self.removeObjects(at: indexes)
    }
    
    // 如果想清理这个数组, 把其中的对象都置为 nil, 可以调用 compact() 方法
}
