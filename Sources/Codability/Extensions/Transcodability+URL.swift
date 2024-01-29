// Copyright (c) 2024 David N Main

import Foundation

/// Error thrown when a URL cannot be decoded from a String
public struct UncorrectableBadURL: Error {
    let url: String
}

extension URL: Transcodability {

    /// Decode a URL from a String, fixing any unencoded spaces
    ///
    /// - Throws: ``UncorrectableBadURL`` if the URL cannot be fixed.
    public static func decode(from value: String) throws -> URL {
        if let url = URL.correctingSpaces(in: value) {
            return url
        } else {
            throw UncorrectableBadURL(url: value)
        }
    }

    /// Encodes the URL using absoluteString.
    public static func encode(value: URL, to encoder: Encoder) throws {
        try value.absoluteString.encode(to: encoder)
    }
}

extension Swift.Optional: Transcodability where Wrapped == URL {

    /// Decode a URL from a String, fixing any unencoded spaces, and returning
    /// nil if a URL could not be constructed from the string. Also handles
    /// an empty string and returns a nil URL.
    ///
    /// - Throws: ``UncorrectableBadURL`` if the URL cannot be fixed.
    public static func decode(from value: String) throws -> URL? {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        
        return URL.correctingSpaces(in: value)
    }

    /// Encodes the URL using absoluteString, if not nil
    public static func encode(value: URL?, to encoder: Encoder) throws {
        if let value {
            try value.absoluteString.encode(to: encoder)
        } else {
            // need to use singleValueContainer otherwise nil is encoded as empty object
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

public extension URL {

    /// Attempt to initialize a URL by fixing unencoded spaces
    static func correctingSpaces(in s: String) -> URL? {
        URL(string: s) ?? URL(string: s.replacingOccurrences(of: " ", with: "%20"))
    }
}
