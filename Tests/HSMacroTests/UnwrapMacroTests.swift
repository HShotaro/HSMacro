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

final class UnwrapMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "unwrap": UnwrapMacro.self,
    ]
    
    func testMacro() throws {
        #if canImport(HSMacroMacros)
        assertMacroExpansion(
            """
            #unwrap("https://www.google.com/")
            """,
            expandedSource: """
                guard let url = URL(string: "https://www.google.com/") else {
                    preconditionFailure(
                        #"Unexpectedly found nil: ‘"https://www.google.com/"’ "#,
                        file: nil,
                        line: nil
                    )
                }
                return url
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}


