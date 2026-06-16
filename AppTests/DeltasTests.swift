import XCTest
@testable import AAPSClientiOS

final class DeltasTests: XCTestCase {

    func test_returnsNilForEmpty() {
        let deltas = DeltasCompute.compute(readings: [], units: .mgdl)
        XCTAssertNil(deltas.delta)
        XCTAssertNil(deltas.delta15)
        XCTAssertNil(deltas.delta40)
    }

    func test_computesDeltasInMgdl() {
        let now = Date()
        let readings: [GlucoseReading] = [
            GlucoseReading(date: now, mgdl: 120, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-5 * 60), mgdl: 125, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-15 * 60), mgdl: 130, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-40 * 60), mgdl: 140, trend: .flat),
        ]
        let deltas = DeltasCompute.compute(readings: readings, units: .mgdl)
        XCTAssertEqual(deltas.delta, -5)
        XCTAssertEqual(deltas.delta15, -10)
        XCTAssertEqual(deltas.delta40, -20)
    }

    func test_computesDeltasInMmol() {
        let now = Date()
        let readings: [GlucoseReading] = [
            GlucoseReading(date: now, mgdl: 120, trend: .flat),
            GlucoseReading(date: now.addingTimeInterval(-5 * 60), mgdl: 108, trend: .flat),
        ]
        let deltas = DeltasCompute.compute(readings: readings, units: .mmol)
        let expected = Int((Double(120 - 108) / 18.0182).rounded())
        XCTAssertEqual(deltas.delta, expected)
    }

    func test_returnsNilForMissingTimeWindows() {
        let now = Date()
        let readings: [GlucoseReading] = [
            GlucoseReading(date: now, mgdl: 120, trend: .flat),
        ]
        let deltas = DeltasCompute.compute(readings: readings, units: .mgdl)
        XCTAssertNil(deltas.delta)
        XCTAssertNil(deltas.delta15)
    }
}
