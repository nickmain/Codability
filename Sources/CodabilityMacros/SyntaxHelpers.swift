// Copyright (c) 2024 David N Main

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public extension SwiftSyntax.MemberBlockSyntax {

    /// A stored property
    struct StoredPropertyInfo {
        let isStatic: Bool
        let name: String
        let type: String?
        let value: String?
    }

    /// Get the stored properties from a member block
    var storedProperties: [StoredPropertyInfo] {
        var props = [StoredPropertyInfo]()

        for member in self.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                let isStatic = varDecl.modifiers.contains {
                    $0.name.tokenKind == TokenKind.keyword(.static)
                }

                for binding in varDecl.bindings {
                    if binding.accessorBlock != nil { continue } // skip computed props

                    let name  = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                    let type  = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text
                    let value = binding.initializer?.value.description

                    if let name {
                        props.append(.init(isStatic: isStatic, name: name, type: type, value: value))
                    }
                }
            }
        }

        return props
    }

    /// Get the names of the instance stored properties
    var instanceStoredPropertyNames: [String] {
        storedProperties.filter { !$0.isStatic } .map(\.name)
    }
}

extension AttributeSyntax {

    // Get the first argument of the macro attribute, if a string
    var firstStringArgument: String? {
        if let expressionList = self.arguments?.as(LabeledExprListSyntax.self),
           let stringLiteral = expressionList.first?.expression.as(StringLiteralExprSyntax.self) {
            return stringLiteral.segments.description
        }
        return nil
    }
}
