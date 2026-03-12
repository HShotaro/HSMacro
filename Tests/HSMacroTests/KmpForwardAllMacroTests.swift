import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HSMacroMacros)
import HSMacroMacros
#endif

final class KmpForwardAllMacroTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "KmpForwardAll": KmpForwardAllMacro.self,
        "KmpForward": KmpForwardMacro.self,
    ]

    // MARK: - KmpForwardAll の展開

    /// extension 内の関数に @KmpForward が付与され、ボディが生成されること
    func testForwardAllGeneratesBodyForSingleFunction() {
        assertMacroExpansion(
            """
            @KmpForwardAll
            extension IosHomeViewModel: HomeViewModelInterface {
                func loadHomeData()
            }
            """,
            expandedSource: """
            extension IosHomeViewModel: HomeViewModelInterface {
                func loadHomeData() {
                    viewModel.loadHomeData()
                }
            }
            """,
            macros: testMacros
        )
    }

    /// 複数関数にまとめて @KmpForward が付与されること
    func testForwardAllGeneratesBodyForMultipleFunctions() {
        assertMacroExpansion(
            """
            @KmpForwardAll
            extension IosSearchViewModel: SearchViewModelInterface {
                func search(query: String)
                func clearResults()
            }
            """,
            expandedSource: """
            extension IosSearchViewModel: SearchViewModelInterface {
                func search(query: String) {
                    viewModel.search(query: query)
                }
                func clearResults() {
                    viewModel.clearResults()
                }
            }
            """,
            macros: testMacros
        )
    }

    /// 戻り値がある関数でも return が生成されること
    func testForwardAllHandlesReturnType() {
        assertMacroExpansion(
            """
            @KmpForwardAll
            extension IosHomeViewModel: HomeViewModelInterface {
                func getTitle() -> String
            }
            """,
            expandedSource: """
            extension IosHomeViewModel: HomeViewModelInterface {
                func getTitle() -> String {
                    return viewModel.getTitle()
                }
            }
            """,
            macros: testMacros
        )
    }

    /// アンダースコアラベルの引数も正しく処理されること
    func testForwardAllHandlesUnderscoreLabel() {
        assertMacroExpansion(
            """
            @KmpForwardAll
            extension IosHomeViewModel: HomeViewModelInterface {
                func select(_ id: String)
            }
            """,
            expandedSource: """
            extension IosHomeViewModel: HomeViewModelInterface {
                func select(_ id: String) {
                    viewModel.select(id)
                }
            }
            """,
            macros: testMacros
        )
    }
}
