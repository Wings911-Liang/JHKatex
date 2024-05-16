//
//  KatexUtils.swift
//  KatexUtils
//
//  Created by admin on 2024/5/15.
//

import Foundation

public struct KatexViewConfig {
        
    var options: [Katex.Key : Any]?
    
    public static func defaultConfig() -> KatexViewConfig {
        var config = KatexViewConfig()
        config.options = [.displayMode: false, .macros: [#"\RR"#: #"\mathbb{R}"#, #"\f"#: #"#1f(#2)"#]]
        return config
    }
}
