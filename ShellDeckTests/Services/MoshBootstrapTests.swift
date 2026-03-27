import XCTest
@testable import ShellDeck

final class MoshBootstrapTests: XCTestCase {

    func testParseValidOutput() throws {
        let output = "MOSH CONNECT 60001 AbCdEf1234567890abcdef"
        let info = try MoshBootstrap.parse(output, host: "example.com")

        XCTAssertEqual(info.host, "example.com")
        XCTAssertEqual(info.port, 60001)
        XCTAssertEqual(info.key, "AbCdEf1234567890abcdef")
    }

    func testParseMultiLineOutput() throws {
        let output = """
        mosh-server (mosh 1.4.0)
        Copyright 2012 Keith Winstein
        [mosh-server detached, pid = 12345]

        MOSH CONNECT 60002 XyZ9876543210abcdefghi
        """
        let info = try MoshBootstrap.parse(output, host: "10.0.0.1")

        XCTAssertEqual(info.port, 60002)
        XCTAssertEqual(info.key, "XyZ9876543210abcdefghi")
    }

    func testParseNoConnectLine_throws() {
        let output = "some random output\nno connect line here"

        XCTAssertThrowsError(try MoshBootstrap.parse(output, host: "h")) { error in
            XCTAssertEqual(error as? MoshBootstrapError, .noMoshConnectLine)
        }
    }

    func testParseInvalidPort_throws() {
        let output = "MOSH CONNECT notaport AbCdEf1234567890abcdef"

        XCTAssertThrowsError(try MoshBootstrap.parse(output, host: "h")) { error in
            XCTAssertEqual(error as? MoshBootstrapError, .invalidPort("notaport"))
        }
    }

    func testParseInvalidKeyLength_throws() {
        let output = "MOSH CONNECT 60001 shortkey"

        XCTAssertThrowsError(try MoshBootstrap.parse(output, host: "h")) { error in
            XCTAssertEqual(error as? MoshBootstrapError, .invalidKeyLength(8))
        }
    }

    func testParseMalformedOutput_throws() {
        let output = "MOSH CONNECT 60001"

        XCTAssertThrowsError(try MoshBootstrap.parse(output, host: "h")) { error in
            XCTAssertEqual(error as? MoshBootstrapError, .malformedOutput)
        }
    }
}
