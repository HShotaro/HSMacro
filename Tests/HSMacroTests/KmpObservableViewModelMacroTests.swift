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

                init() {
                    self.viewModel = IosDependencies.shared.provider.homeViewModel
                    setupKmpObservations()
                }

                deinit {
                    viewModel.dispose()
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

                init() {
                    self.viewModel = IosDependencies.shared.provider.loginViewModel
                    setupKmpObservations()
                }

                deinit {
                    viewModel.dispose()
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

                init() {
                    self.viewModel = IosDependencies.shared.provider.homeViewModel
                    setupKmpObservations()
                }

                deinit {
                    viewModel.dispose()
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

                init() {
                    self.viewModel = IosDependencies.shared.provider.homeViewModel
                    setupKmpObservations()
                }

                deinit {
                    viewModel.dispose()
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - init() 生成制御

    /// 既存 init がある場合は init() を生成しないこと
    func testSkipsInitGenerationWhenInitExists() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosHomeViewModel: ObservableObject {
                init(custom: Bool) {
                    self.viewModel = IosDependencies.shared.provider.homeViewModel
                    setupKmpObservations()
                }
            }
            """,
            expandedSource: """
            class IosHomeViewModel: ObservableObject {
                init(custom: Bool) {
                    self.viewModel = IosDependencies.shared.provider.homeViewModel
                    setupKmpObservations()
                }

                private let viewModel: HomeViewModel

                @Published var uiState = HomeUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                }

                deinit {
                    viewModel.dispose()
                }
            }
            """,
            macros: testMacros
        )
    }

    // MARK: - deinit 生成制御

    /// deinit { viewModel.dispose() } が自動生成されること
    func testGeneratesDeinitWithClear() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosSearchViewModel: ObservableObject {
            }
            """,
            expandedSource: """
            class IosSearchViewModel: ObservableObject {

                private let viewModel: SearchViewModel

                @Published var uiState = SearchUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                }

                init() {
                    self.viewModel = IosDependencies.shared.provider.searchViewModel
                    setupKmpObservations()
                }

                deinit {
                    viewModel.dispose()
                }
            }
            """,
            macros: testMacros
        )
    }

    /// 既存 deinit がある場合は deinit を生成しないこと（シングルトン ViewModel の opt-out パターン）
    func testSkipsDeinitGenerationWhenDeinitExists() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosLoginViewModel: ObservableObject {
                deinit {}
            }
            """,
            expandedSource: """
            class IosLoginViewModel: ObservableObject {
                deinit {}

                private let viewModel: LoginViewModel

                @Published var uiState = LoginUiState()

                func setupKmpObservations() {
                    viewModel.observeUiState { [weak self] value in
                        Task { @MainActor [weak self] in
                            self?.uiState = value
                        }
                    }
                }

                init() {
                    self.viewModel = IosDependencies.shared.provider.loginViewModel
                    setupKmpObservations()
                }
            }
            """,
            macros: testMacros
        )
    }

    /// 既存 init と既存 deinit が両方ある場合はどちらも生成しないこと
    func testSkipsBothInitAndDeinitWhenBothExist() {
        assertMacroExpansion(
            """
            @KmpObservableViewModel
            class IosLoginViewModel: ObservableObject {
                init() {
                    self.viewModel = IosDependencies.shared.provider.loginViewModel
                    setupKmpObservations()
                }
                deinit {}
            }
            """,
            expandedSource: """
            class IosLoginViewModel: ObservableObject {
                init() {
                    self.viewModel = IosDependencies.shared.provider.loginViewModel
                    setupKmpObservations()
                }
                deinit {}

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
