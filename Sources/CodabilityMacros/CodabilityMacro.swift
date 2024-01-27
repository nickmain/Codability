// Copyright (c) 2024 David N Main

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CodabilityPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodingKeysMacro.self,
    ]
}
