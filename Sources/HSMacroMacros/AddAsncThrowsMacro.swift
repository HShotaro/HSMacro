//
//  File.swift
//
//
//  Created by shotaro.hirano on 2023/10/31.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AddAsncThrowsMacro: PeerMacro {
    enum AddAsncThrowsError: CustomStringConvertible, Error {
        case onlyApplicableToFunction
        case noCompletionName
        case onlyApplicableToFunctionWithASingleFunctionArgument
        case notDefine
        case incorrectType
        case notResultType
        
        var description: String {
            switch self {
            case .onlyApplicableToFunction: return "AddAsncThrowsMacro can only be applied to function"
            case .noCompletionName: return "noCompletionName error"
            case .onlyApplicableToFunctionWithASingleFunctionArgument: return "AddAsncThrowsMacro can only be applied to FunctionWithASingleFunctionArgument"
            case .notDefine: return "notDefine error"
            case .incorrectType: return "incorrectType error"
            case .notResultType: return "notResultType error"
            }
        }
    }
    
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            throw AddAsncThrowsError.onlyApplicableToFunction
        }

        guard function.signature.parameterClause.parameters.count == 1,
              let functionCompletionParameter = function.signature.parameterClause.parameters.first?.type.as(AttributedTypeSyntax.self),
              let baseType = functionCompletionParameter.baseType.as(FunctionTypeSyntax.self) else {
            throw AddAsncThrowsError.onlyApplicableToFunctionWithASingleFunctionArgument
        }
        guard let typeStrTuple = try? getType(baseType: baseType) else {
            throw AddAsncThrowsError.incorrectType
        }
        if typeStrTuple.isResultType {
            return [DeclSyntax(stringLiteral: """
                            func \(function.name.text)() async throws -> \(typeStrTuple.text) {
                                return try await withCheckedThrowingContinuation { continuation in
                                    \(function.name.text) { value in
                                        switch result {
                                        case .success(let s):
                                            continuation.resume(with: s)
                                        case .failure(let error):
                                            continuation.resume(throwing: error)
                                        }
                                    }
                                }
                            }
                            """)]
        } else {
            return [DeclSyntax(stringLiteral: """
                            func \(function.name.text)() async -> \(typeStrTuple.text) {
                                return try await withCheckedContinuation { continuation in
                                    \(function.name.text) { value in
                                        continuation.resume(with: value)
                                    }
                                }
                            }
                            """)]
        }
        
        
    }
    
    static func getType(baseType: FunctionTypeSyntax) throws -> (text: String, isResultType: Bool) {
        let parameterType = baseType.parameters.first?.type.as(IdentifierTypeSyntax.self)
        let isResultType = parameterType?.name.text == "Result"
        let typeStrs = parameterType?.genericArgumentClause?.arguments.compactMap { $0.as(GenericArgumentSyntax.self)?.argument.as(IdentifierTypeSyntax.self)?.name.text } ?? []
        if isResultType {
            guard typeStrs.count == 2 else {
                throw AddAsncThrowsError.incorrectType
            }
            return (text: typeStrs[0].description, isResultType: true)
        } else {
            guard let typeText = parameterType?.name.text else {
                throw AddAsncThrowsError.incorrectType
            }
            return (text: typeText, isResultType: false)
        }
    }
}

