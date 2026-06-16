import XCTest
@testable import AAPSClientiOS

final class KeychainStoreTests: XCTestCase {

    func test_storesAndReadsSecret() throws {
        let s = KeychainStore(service: "test.aapsclient")
        try s.set("abc", for: .nsAccessToken)
        XCTAssertEqual(try s.get(.nsAccessToken), "abc")
    }

    func test_updatesExistingSecret() throws {
        let s = KeychainStore(service: "test.aapsclient")
        try s.set("first", for: .nsAccessToken)
        try s.set("second", for: .nsAccessToken)
        XCTAssertEqual(try s.get(.nsAccessToken), "second")
    }

    func test_deleteRemovesSecret() throws {
        let s = KeychainStore(service: "test.aapsclient")
        try s.set("xyz", for: .nsAccessToken)
        try s.delete(.nsAccessToken)
        XCTAssertNil(try s.get(.nsAccessToken))
    }

    func test_returnsNilForMissing() throws {
        let s = KeychainStore(service: "test.aapsclient.missing")
        XCTAssertNil(try s.get(.nsAccessToken))
    }
}
