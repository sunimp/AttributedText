//
//  MEMLabel.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

class MEMLabel: UILabel {
    
    private var timer: Timer?
    
    init() {
        super.init(frame: .zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.textColor = .white
        self.font = UIFont.systemFont(ofSize: 16)
        self.textAlignment = .center
    }
    
    func start() {
        if self.timer != nil {
            self.stop()
        }
        
        self.timer = Timer.scheduled(
            interval: 1.0,
            target: self,
            selector: #selector(self.checkMemory),
            repeats: true
        )
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc
    private func checkMemory() {
        self.text = "\(self.memoryUsage()) MB"
    }
    
    private func memoryUsage() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        var used: Double = 0
        if result == KERN_SUCCESS {
            used = Double(taskInfo.phys_footprint) / 1_024.0 / 1_024.0
        }
        
        return UInt64(used)
    }
}
