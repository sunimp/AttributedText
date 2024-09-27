//
//  LinkedFramesList.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import Foundation

/// 链表节点
class FrameNode {
    
    var next: FrameNode?
    weak var previous: FrameNode?
    
    private(set) var timestamp: TimeInterval
    
    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
    }
}

/// 双向链表
class LinkedFramesList {
    
    private var head: FrameNode?
    private var tail: FrameNode?
    
    private(set) var count = 0
}

extension LinkedFramesList {
    
    func append(frameWithTimestamp timestamp: TimeInterval) {
        let newNode = FrameNode(timestamp: timestamp)
        if let lastNode = self.tail {
            newNode.previous = lastNode
            lastNode.next = newNode
            self.tail = newNode
        } else {
            self.head = newNode
            self.tail = newNode
        }
        
        self.count += 1
        self.removeFrameNodes(olderThanTimestampMoreThanSecond: timestamp)
    }
}

extension LinkedFramesList {
    
    private func removeFrameNodes(olderThanTimestampMoreThanSecond timestamp: TimeInterval) {
        while let firstNode = self.head {
            guard timestamp - firstNode.timestamp > 1.0 else {
                break
            }
            
            let nextNode = firstNode.next
            nextNode?.previous = nil
            firstNode.next = nil
            self.head = nextNode
            
            self.count -= 1
        }
    }
}
