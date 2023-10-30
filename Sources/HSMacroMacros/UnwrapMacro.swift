//
//  File.swift
//  
//
//  Created by shotaro.hirano on 2023/10/30.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UnwrapMacro: ExpressionMacro {
    enum UnwrapError: CustomStringConvertible, Error {
        case noArgument
        case cannotConvertToStrSyntax
        case cannotConvertToTokenSyntax
        
        var description: String {
            switch self {
            case .noArgument:
                return "noArgument error"
            case .cannotConvertToStrSyntax:
                return "cannotConvertToStrSyntax error"
            case .cannotConvertToTokenSyntax:
                return "cannotConvertToTokenSyntax error"
            }
        }
    }
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            throw UnwrapError.noArgument
        }
        guard let strSyntax = argument.as(StringLiteralExprSyntax.self) else {
            throw UnwrapError.cannotConvertToStrSyntax
        }
        guard let tokenSyntax = strSyntax.segments.first?.as(StringSegmentSyntax.self)?.content else {
            throw UnwrapError.cannotConvertToTokenSyntax
        }
        return """
            guard let url = URL(string: "\(tokenSyntax)") else {
                preconditionFailure(
                    \(literal: "Unexpectedly found nil: ‘\(argument.description)’ "),
                    file: \(raw: String(describing: context.location(of: argument))),
                    line: \(raw: String(describing: context.location(of: argument)))
                )
            }
            return url
        """
    }
}
