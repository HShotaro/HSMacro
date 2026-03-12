import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HSMacroMacros)
import HSMacroMacros
#endif

final class KmpObservableViewModelMacroTests: XCTestCase {

    let testMacros: [String: Macro.Type] = [
        "KmpObservableViewModel": KmpObservableViewModelMacro.self,
        "KmpObserveIgnore": KmpObserveIgnoreMacro.self,
    ]

    // MARK: - プロパティ・observeUiState 自動生成

    /// IosXxxViewModel 命名規則から viewModel / uiState / setupKmpObservations() が生成されること
    func testGeneratesViewModelUiStateAndSetup() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosHomeViewModel: ObservableObject {
            }
            """,
            expandedSource: """
            class IosHomeViewModel: ObservableObject {

                private let viewModel: HomeViewModel

                @Published var uiState = HomeUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    /// IosLoginViewModel の場合 LoginViewModel / LoginUiState が生成されること
    func testLoginViewModelNamingConvention() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosLoginViewModel: ObservableObject {
            }
            """,
            expandedSource: """
            class IosLoginViewModel: ObservableObject {

                private let viewModel: LoginViewModel

                @Published var uiState = LoginUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    /// ユーザー定義の @Published プロパティも setupKmpObservations() に追加されること
    func testUserDefinedPublishedPropertyAlsoObserved() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosHomeViewModel: ObservableObject {
                @Published var extraState: String = ""
            }
            """,
            expandedSource: """
            class IosHomeViewModel: ObservableObject {
                @Published var extraState: String = ""

                private let viewModel: HomeViewModel

                @Published var uiState = HomeUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                    viewModel.observeExtraState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.extraState = value
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    /// @KmpObserveIgnore 付きの @Published プロパティは setupKmpObservations() から除外されること
    func testKmpObserveIgnoreExcludesFromSetup() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosHomeViewModel: ObservableObject {
                @KmpObserveIgnore
                @Published var selectedGenreId: String? = nil
            }
            """,
            expandedSource: """
            class IosHomeViewModel: ObservableObject {
                @Published var selectedGenreId: String? = nil

                private let viewModel: HomeViewModel

                @Published var uiState = HomeUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - エラー系

    /// struct に適用した場合はエラーになること
    func testAppliedToStructEmitsError() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            struct MyStruct {
            }
            """,
            expandedSource: """
            struct MyStruct {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@KmpObservableViewModel はクラスにのみ適用できます",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }

    /// Ios/ViewModel 命名規則に合わないクラス名はエラーになること
    func testInvalidClassNameEmitsError() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class HomeViewModel: ObservableObject {
            }
            """,
            expandedSource: """
            class HomeViewModel: ObservableObject {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@KmpObservableViewModel: クラス名 'HomeViewModel' は 'Ios' で始まり 'ViewModel' で終わる必要があります",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
    }
}
