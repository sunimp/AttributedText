//
//  FPSLabel.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/6/26.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

import AttributedText

class FPSLabel: UILabel {
    
    private let linkedFramesList = LinkedFramesList()
    private var startTimestamp: TimeInterval?
    private var accumulatedInformationIsEnough = false
    
    private var displayLink: CADisplayLink?
    
    init() {
        super.init(frame: .zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        self.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.textAlignment = .center
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 4
        
        self.displayLink = CADisplayLink.displayLink(target: self, selector: #selector(self.tick))
    }
    
    func start() {
        
        self.startTimestamp = Date().timeIntervalSince1970
        self.displayLink?.isPaused = false
    }
    
    func stop() {
        self.displayLink?.isPaused = true
        self.displayLink?.invalidate()
        self.startTimestamp = nil
        self.accumulatedInformationIsEnough = false
    }
    
    @objc
    func tick() {
        guard let link = self.displayLink else { return }
        self.linkedFramesList.append(frameWithTimestamp: link.timestamp)
        if self.accumulatedInformationIsEnough {
            let fps = self.linkedFramesList.count - 1
            let frameRate = Double(fps) / 60
            let color = UIColor(hue: 0.27 * CGFloat(frameRate - 0.2), saturation: 1, brightness: 0.9, alpha: 1)
            self.textColor = color
            self.text = "\(fps) FPS"
        } else if let start = self.startTimestamp, Date().timeIntervalSince1970 - start >= 1.0 {
            self.accumulatedInformationIsEnough = true
        }
    }
    
    deinit {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
}
