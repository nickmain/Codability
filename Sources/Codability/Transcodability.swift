// Copyright (c) 2024 David N Main

import Foundation

/// Conform to this protocol to provide a way to encode/decode from another
/// Codable type and allow a type to be used with the ``TC`` property wrapper.
public protocol Transcodability {

    /// The Codable type that encoding and decoding operations are forwarded to.
    associatedtype CodableType: Codable

    /// Decode from the associated Codable type
    static func decode(from value: CodableType) throws -> Self

    /// Encode to the associated Codable type
    static func encode(value: Self, to encoder: Encoder) throws
}

/// Property wrapper that is Codable and can act as a proxy between
/// the wrapped type and another Codable type. The wrapped type must
/// conform to ``Transcodability``. The proxy target type is ``Transcodability/CodableType``.
///
/// This is useful where the wrapped type is already codable, so adding
/// Codable conformance via an extension does nothing, but the default
/// conformance needs to be overridden to fix deficiencies.
///
/// The property type may be optional or non-optional.
///
/// Example, assuming the example ``Transcodability`` conformance for URL:
///
/// ```swift
///    struct SomeStruct: Codable {
///        @TC var tcURL: URL
///        @TC var tcOptionalURL: URL?
///    }
/// ```
///
/// This intercepts the URL decoding from String and adds correction of non-percent-encoded
/// spaces, which would otherwise cause the default URL decoding to throw. In the optional case
/// it also handles an empty string being present in the JSON instead of null or missing.
@propertyWrapper
public struct TC<T: Transcodability>: Codable {

    public var wrappedValue: T

    public init(from decoder: Decoder) throws {
        let codableValue = try decoder.singleValueContainer().decode(T.CodableType.self)

        wrappedValue = try T.decode(from: codableValue)
    }

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        try T.encode(value: wrappedValue, to: encoder)
    }
}

extension KeyedDecodingContainer {
    /// Override decoding of a ``TC`` property where the wrapped type is optional and the
    /// value is missing from the JSON.
    ///
    /// Property wrappers are never optional even if the wrapped type is optional, so if the
    /// value is missing then decoding will throw without this extension.
    public func decode<T>(_ type: TC<T>.Type, forKey key: Self.Key) throws -> TC<T> where T: IsOptional {
        try decodeIfPresent(type, forKey: key) ?? TC(wrappedValue: nil)
    }
}
