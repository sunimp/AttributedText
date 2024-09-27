//
//  ThreadLabel.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import Darwin

class ThreadLabel: UILabel {
  
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
        self.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.textAlignment = .center
    }
    
    func start() {
        if self.timer != nil {
            self.stop()
        }
        
        self.timer = Timer.scheduled(
            interval: 1.0,
            target: self,
            selector: #selector(self.checkThread),
            repeats: true
        )
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc
    private func checkThread() {
        let threads = self.threadUsage()
        if threads > 1 {
            self.text = "\(threads) Ths"
        } else {
            self.text = "\(threads) Th"
        }
    }
    
    private func threadUsage() -> UInt32 {
        var threads_array: thread_act_array_t?
        var threads_count = mach_msg_type_number_t()
        let result = task_threads(mach_task_self_, &threads_array, &threads_count)
        
        guard result == KERN_SUCCESS, let threads = threads_array else {
            return 0
        }
        let kern_size = vm_size_t(threads_count) * vm_size_t(MemoryLayout<thread_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threads)), kern_size)
        
        return UInt32(threads_count)
    }
}
