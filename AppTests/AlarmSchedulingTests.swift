import XCTest
@testable import AAPSClientiOS

final class MockNotifier: Notifier {
    var posted: [(title: String, body: String, identifier: String)] = []
    var removed: [String] = []

    func post(title: String, body: String, identifier: String) {
        posted.append((title, body, identifier))
    }

    func remove(identifier: String) {
        removed.append(identifier)
    }
}

final class AlarmSchedulingTests: XCTestCase {

    func test_schedulePostsNotification() {
        let notifier = MockNotifier()
        let engine = AlarmEngineLive(notifier: notifier)

        engine.schedule(.low)

        XCTAssertEqual(notifier.posted.count, 1)
        XCTAssertEqual(notifier.posted[0].title, "Low Glucose")
        XCTAssertEqual(notifier.posted[0].identifier, "alarm.low")
    }

    func test_snoozeRemovesNotification() {
        let notifier = MockNotifier()
        let engine = AlarmEngineLive(notifier: notifier)

        engine.snooze(.high, until: Date().addingTimeInterval(600))

        XCTAssertEqual(notifier.removed, ["alarm.high"])
    }

    func test_scheduleDifferentTypes() {
        let notifier = MockNotifier()
        let engine = AlarmEngineLive(notifier: notifier)

        engine.schedule(.urgentLow)
        engine.schedule(.connectionLost)

        XCTAssertEqual(notifier.posted.count, 2)
        XCTAssertEqual(notifier.posted[0].identifier, "alarm.urgentLow")
        XCTAssertEqual(notifier.posted[1].identifier, "alarm.connectionLost")
    }
}
