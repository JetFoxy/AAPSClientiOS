import XCTest
@testable import AAPSClientiOS

final class NsTreatmentWriterTests: XCTestCase {

    func test_carbsPayloadMatchesContract() async throws {
        let mock = FixtureNightscoutClient()
        let writer = NsTreatmentWriterLive(client: mock)
        let date = Date(timeIntervalSince1970: 1525383.610088)

        try await writer.sendCarbs(grams: 30, at: date)

        let p = mock.postedPayloads.first!
        XCTAssertEqual(p["eventType"] as? String, "Carb Correction")
        XCTAssertEqual(p["carbs"] as? Double, 30)
        XCTAssertEqual(p["enteredBy"] as? String, "AAPSClient-iOS")
        XCTAssertNotNil(p["date"])
    }

    func test_tempTargetPayloadMatchesContract() async throws {
        let mock = FixtureNightscoutClient()
        let writer = NsTreatmentWriterLive(client: mock)

        try await writer.sendTempTarget(targetMgdl: 90, durationMin: 60, reason: .eatingSoon)

        let p = mock.postedPayloads.first!
        XCTAssertEqual(p["eventType"] as? String, "Temporary Target")
        XCTAssertEqual(p["duration"] as? Int, 60)
        XCTAssertEqual(p["targetBottom"] as? Int, 90)
        XCTAssertEqual(p["targetTop"] as? Int, 90)
        XCTAssertEqual(p["units"] as? String, "mg/dl")
        XCTAssertEqual(p["reason"] as? String, "Eating Soon")
    }

    func test_cancelTempTargetHasZeroDuration() async throws {
        let mock = FixtureNightscoutClient()
        let writer = NsTreatmentWriterLive(client: mock)

        try await writer.cancelTempTarget()

        let p = mock.postedPayloads.first!
        XCTAssertEqual(p["eventType"] as? String, "Temporary Target")
        XCTAssertEqual(p["duration"] as? Int, 0)
    }

    func test_sendCarbsPropagatesNetworkError() async {
        let mock = FixtureNightscoutClient()
        mock.shouldThrow = NsError.noNetwork
        let writer = NsTreatmentWriterLive(client: mock)

        do {
            try await writer.sendCarbs(grams: 10, at: Date())
            XCTFail("Expected error")
        } catch {
            guard case NsError.noNetwork = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func test_siteChangePayload() {
        let now = Date()
        let p = NsTreatmentWriterLive.buildEvent(eventType: "Site Change", at: now, notes: "right arm", glucoseMgdl: nil, durationMin: nil)
        XCTAssertEqual(p["eventType"] as? String, "Site Change")
        XCTAssertEqual(p["notes"] as? String, "right arm")
        XCTAssertNotNil(p["date"])
        XCTAssertEqual(p["app"] as? String, "AAPSClient-iOS")
        XCTAssertNil(p["glucose"])
    }

    func test_bgCheckPayloadHasGlucose() {
        let now = Date()
        let p = NsTreatmentWriterLive.buildEvent(eventType: "BG Check", at: now, notes: nil, glucoseMgdl: 120, durationMin: nil)
        XCTAssertEqual(p["eventType"] as? String, "BG Check")
        XCTAssertEqual(p["glucose"] as? Int, 120)
        XCTAssertEqual(p["units"] as? String, "mg/dl")
    }

    func test_loopModePayload() {
        let p = NsTreatmentWriterLive.buildLoopMode("OPEN_LOOP", durationMin: 60)
        XCTAssertEqual(p["eventType"] as? String, "OpenAPS Offline")
        XCTAssertEqual(p["mode"] as? String, "OPEN_LOOP")
        XCTAssertEqual(p["duration"] as? Int, 60)
        XCTAssertEqual(p["app"] as? String, "AAPSClient-iOS")
    }
}
