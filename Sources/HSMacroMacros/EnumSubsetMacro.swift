//
//  File.swift
//  
//
//  Created by shotaro.hirano on 2023/10/06.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EnumSubsetMacro: MemberMacro {
    enum EnumSubsetError: CustomStringConvertible, Error {
        case onlyApplicableToEnum
        
        var description: String {
            switch self {
            case .onlyApplicableToEnum: return "@EnumSubset can only be applied to an enum"
            }
        }
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw EnumSubsetError.onlyApplicableToEnum
        }
        
        guard let supersetType = (enumDecl
            .attributes.filter {
                $0.as(AttributeSyntax.self)?
                    .attributeName
                    .as(IdentifierTypeSyntax.self)?.name
                    .as(TokenSyntax.self)?.text == "EnumSubset"
            }.first?.as(AttributeSyntax.self))?
            .attributeName.as(IdentifierTypeSyntax.self)?
            .genericArgumentClause?
            .arguments.first?.as(GenericArgumentSyntax.self)?
            .argument.as(IdentifierTypeSyntax.self)?.name else {
            return []
        }
        
        let members = enumDecl.memberBlock.members
        let caseDecls = members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
        let elements = caseDecls.flatMap { $0.elements }
        let initializer = try InitializerDeclSyntax("init?(_ \(raw: supersetType.text.lowercased()): \(raw: supersetType.text))") {
            try SwitchExprSyntax("switch \(raw: supersetType.text.lowercased())") {
                for element in elements {
                    SwitchCaseSyntax(
                        """
                        case .\(element.name):
                            self = .\(element.name)
                        """
                    )
                }
                SwitchCaseSyntax("default: return nil")
            }
        }
        return [DeclSyntax(initializer)]
    }
}
