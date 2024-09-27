//
//  Data+Additionals.swift
//  AttributedText
//
//  Created by Sun on 2023/6/27.
//  Copyright © 2023 Webull. All rights reserved.
//

import Foundation

extension Data {
    
    static func dataNamed(_ name: String?) -> Data? {
        let path = Bundle.main.path(forResource: name, ofType: "")
        if path == nil {
            return nil
        }
        let data = NSData(contentsOfFile: path ?? "") as Data?
        return data
    }
}

extension NSData {
    
    @objc
    static func dataNamed(_ name: String?) -> NSData? {
        let path = Bundle.main.path(forResource: name, ofType: "")
        if path == nil {
            return nil
        }
        let data = NSData(contentsOfFile: path ?? "")
        return data
    }
}
