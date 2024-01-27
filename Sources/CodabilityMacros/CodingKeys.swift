// Copyright (c) 2024 David N Main

import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct CodingKeysMacro: MemberMacro {

    // Macro implementation - see documentation for CodingKeys(_:) in Codability.swift
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {

        guard let argString = node.firstStringArgument?.trimmingCharacters(in: .whitespaces) else {
            diagnose(.noStringArg, initialStringFixits())
            return []
        }

        let storedPropertyNames = declaration.memberBlock.instanceStoredPropertyNames
        let nameSet = Set(storedPropertyNames)
        var propNameKeys = [String: String]()

        if !argString.isEmpty {
            // parse the macro arg string into comma separated parts then equal-sign separated pairs
            let argParts = argString.split(separator: ",", omittingEmptySubsequences: false)

            for part in argParts {
                let nameAndCodingKey = part.split(separator: "=", omittingEmptySubsequences: false)
                if nameAndCodingKey.count == 2 {
                    let name  = nameAndCodingKey[0].trimmingCharacters(in: .whitespaces)
                    let codingKey = nameAndCodingKey[1].trimmingCharacters(in: .whitespaces)

                    // validation ...
                    if name.isEmpty {
                        diagnose(.missingPropName(part))
                        return []
                    }
                    if codingKey.isEmpty {
                        diagnose(.missingCodingKey(part))
                        return []
                    }

                    if !nameSet.contains(name) {
                        diagnose(.nameNotStoredProp(name))
                        return []
                    }

                    if propNameKeys[name] != nil {
                        diagnose(.duplicatePropName(part))
                        return []
                    }

                    if propNameKeys.values.contains(where: {$0 == codingKey}) {
                        diagnose(.duplicateCodingKey(codingKey, part))
                        return []
                    }

                    propNameKeys[name] = codingKey

                } else {
                    if part.trimmingCharacters(in: .whitespaces).isEmpty {
                        diagnose(.emptyPart)
                        return []
                    }

                    diagnose(.badPart(part))
                    return []
                }
            }
        } else {
            diagnose(.emptyString, initialStringFixits())
        }

        // Validate that no coding key is the name of a property that does not have a new coding key
        for codingKey in propNameKeys.values {
            if nameSet.contains(codingKey) && propNameKeys[codingKey] == nil {
                diagnose(.codingKeyShadowsProperty(codingKey))
                return []
            }
        }

        // Build CodingKeys enum
        var enumSyntax = try EnumDeclSyntax("enum CodingKeys: String, CodingKey { }")
        for propName in storedPropertyNames {
            let newCase = if let value = propNameKeys[propName] {
                MemberBlockItemSyntax(decl: try EnumCaseDeclSyntax("case \(raw: propName) = \(literal: value)"))
            } else {
                MemberBlockItemSyntax(decl: try EnumCaseDeclSyntax("case \(raw: propName)"))
            }
            enumSyntax.memberBlock.members.append(newCase)
        }

        return [DeclSyntax(enumSyntax)]

        // method-local helpers
        func diagnose(_ message: Diagnosis, _ fixits: [FixIt] = []) {
            context.diagnose(.init(node: node, message: message, fixIts: fixits))
        }

        func initialStringFixits() -> [FixIt] {
            let newAttributeSyntax: AttributeSyntax = "@CodingKeys(\"<#property-name#>=<#coding-key#>\")"
            return [.init(message: FixItMsg.addCodingKeyString,
                          changes: [.replace(oldNode: Syntax(node), newNode: Syntax(newAttributeSyntax))])]
        }
    }

    enum Diagnosis: DiagnosticMessage {
        case noStringArg
        case emptyString
        case codingKeyShadowsProperty(_ codingKey: any StringProtocol)
        case missingPropName(_ part: any StringProtocol)
        case missingCodingKey(_ part: any StringProtocol)
        case nameNotStoredProp(_ name: any StringProtocol)
        case duplicatePropName(_ part: any StringProtocol)
        case duplicateCodingKey(_ codingKey: any StringProtocol, _ part: any StringProtocol)
        case emptyPart
        case badPart(_ part: any StringProtocol)

        var message: String {
            switch self {
            case .noStringArg: "CodingKeys needs a coding key string"
            case .emptyString: "Empty string"
            case .codingKeyShadowsProperty(let codingKey): "Coding key \"\(codingKey)\" is the name of a property with no key override"
            case .missingPropName(let part): "Property name missing in: \"\(part.trimmingCharacters(in: .whitespaces))\""
            case .missingCodingKey(let part): "Coding key missing in: \"\(part.trimmingCharacters(in: .whitespaces))\""
            case .nameNotStoredProp(let name): "\"\(name)\" is not a stored instance property"
            case .duplicatePropName(let part): "Duplicate property name in: \"\(part.trimmingCharacters(in: .whitespaces))\""
            case .duplicateCodingKey(let codingKey, let part): "\"\(codingKey)\" is an existing coding key in: \"\(part.trimmingCharacters(in: .whitespaces))\""
            case .emptyPart: "Empty name=key string"
            case .badPart(let part): "Bad name=key string: \"\(part.trimmingCharacters(in: .whitespaces))\""
            }
        }

        var severity: DiagnosticSeverity {
            switch self {
            case .emptyString: .warning
            default: .error
            }
        }

        var diagnosticID: MessageID { .init(domain: "Codability", id: "CodingKeys") }
    }

    enum FixItMsg: FixItMessage {
        case addCodingKeyString

        var message: String {
            switch self {
            case .addCodingKeyString: "Add a coding key string"
            }
        }

        var fixItID: MessageID { .init(domain: "Codability", id: "CodingKeys") }
    }
}
