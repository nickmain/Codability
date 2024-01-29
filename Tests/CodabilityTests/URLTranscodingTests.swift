// Copyright (c) 2024 David N Main

import XCTest
import Codability

final class URLTranscodingTests: XCTestCase {

    struct TestStruct: Codable {
        let rawURL: URL
        let rawOptionalURL: URL?
        @TC var tcURL: URL
        @TC var tcOptionalURL: URL?

        init(_ rawURLs: String, _ rawOptionalURLs: String?, _ tcURLs: String, _ tcOptionalURLs: String?) {
            rawURL = URL(string: rawURLs)!
            rawOptionalURL = if let rawOptionalURLs { URL(string: rawOptionalURLs)! } else { nil }
            tcURL = URL(string: tcURLs)!
            tcOptionalURL = if let tcOptionalURLs { URL(string: tcOptionalURLs)! } else { nil }
        }
    }

    func testDecoding() throws {
        func decode(_ rawURL: String, _ rawOptionalURL: String?, _ tcURL: String, _ tcOptionalURL: String?) throws -> TestStruct {
            let json = """
                  { "tcOptionalURL": \(tcOptionalURL.map { "\"\($0)\"" }  ?? "null"),
                    "rawOptionalURL": \(rawOptionalURL.map { "\"\($0)\"" } ?? "null"),
                    "rawURL": "\(rawURL)",
                    "tcURL": "\(tcURL)" }
                """
                .data(using: .utf8)!

            return try JSONDecoder().decode(TestStruct.self, from: json)
        }

        let goodUrlString = "http://foo.com"
        let spacedString  = "http://bar.com/hello world"
        let goodUrl = URL(string: goodUrlString)!
        let spacedUrl = URL(string: "http://bar.com/hello%20world")!

        var ts = try decode(goodUrlString, nil, spacedString, nil)
        XCTAssertEqual(ts.rawURL, goodUrl)
        XCTAssertEqual(ts.tcURL, spacedUrl)
        XCTAssertNil(ts.rawOptionalURL)
        XCTAssertNil(ts.tcOptionalURL)

        ts = try decode(goodUrlString, nil, spacedString, spacedString)
        XCTAssertEqual(ts.rawURL, goodUrl)
        XCTAssertEqual(ts.tcURL, spacedUrl)
        XCTAssertEqual(ts.tcOptionalURL, spacedUrl)
        XCTAssertNil(ts.rawOptionalURL)

        ts = try decode(goodUrlString, goodUrlString, spacedString, "  ") // empty string as nil
        XCTAssertEqual(ts.rawURL, goodUrl)
        XCTAssertEqual(ts.tcURL, spacedUrl)
        XCTAssertEqual(ts.rawOptionalURL, goodUrl)
        XCTAssertNil(ts.tcOptionalURL)

        do {
            ts = try decode(goodUrlString, goodUrlString, "", "")  // empty string throws
        } catch is UncorrectableBadURL {
            // OK
            return
        }

        XCTFail("Did not throw UncorrectableBadURL")
    }

    func testEncoding() throws {
        struct StringStruct: Codable {
            let rawURL: String
            let rawOptionalURL: String?
            let tcURL: String
            let tcOptionalURL: String?

            static func from(_ json: Data) throws -> Self {
                print(String(data: json, encoding: .utf8)!)
                return try JSONDecoder().decode(StringStruct.self, from: json)
            }
        }

        var ts = TestStruct("http://foo.com", nil, "http://bar.com", nil)
        var strings = try StringStruct.from(try JSONEncoder().encode(ts))
        XCTAssertEqual(strings.rawURL, "http://foo.com")
        XCTAssertEqual(strings.tcURL, "http://bar.com")
        XCTAssertNil(strings.rawOptionalURL)
        XCTAssertNil(strings.tcOptionalURL)

        ts = TestStruct("http://foo.com", "http://foo.com", "http://bar.com", "http://bar.com")
        strings = try StringStruct.from(try JSONEncoder().encode(ts))
        XCTAssertEqual(strings.rawURL, "http://foo.com")
        XCTAssertEqual(strings.rawOptionalURL, "http://foo.com")
        XCTAssertEqual(strings.tcURL, "http://bar.com")
        XCTAssertEqual(strings.tcOptionalURL, "http://bar.com")
    }
}
