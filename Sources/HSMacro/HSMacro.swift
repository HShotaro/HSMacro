// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "HSMacroMacros", type: "StringifyMacro")

@freestanding(expression)
public macro unwrap(_ urlString: String) -> URL = #externalMacro(module: "HSMacroMacros", type: "UnwrapMacro")

@attached(member, names: named(init))
public macro EnumSubset<Superset>() = #externalMacro(module: "HSMacroMacros", type: "EnumSubsetMacro")
