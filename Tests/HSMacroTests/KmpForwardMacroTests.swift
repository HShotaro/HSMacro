import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HSMacroMacros)
import HSMacroMacros
#endif

final class KmpForwardMacroTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "KmpForward": KmpForwardMacro.self,
    ]

    // MARK: - 基本的なデリゲート生成

    /// 引数なし・戻り値なし関数のボディが生成されること
    func testNoArgsVoidFunction() {
        assertMacroExpansion(
            """
            @KmpForward func loadHomeData()
            """,
            expandedSource: """
            func loadHomeData() {
                viewModel.loadHomeData()
            }
            """,
            macros: testMacros
        )
    }

    /// ラベルあり引数のデリゲートが生成されること
    func testLabeledArgument() {
        assertMacroExpansion(
            """
            @KmpForward func search(query: String)
            """,
            expandedSource: """
            func search(query: String) {
                viewModel.search(query: query)
            }
            """,
            macros: testMacros
        )
    }

    /// アンダースコアラベル（引数ラベルなし）のデリゲートが生成されること
    func testUnderscoreLabel() {
        assertMacroExpansion(
            """
            @KmpForward func select(_ id: String)
            """,
            expandedSource: """
            func select(_ id: String) {
                viewModel.select(id)
            }
            """,
            macros: testMacros
        )
    }

    /// 外部ラベルと内部名が異なる場合（外部ラベルで呼び出されること）
    func testExternalAndInternalLabel() {
        assertMacroExpansion(
            """
            @KmpForward func rename(from oldName: String, to newName: String)
            """,
            expandedSource: """
            func rename(from oldName: String, to newName: String) {
                viewModel.rename(from: oldName, to: newName)
            }
            """,
            macros: testMacros
        )
    }

    /// 戻り値がある場合 return が生成されること
    func testReturnValue() {
        assertMacroExpansion(
            """
            @KmpForward func getTitle() -> String
            """,
            expandedSource: """
            func getTitle() -> String {
                return viewModel.getTitle()
            }
            """,
            macros: testMacros
        )
    }

    /// 複数引数のデリゲートが生成されること
    func testMultipleArguments() {
        assertMacroExpansion(
            """
            @KmpForward func loadPlaylists(genreId: String, limit: Int)
            """,
            expandedSource: """
            func loadPlaylists(genreId: String, limit: Int) {
                viewModel.loadPlaylists(genreId: genreId, limit: limit)
            }
            """,
            macros: testMacros
        )
    }
}
