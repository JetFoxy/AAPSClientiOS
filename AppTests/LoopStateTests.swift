import XCTest
@testable import AAPSClientiOS

final class LoopStateTests: XCTestCase {

    func test_loopingUnder7min() {
        let now = Date()
        let t = now.addingTimeInterval(-6.9 * 60)
        XCTAssertEqual(LoopStateCalc.from(statusTimestamp: t, now: now), .looping)
    }

    func test_warning7to14min() {
        let now = Date()
        let t = now.addingTimeInterval(-10 * 60)
        XCTAssertEqual(LoopStateCalc.from(statusTimestamp: t, now: now), .warning)
    }

    func test_stale15minPlus() {
        let now = Date()
        let t = now.addingTimeInterval(-16 * 60)
        XCTAssertEqual(LoopStateCalc.from(statusTimestamp: t, now: now), .stale)
    }

    func test_boundary7min() {
        let now = Date()
        let t = now.addingTimeInterval(-7 * 60)
        XCTAssertEqual(LoopStateCalc.from(statusTimestamp: t, now: now), .warning)
    }

    func test_boundary15min() {
        let now = Date()
        let t = now.addingTimeInterval(-15 * 60)
        XCTAssertEqual(LoopStateCalc.from(statusTimestamp: t, now: now), .stale)
    }

    func test_nilTimestamp() {
        XCTAssertEqual(LoopStateCalc.from(statusTimestamp: nil, now: Date()), .unknown)
    }
}
