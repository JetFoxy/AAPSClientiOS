import XCTest
@testable import AAPSClientiOS

final class NightscoutReadTests: XCTestCase {

    func test_fetchEntriesReturnsParsedData() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        let fixture = try loadFixture("entries")
        transport.responseData = fixture
        let entries = try await client.fetchEntries(limit: 10)

        XCTAssertEqual(transport.lastRequest?.url?.absoluteString.contains("api/v3/entries"), true)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].mgdl, 120)
        XCTAssertEqual(entries[0].trend, .flat)
    }

    func test_fetchTreatmentsReturnsParsedData() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        let fixture = try loadFixture("treatments")
        transport.responseData = fixture
        let treatments = try await client.fetchTreatments()

        XCTAssertEqual(treatments.count, 3)
        XCTAssertEqual(treatments[0].eventType, "Meal Bolus")
    }

    func test_fetchTreatmentsWithSinceAddsFilter() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        transport.responseData = #"{"status":200,"result":[]}"# .data(using: .utf8)!
        let since = Date(timeIntervalSince1970: 1000)
        _ = try await client.fetchTreatments(since: since)

        let url = transport.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("srvModified$gte="))
    }

    func test_fetchDeviceStatusReturnsLoopStatus() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        let fixture = try loadFixture("devicestatus")
        transport.responseData = fixture
        let status = try await client.fetchDeviceStatus()

        XCTAssertEqual(status?.iob, 1.85)
        XCTAssertEqual(status?.cob, 24.0)
    }

    func test_fetchProfileReturnsParsedProfile() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        let fixture = try loadFixture("profile")
        transport.responseData = fixture
        let profile = try await client.fetchProfile()

        XCTAssertEqual(profile.units, .mgdl)
        XCTAssertEqual(profile.basal.count, 3)
    }

    func test_urlHasNoDoubleSlash() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        transport.responseData = #"{"status":200,"result":[]}"# .data(using: .utf8)!
        _ = try await client.fetchEntries(limit: 10)

        let url = transport.lastRequest?.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("test.nightscout.example.com/api/v3/entries"))
        XCTAssertFalse(url.contains("//api"))
    }

    func test_serverErrorThrowsServerCase() async throws {
        let transport = MockAuthTransport()
        transport.responseData = #"{"token":"jwt","iat":1,"exp":99999}"# .data(using: .utf8)!
        let client = NightscoutClientLive(baseURL: testBaseURL, accessToken: "t", transport: transport)
        try await client.authorize()

        transport.responseCode = 500
        transport.responseData = Data()

        do {
            _ = try await client.fetchEntries(limit: 10)
            XCTFail("Expected error")
        } catch {
        }
    }
}
