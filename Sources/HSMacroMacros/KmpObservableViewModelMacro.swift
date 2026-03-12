import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@KmpObservableViewModel` を付与したクラスの名前から KMP ViewModel / UiState の型名を導出し、
/// 以下の3つのメンバーを自動生成する。
///
/// **命名規則**: クラス名が `IosXxxViewModel` の場合
///   - `private let viewModel: XxxViewModel`
///   - `@Published var uiState = XxxUiState()`
///   - `func setupKmpObservations()` — `viewModel.observeUiState { ... }` を含む
///
/// さらにクラス内の `@Published var` プロパティを走査し、`@KmpObserveIgnore` の付いていないものも
/// `setupKmpObservations()` に追加する。
///
/// **制約**:
/// - クラス名は `Ios` で始まり `ViewModel` で終わる必要がある
/// - 手書きの `viewModel` / `uiState` プロパティは削除してからマクロを適用すること
public struct KmpObservableViewModelMacro: MemberMacro {

    enum KmpObservableError: CustomStringConvertible, Error {
        case onlyApplicableToClass
        case invalidClassName(String)

        var description: String {
            switch self {
            case .onlyApplicableToClass:
                return "@KmpObservableViewModel はクラスにのみ適用できます"
            case .invalidClassName(let name):
                return "@KmpObservableViewModel: クラス名 '\(name)' は 'Ios' で始まり 'ViewModel' で終わる必要があります"
            }
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw KmpObservableError.onlyApplicableToClass
        }

        // クラス名から "Xxx" 部分を抽出: IosXxxViewModel → Xxx
        let className = classDecl.name.text
        guard className.hasPrefix("Ios"), className.hasSuffix("ViewModel") else {
            throw KmpObservableError.invalidClassName(className)
        }
        let withoutPrefix = String(className.dropFirst(3))    // XxxViewModel
        let middlePart    = String(withoutPrefix.dropLast(9)) // Xxx

        let viewModelTypeName = "\(middlePart)ViewModel" // HomeViewModel
        let uiStateTypeName   = "\(middlePart)UiState"   // HomeUiState

        // --- ユーザー定義の @Published プロパティを走査（追加の observe 生成用）---
        let scannedObservations: [String] = classDecl.memberBlock.members.compactMap { member in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var)
            else { return nil }

            // @KmpObserveIgnore が付いていればスキップ
            let hasIgnore = varDecl.attributes.contains { attr in
                attr.as(AttributeSyntax.self)?
                    .attributeName.as(IdentifierTypeSyntax.self)?
                    .name.text == "KmpObserveIgnore"
            }
            guard !hasIgnore else { return nil }

            // @Published が付いているプロパティのみ対象
            let hasPublished = varDecl.attributes.contains { attr in
                attr.as(AttributeSyntax.self)?
                    .attributeName.as(IdentifierTypeSyntax.self)?
                    .name.text == "Published"
            }
            guard hasPublished else { return nil }

            guard let binding = varDecl.bindings.first,
                  let identPattern = binding.pattern.as(IdentifierPatternSyntax.self)
            else { return nil }

            let propName = identPattern.identifier.text
            // 命名規則で生成する uiState は重複しないよう除外
            guard propName != "uiState" else { return nil }

            let observeName = "observe" + propName.prefix(1).uppercased() + propName.dropFirst()
            return """
                viewModel.\(observeName) { [weak self] value in
                    Task { @MainActor [weak self] in
                        self?.\(propName) = value
                    }
                }
            """
        }

        // --- setupKmpObservations() のボディ ---
        // 命名規則由来の observeUiState は常に先頭に追加
        let uiStateObservation = """
                viewModel.observeUiState { [weak self] value in
                    Task { @MainActor [weak self] in
                        self?.uiState = value
                    }
                }
            """
        let allObservations = ([uiStateObservation] + scannedObservations).joined(separator: "\n")

        // --- 生成するメンバー ---
        let viewModelProp = DeclSyntax(
            stringLiteral: "private let viewModel: \(viewModelTypeName)"
        )
        let uiStateProp = DeclSyntax(
            stringLiteral: "@Published var uiState = \(uiStateTypeName)()"
        )
        let setupFunc = DeclSyntax(stringLiteral: """
            func setupKmpObservations() {
            \(allObservations)
            }
            """)

        return [viewModelProp, uiStateProp, setupFunc]
    }
}

/// 生成対象から除外するためのマーカーマクロ。
/// `@KmpObservableViewModel` がプロパティを走査する際、このアトリビュートが付いていれば
/// `setupKmpObservations()` への observation コードを生成しない。
public struct KmpObserveIgnoreMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}
