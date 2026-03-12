import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// `@KmpForward` を付与した関数宣言に、`viewModel.xxx(...)` を呼び出すボディを自動生成する。
///
/// **使い方**:
/// ```swift
/// @KmpForward func loadHomeData()
/// // 生成: { viewModel.loadHomeData() }
///
/// @KmpForward func search(query: String) -> [Result]
/// // 生成: { return viewModel.search(query: query) }
///
/// @KmpForward func select(_ item: Item)
/// // 生成: { viewModel.select(item) }
/// ```
public struct KmpForwardMacro: BodyMacro {

    enum KmpForwardError: CustomStringConvertible, Error {
        case onlyApplicableToFunction

        var description: String {
            "@KmpForward は関数にのみ適用できます"
        }
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw KmpForwardError.onlyApplicableToFunction
        }

        let funcName = funcDecl.name.text
        let params = funcDecl.signature.parameterClause.parameters

        // パラメータリストを生成
        // func foo(label name: T) → "label: name"
        // func foo(name: T)       → "name: name"
        // func foo(_ name: T)     → "name"
        let args = params.map { param -> String in
            let firstName = param.firstName.text
            let internalName: String
            if let second = param.secondName {
                internalName = second.text
            } else {
                internalName = firstName
            }
            if firstName == "_" {
                return internalName
            } else {
                return "\(firstName): \(internalName)"
            }
        }.joined(separator: ", ")

        let call = "viewModel.\(funcName)(\(args))"
        let hasReturn = funcDecl.signature.returnClause != nil
        let stmt = hasReturn ? "return \(call)" : call

        return ["\(raw: stmt)"]
    }
}
