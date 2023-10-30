//
//  File.swift
//  
//
//  Created by shotaro.hirano on 2023/10/30.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UnwrapURLMacro: ExpressionMacro {
    enum UnwrapURLError: CustomStringConvertible, Error {
        case noArgument
        case cannotConvertToStrSyntax
        case cannotConvertToTokenSyntax
        case noLocation
        
        var description: String {
            switch self {
            case .noArgument:
                return "noArgument error"
            case .cannotConvertToStrSyntax:
                return "cannotConvertToStrSyntax error"
            case .cannotConvertToTokenSyntax:
                return "cannotConvertToTokenSyntax error"
            case .noLocation:
                return "noLocation error"
            }
        }
    }
    
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            throw UnwrapURLError.noArgument
        }
        guard let strSyntax = argument.as(StringLiteralExprSyntax.self) else {
            throw UnwrapURLError.cannotConvertToStrSyntax
        }
        guard let tokenSyntax = strSyntax.segments.first?.as(StringSegmentSyntax.self)?.content else {
            throw UnwrapURLError.cannotConvertToTokenSyntax
        }
        guard let location = context.location(of: tokenSyntax) else {
            throw UnwrapURLError.noLocation
        }
        return """
        {
            guard let url = URL(string: "\(tokenSyntax)") else {
                preconditionFailure(
                    \(literal: "Unexpectedly found nil: \(argument.description) "),
                    file: \(location.file),
                    line: \(location.line)
                )
            }
            return url
        }()
        """
    }
}
