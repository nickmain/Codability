// Copyright (c) 2024 David N Main

import XCTest
import Codability

final class CodingKeysUsageTests: XCTestCase {

    struct Foo: Codable {
        let a: String
        let b: Int

        enum CodingKeys: String, CodingKey {
            case a = "Apple"
            case b
        }
    }

    @CodingKeys("a=Apple")
    struct Bar: Codable {
        let a: String
        let b: Int
    }

    let data = "{ \"Apple\": \"Hello\", \"b\": 23 }".data(using: .utf8)!

    func testSanity() throws {
        XCTAssertEqual(Foo.CodingKeys.a.rawValue, Bar.CodingKeys.a.rawValue)
        XCTAssertEqual(Foo.CodingKeys.b.rawValue, Bar.CodingKeys.b.rawValue)

        let foo = try JSONDecoder().decode(Foo.self, from: data)
        let bar = try JSONDecoder().decode(Bar.self, from: data)

        XCTAssertEqual(foo.a, bar.a)
        XCTAssertEqual(foo.b, bar.b)
    }
}
