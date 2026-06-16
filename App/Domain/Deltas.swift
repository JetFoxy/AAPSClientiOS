import Foundation

struct Deltas: Equatable {
    let delta: Int?
    let delta15: Int?
    let delta40: Int?
}

enum DeltasCompute {
    static func compute(readings: [GlucoseReading], units: GlucoseUnits) -> Deltas {
        let sorted = readings.sorted(by: { $0.date > $1.date })
        guard let latest = sorted.first else { return Deltas(delta: nil, delta15: nil, delta40: nil) }

        func deltaAt(secondsAgo: TimeInterval) -> Int? {
            let targetDate = latest.date.addingTimeInterval(-secondsAgo)
            guard let nearest = sorted.min(by: { abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate)) }),
                  abs(nearest.date.timeIntervalSince(targetDate)) < 300 else { return nil }
            let raw = latest.mgdl - nearest.mgdl
            return units == .mmol ? Int((Double(raw) / 18.0182).rounded()) : raw
        }

        return Deltas(
            delta: deltaAt(secondsAgo: 5 * 60),
            delta15: deltaAt(secondsAgo: 15 * 60),
            delta40: deltaAt(secondsAgo: 40 * 60)
        )
    }
}
