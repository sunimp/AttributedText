//
//  TextParser.swift
//  AttributedText
//
//  Created by Sun on 2023/6/25.
//  Copyright © 2023 Webull. All rights reserved.
//

import UIKit

/// The TextParser protocol declares the required method for AttributedTextView and AttributedLabel
///  to modify the text during editing.
///
///  You can implement this protocol to add code highlighting or emoticon replacement for
///  AttributedTextView and AttributedLabel. See `TextSimpleMarkdownParser` and `TextSimpleEmoticonParser` for example.
public protocol TextParser: NSObjectProtocol {
    /// When text is changed in AttributedTextView or AttributedLabel, this method will be called.
    ///
    /// - Parameters:
    ///     - text:  The original attributed string. This method may parse the text and
    ///     change the text attributes or content.
    ///     - selectedRange:  Current selected range in `text`.
    ///
    ///  This method should correct the range if the text content is changed. If there's
    ///  no selected range (such as AttributedLabel), this value is NULL.
    ///
    ///  - Returns: If the 'text' is modified in this method, returns `true`, otherwise returns `false`.
    @discardableResult
    func parseText(_ text: NSMutableAttributedString?, selectedRange: NSRangePointer?) -> Bool
}
