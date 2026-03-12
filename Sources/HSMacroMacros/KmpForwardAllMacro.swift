import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// extension 内の全 `func` 宣言に `@KmpForward` を付与する `@attached(memberAttribute)` マクロ。
///
/// **制約**: Swift パーサーの仕様上、`@attached(body)` は関数にパース時点で直接付与されている
/// 必要があるため、`@KmpForwardAll` 経由の自動付与では bodyless 関数を使えない。
/// そのため各関数に `@KmpForward` を明示的に書く方式を推奨する。
///
/// **使い方**:
/// ```swift
/// extension IosHomeViewModel: HomeViewModelInterface {
///     @KmpForward func loadHomeData()
///     @KmpForward func search(query: String)
/// }
/// ```
public struct KmpForwardAllMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard member.is(FunctionDeclSyntax.self) else { return [] }
        return ["@KmpForward"]
    }
}
