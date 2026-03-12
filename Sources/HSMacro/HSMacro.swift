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
public macro unwrap(_ urlString: String) -> URL = #externalMacro(module: "HSMacroMacros", type: "UnwrapURLMacro")

@attached(member, names: named(init))
public macro EnumSubset<Superset>() = #externalMacro(module: "HSMacroMacros", type: "EnumSubsetMacro")

@attached(peer, names: overloaded)
macro AddAsncThrows() = #externalMacro(module: "HSMacroMacros", type: "AddAsncThrowsMacro")

/// `IosXxxViewModel` クラスに付与することで、KMP 統合に必要な3つのメンバーを自動生成する。
///
///   - `private let viewModel: XxxViewModel`
///   - `@Published var uiState = XxxUiState()`
///   - `func setupKmpObservations()` — `viewModel.observeUiState { ... }` を含む
///
/// クラス内の `@Published var` プロパティも走査し、`@KmpObserveIgnore` のないものを
/// `setupKmpObservations()` に追加する。
@attached(member, names: named(setupKmpObservations), named(viewModel), named(uiState))
public macro KmpObservableViewModel() = #externalMacro(module: "HSMacroMacros", type: "KmpObservableViewModelMacro")

/// `@KmpObservableViewModel` の observation 自動生成から除外するマーカー。
/// KMP との型変換が必要なプロパティに付与する。
@attached(peer)
public macro KmpObserveIgnore() = #externalMacro(module: "HSMacroMacros", type: "KmpObserveIgnoreMacro")
