//
//  File.swift
//  
//
//  Created by shotaro.hirano on 2023/10/06.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HSMacroMacros)
import HSMacroMacros
#endif

final class EnumSubsetTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "EnumSubset" : EnumSubsetMacro.self,
    ]
    
    func testSlopeSubset() {
        assertMacroExpansion(
            """
            @EnumSubset<Slope>
            enum EasySlope {
                case beginnersParadise
                case practiceRun
            }
            """,
            expandedSource: """

            enum EasySlope {
                case beginnersParadise
                case practiceRun
            
                init?(_ slope: Slope) {
                    switch slope {
                    case .beginnersParadise:
                        self = .beginnersParadise
                    case .practiceRun:
                        self = .practiceRun
                    default:
                        return nil
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testSlopeSubsetOnStruct() throws {
        assertMacroExpansion(
            """
            @EnumSubset
            struct Skier {
            }
            """,
            expandedSource: """

            struct Skier {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@EnumSubset can only be applied to an enum", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}
