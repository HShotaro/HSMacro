import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct HSMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        EnumSubsetMacro.self,
        UnwrapURLMacro.self,
        AddAsncThrowsMacro.self
    ]
}
