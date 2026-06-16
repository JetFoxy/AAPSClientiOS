import XCTest
@testable import AAPSClientiOS

final class StatisticsTests: XCTestCase {

    private let thresholds = AlarmThresholds(urgentLow: 55, low: 70, high: 180, urgentHigh: 250, staleMinutes: 15)

    func test_emptyReturnsZeros() {
        let s = StatisticsCompute.stats(readings: [], thresholds: thresholds)
        XCTAssertEqual(s.count, 0)
        XCTAssertEqual(s.averageMgdl, 0)
    }

    func test_singleValue() {
        let readings = [GlucoseReading]()
        let s = StatisticsCompute.stats(readings: readings, thresholds: thresholds)
        XCTAssertEqual(s.count, 0)
    }

    func test_allInRange() {
        let now = Date()
        let readings: [GlucoseReading] = (0..<10).map { i in
            GlucoseReading(date: now.addingTimeInterval(Double(-i) * 300), mgdl: 120, trend: .flat)
        }
        let s = StatisticsCompute.stats(readings: readings, thresholds: thresholds)
        XCTAssertEqual(s.count, 10)
        XCTAssertEqual(s.averageMgdl, 120)
        XCTAssertEqual(s.tirInRange, 100)
        XCTAssertEqual(s.tirBelow, 0)
    }

    func test_mixedRange() {
        let now = Date()
        let readings: [GlucoseReading] = [
            GlucoseReading(date: now, mgdl: 50, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-300), mgdl: 65, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-600), mgdl: 120, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-900), mgdl: 200, trend: .flat),
        ]
        let s = StatisticsCompute.stats(readings: readings, thresholds: thresholds)
        XCTAssertEqual(s.tirBelowUrgent, 25)
        XCTAssertEqual(s.tirBelow, 25)
        XCTAssertEqual(s.tirInRange, 25)
        XCTAssertEqual(s.tirAbove, 25)
        XCTAssertTrue(s.sdMgdl > 0)
        XCTAssertTrue(s.gmiPercent > 0)
    }
}
