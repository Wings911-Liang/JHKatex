//
//  KatexUtils.swift
//  KatexUtils
//
//  Created by admin on 2024/5/15.
//

import Foundation

public struct KatexViewConfig {
        
    var options: [Katex.Key : Any]?
        
    var customCss = ""
        
    public static func defaultConfig() -> KatexViewConfig {
        var config = KatexViewConfig()
        config.options = [.displayMode: false, .macros: [#"\RR"#: #"\mathbb{R}"#, #"\f"#: #"#1f(#2)"#]]
        config.customCss = ".katex { color: #212121; font-size: 16px; }"
        return config
    }
}
