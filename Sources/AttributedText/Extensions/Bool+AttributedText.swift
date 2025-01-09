//
//  Bool+AttributedText.swift
//  AttributedText
//
//  Created by Sun on 2025/1/9.
//

import Foundation

extension Bool {
    /// `false` if `self` is `true`; `true` if `self` is `false`.
    public var toggled: Bool {
        return !self
    }
}
