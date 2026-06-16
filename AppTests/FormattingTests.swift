import XCTest
@testable import AAPSClientiOS

final class FormattingTests: XCTestCase {

    private let thresholds = AlarmThresholds(urgentLow: 55, low: 70, high: 180, urgentHigh: 250, staleMinutes: 15)

    func test_classifyUrgentLow() {
        XCTAssertEqual(Formatting.classify(mgdl: 50, thresholds: thresholds), .urgentLow)
    }

    func test_classifyLow() {
        XCTAssertEqual(Formatting.classify(mgdl: 60, thresholds: thresholds), .low)
    }

    func test_classifyInRange() {
        XCTAssertEqual(Formatting.classify(mgdl: 120, thresholds: thresholds), .inRange)
    }

    func test_classifyHigh() {
        XCTAssertEqual(Formatting.classify(mgdl: 200, thresholds: thresholds), .high)
    }

    func test_classifyUrgentHigh() {
        XCTAssertEqual(Formatting.classify(mgdl: 260, thresholds: thresholds), .urgentHigh)
    }

    func test_formatMgdl() {
        XCTAssertEqual(Formatting.format(120, units: .mgdl), "120")
    }

    func test_formatMmol() {
        let result = Formatting.format(120, units: .mmol)
        XCTAssertTrue(result.hasPrefix("6."))
    }
}
