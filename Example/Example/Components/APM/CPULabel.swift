//
//  CPULabel.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit
import Darwin

class CPULabel: UILabel {
    
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
            selector: #selector(self.checkProcessor),
            repeats: true
        )
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    @objc
    private func checkProcessor() {
        let cpu = self.cpuUsage() / 100
        self.textColor = UIColor(hue: 0.27 * CGFloat(1 - cpu), saturation: 1, brightness: 0.9, alpha: 1)
        self.text = "\(Double(cpu).percentageFormat())"
    }
    
    private func cpuUsage() -> Double {
        
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }
        
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)],
                                    thread_flavor_t(THREAD_BASIC_INFO),
                                    $0,
                                    &threadInfoCount)
                    }
                }
                
                guard infoResult == KERN_SUCCESS else {
                    break
                }
                
                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = (totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) /
                                                          Double(TH_USAGE_SCALE) * 100.0))
                }
            }
        }
        
        vm_deallocate(mach_task_self_,
                      vm_address_t(UInt(bitPattern: threadsList)),
                      vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        return totalUsageOfCPU
    }
}
