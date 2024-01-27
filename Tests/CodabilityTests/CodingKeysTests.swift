// Copyright (c) 2024 David N Main

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftDiagnostics
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(CodabilityMacros)
import CodabilityMacros

let testMacros: [String: Macro.Type] = [
    "CodingKeys": CodingKeysMacro.self,
]
#endif

final class CodingKeysTests: XCTestCase {

    // the basic test struct prefix
    let structBar = """
        struct Bar: Codable {
            let a: String
            let b: Int
            let c: Double
    """

    // struct with a preceding macro
    func withMacro(args: String?) -> String {
        if let args {
            """
            @CodingKeys("\(args)")
            \(unexpanded)
            """
        } else { // use editor placeholder - DO NOT REPLACE THE PLACEHOLDER!!!
            """
            @CodingKeys(<#T##keys: String##String#>)
            \(unexpanded)
            """
        }
    }

    // The struct without macro expansion
    var unexpanded: String {
        """
        \(structBar)
        }
        """
    }

    // struct with expanded macro
    func expanded(a: String? = nil, b: String? = nil, c: String? = nil) -> String {
        """
        \(structBar)

            enum CodingKeys: String, CodingKey {
                case a\(a.map { " = \"\($0)\"" } ?? "")
                case b\(b.map { " = \"\($0)\"" } ?? "")
                case c\(c.map { " = \"\($0)\"" } ?? "")
            }
        }
        """
    }

    func testCodingKeysSanity() throws {
        #if canImport(CodabilityMacros)

        assertMacroExpansion(
            withMacro(args: "a=Apple"),
            expandedSource: expanded(a: "Apple"),
            macros: testMacros
        )

        assertMacroExpansion(
            withMacro(args: "a=Apple, b=Banana"),
            expandedSource: expanded(a: "Apple", b: "Banana"),
            macros: testMacros
        )

        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    // Check diagnostics and fixits
    func diagnosticTest(_ macroArg: String?, _ diagnositicMessage: String, _ fixitMsg: String?, _ severity: DiagnosticSeverity, _ expandedSource: String? = nil) {
        #if canImport(CodabilityMacros)

        let spec: DiagnosticSpec = if let fixitMsg {
            .init(message: diagnositicMessage, line: 1, column: 1, severity: severity, fixIts: [.init(message: fixitMsg)])
        } else {
            .init(message: diagnositicMessage, line: 1, column: 1, severity: severity)
        }

        assertMacroExpansion(
            withMacro(args: macroArg),
            expandedSource: expandedSource ?? unexpanded,
            diagnostics: [ spec ],
            macros: testMacros
        )

        #endif
    }

    func testDiagnostics() throws {
        #if canImport(CodabilityMacros)

        diagnosticTest(nil, "CodingKeys needs a coding key string", "Add a coding key string", .error, unexpanded)

        diagnosticTest("", "Empty string", "Add a coding key string", .warning, expanded())

        diagnosticTest("a=Apple, ",  "Empty name=key string", nil, .error, unexpanded)
        diagnosticTest("a=Apple, x", "Bad name=key string: \"x\"", nil, .error, unexpanded)
        diagnosticTest("a=",         "Coding key missing in: \"a=\"", nil, .error, unexpanded)
        diagnosticTest("=Apple",     "Property name missing in: \"=Apple\"", nil, .error, unexpanded)
        diagnosticTest("aa=Apple",   "\"aa\" is not a stored instance property", nil, .error, unexpanded)
        diagnosticTest("a=b",        "Coding key \"b\" is the name of a property with no key override", nil, .error, unexpanded)
        diagnosticTest("a=Apple, a=Foo",   "Duplicate property name in: \"a=Foo\"", nil, .error, unexpanded)
        diagnosticTest("a=Apple, b=Apple", "\"Apple\" is an existing coding key in: \"b=Apple\"", nil, .error, unexpanded)

        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
