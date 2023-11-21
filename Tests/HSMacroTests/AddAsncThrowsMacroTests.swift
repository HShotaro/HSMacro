//
//  File.swift
//  
//
//  Created by shotaro.hirano on 2023/10/31.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(HSMacroMacros)
import HSMacroMacros
#endif

final class AddAsncThrowsMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "AddAsncThrows" : AddAsncThrowsMacro.self,
    ]
    
    func testMacro() {
        assertMacroExpansion(
            """
            @AddAsncThrows()
            func fetchAvatar(onCompletion: @escaping (Int) -> Void
                ) {
                    let task = URLSession.shared.dataTask(with: url){ data, response, error in
                        if let response = response as? HTTPURLResponse {
                            onCompletion(response.statusCode)
                        }
                    }
                    task.resume()
                }
            """,
            expandedSource: """
            func fetchAvatar(onCompletion: @escaping (Int) -> Void
                ) {
                    let task = URLSession.shared.dataTask(with: url){ data, response, error in
                        if let response = response as? HTTPURLResponse {
                            onCompletion(response.statusCode)
                        }
                    }
                    task.resume()
                }
            
            func fetchAvatar() async -> Int {
                return try await withCheckedContinuation { continuation in
                    fetchAvatar { value in
                        continuation.resume(with: value)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMacroWithError() {
        assertMacroExpansion(
            """
            @AddAsncThrows()
            func fetchAvatar(onCompletion: @escaping (Result<Int, Error>) -> Void
                ) {
                    let task = URLSession.shared.dataTask(with: url){ data, response, error in
                        if let error = error{
                            onCompletion(.failure(error))
                            return
                        }
                        if let response = response as? HTTPURLResponse {
                            onCompletion(.success(response.statusCode))
                        }
                    }
                    task.resume()
                }
            """,
            expandedSource: """
            func fetchAvatar(onCompletion: @escaping (Result<Int, Error>) -> Void
                ) {
                    let task = URLSession.shared.dataTask(with: url){ data, response, error in
                        if let error = error{
                            onCompletion(.failure(error))
                            return
                        }
                        if let response = response as? HTTPURLResponse {
                            onCompletion(.success(response.statusCode))
                        }
                    }
                    task.resume()
                }
            
            func fetchAvatar() async throws -> Int {
                return try await withCheckedThrowingContinuation { continuation in
                    fetchAvatar { value in
                        switch result {
                        case .success(let s):
                            continuation.resume(with: s)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}

