//
//  Double+Additionals.swift
//  AttributedTextExample
//
//  Created by Sun on 2023/7/10.
//  Copyright © 2023 Webull. All rights reserved.
//

import Foundation

extension Double {
    
    /// 数字格式化
    public static var digitalFormat: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = "."
        formatter.perMillSymbol = ","
        formatter.numberStyle = NumberFormatter.Style.currency
        formatter.currencySymbol = ""
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    /// 百分比格式
    public func percentageFormat(_ precision: Int = 2, power: Int = -2) -> String {
        return String(format: "%.\(precision)f", self / pow(10.0, Double(power))).numberFormat()
    }
    
    /// 数字格式
    public func digitalFormat(minFraction: Int? = nil, maxFraction: Int? = nil) -> String {
        
        let formatter = Double.digitalFormat
        if let min = minFraction {
            formatter.minimumFractionDigits = min
        }
        if let max = maxFraction {
            formatter.maximumFractionDigits = max
        }
        
        if let formatString = formatter.string(from: NSNumber(value: self)) {
            return formatString.trim()
        }
        
        return "-"
    }
}
