// Copyright (c) 2024 David N Main

/// Add a CodingKeys enum in the same way as the default Swift Codable synthesis but with
/// a set of coding key value overrides. Normally, adding a coding key override would require
/// hand-writing the entire CodingKeys enum with all the property names included, not just the
/// overridden property.
///
/// Example usage:
///
/// ```swift
/// @CodingKeys("name=firstName, lastName=surname")
/// struct Person: Codable {
///    let name: String
///    let lastName: String
///    let age: Int
/// }
/// ```
///
/// will generate the following coding keys enum:
///
/// ```swift
/// enum CodingKeys: String, CodingKey {
///     case name = "firstName"
///     case lastName = "surname"
///     case age
/// }
/// ```
///
/// An error is produced if the property name of an override does not match a stored property
/// of the type.
///
/// These are some of the other diagnostics that may be produced:
/// @Image(source: "diagnostics.png", alt: "Screenshot of diagnostics produced by the macro")
///
/// - Parameter keys: a string consisting of comma separated elements of the form
///                   "property-name=coding-key". The property name and coding key will have
///                   leading and trailing whitespace removed before being used. An empty string
///                   will produce a warning.
///
@attached(member, names: named(CodingKeys), named(debug))
public macro CodingKeys(_ keys: String) = #externalMacro(module: "CodabilityMacros", type: "CodingKeysMacro")
