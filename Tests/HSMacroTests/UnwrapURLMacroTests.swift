//
//  File.swift
//  
//
//  Created by shotaro.hirano on 2023/10/30.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HSMacroMacros)
import HSMacroMacros
#endif

final class UnwrapURLMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "unwrap": UnwrapURLMacro.self,
    ]
    
    func testMacro() throws {
        #if canImport(HSMacroMacros)
        assertMacroExpansion(
            """
            #unwrap("https://www.google.com/")
            """,
            expandedSource: """
            #unwrap("https://www.google.com/")
            """,
            diagnostics: [
                DiagnosticSpec(message: "noLocation error", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}


