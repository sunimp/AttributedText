//
//  APMWindow.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class APMWindow: UIView {
    
    static let shared = APMWindow()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .equalSpacing
        stackView.axis = .vertical
        stackView.alignment = .fill
        return stackView
    }()
    
    private let debugSwitch = DebugSwitch()
    private let fpsLabel = FPSLabel()
    private let memoryLabel = MEMLabel()
    private let cpuLabel = CPULabel()
    private let threadLabel = ThreadLabel()
    
    private var panBeginPosition = CGPoint.zero
    
    /// 是否在监控
    var isMonitoring = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 展示
    static func show() {
        self.shared.frame = CGRect(
            x: TextUtilities.screenSize.width - 10 - 68,
            y: 400,
            width: 68,
            height: 128
        )
        if self.shared.superview == nil {
            TextUtilities.keyWindow?.addSubview(self.shared)
            self.shared.start()
        }
    }
    
    // 隐藏
    static func hide() {
        self.shared.stop()
        self.shared.removeFromSuperview()
    }
    
    private func setup() {
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        self.isUserInteractionEnabled = true
        
        stackView.addArrangedSubview(self.debugSwitch)
        stackView.addArrangedSubview(self.fpsLabel)
        stackView.addArrangedSubview(self.memoryLabel)
        stackView.addArrangedSubview(self.cpuLabel)
        stackView.addArrangedSubview(self.threadLabel)
        
        self.addSubview(stackView)
        
        // swiftlint:disable discarded_notification_center_observer
        _ = NotificationCenter.default
            .addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { [weak self] _ in
                    guard let self else { return }
                    
                    self.start()
                }
            )
        
        _ = NotificationCenter.default
            .addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { [weak self] _ in
                    guard let self else { return }
                    
                    self.stop()
                }
            )
        // swiftlint:enable discarded_notification_center_observer
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        self.addGestureRecognizer(pan)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longPress.minimumPressDuration = 0.5
        self.addGestureRecognizer(longPress)
        
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(tripleTap(_:)))
        tripleTap.numberOfTapsRequired = 3
        self.addGestureRecognizer(tripleTap)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 5
        self.addGestureRecognizer(doubleTap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        stackView.frame = self.bounds.inset(by: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
    }
    
    private func start() {
        guard !self.isMonitoring else {
            return
        }
        self.fpsLabel.start()
        self.memoryLabel.start()
        self.cpuLabel.start()
        self.threadLabel.start()
        self.isMonitoring = true
    }
    
    private func stop() {
        guard self.isMonitoring else {
            return
        }
        self.fpsLabel.stop()
        self.memoryLabel.stop()
        self.cpuLabel.stop()
        self.threadLabel.stop()
        self.isMonitoring = false
    }
    
    @objc
    private func pan(_ pan: UIPanGestureRecognizer) {
        
        switch pan.state {
        case .began:
            self.panBeginPosition = self.frame.origin
        case .changed:
            guard let superview = self.superview else { return }
            let offset = pan.translation(in: superview)
            
            self.left = self.panBeginPosition.x + offset.x
            self.top = self.panBeginPosition.y + offset.y
        default:
            if self.left < -self.width / 5 || self.left > TextUtilities.screenSize.width - self.width * 0.8 {
                let left = self.left < -self.width / 3 ?
                -self.width :
                TextUtilities.screenSize.width + self.width
                UIView.animate(withDuration: 0.25, animations: {
                    self.left = left
                }) { (_) in
                    Self.hide()
                }
                return
            }
            if self.top < -self.height / 5 || self.top > TextUtilities.screenSize.height - self.height * 0.8 {
                let top = self.top < -self.height / 3 ?
                -self.height :
                TextUtilities.screenSize.height + self.height
                UIView.animate(withDuration: 0.25, animations: {
                    self.top = top
                }) { (_) in
                    Self.hide()
                }
                return
            }
            
            let left: CGFloat
            if self.frame.midX < TextUtilities.screenSize.width / 2 {
                left = 10
            } else {
                left = TextUtilities.screenSize.width - 10 - self.width
            }
            let top = min(max(20, self.top), TextUtilities.screenSize.height - 20 - self.height)
            
            UIView.animate(withDuration: 0.25) {
                self.left = left
                self.top = top
            }
        }
    }
    
    @objc
    private func longPress(_ gesture: UIPanGestureRecognizer) {
        
        // Do your custom action
    }
    
    @objc
    private func tripleTap(_ gesture: UIPanGestureRecognizer) {
        // Do your custom action
    }
    
    @objc
    private func doubleTap(_ gesture: UIPanGestureRecognizer) {
        // Do your custom action
    }
    
}
