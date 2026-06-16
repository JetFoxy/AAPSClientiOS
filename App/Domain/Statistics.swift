import Foundation

struct GlucoseStats: Equatable {
    let count: Int
    let averageMgdl: Double
    let gmiPercent: Double
    let cvPercent: Double
    let sdMgdl: Double
    let tirBelowUrgent: Double
    let tirBelow: Double
    let tirInRange: Double
    let tirAbove: Double
    let tirAboveUrgent: Double
}

enum StatisticsCompute {
    static func stats(readings: [GlucoseReading], thresholds: AlarmThresholds) -> GlucoseStats {
        let values = readings.map { Double($0.mgdl) }
        let count = values.count
        guard count > 1 else {
            return GlucoseStats(
                count: count, averageMgdl: values.first ?? 0, gmiPercent: 0, cvPercent: 0,
                sdMgdl: 0, tirBelowUrgent: 0, tirBelow: 0, tirInRange: 0, tirAbove: 0, tirAboveUrgent: 0
            )
        }
        let mean = values.reduce(0, +) / Double(count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(count - 1)
        let sd = sqrt(variance)
        let cv = sd / mean * 100
        let gmi = 3.31 + 0.02392 * mean

        func pct(_ cond: (Int) -> Bool) -> Double {
            Double(readings.filter { cond($0.mgdl) }.count) / Double(count) * 100
        }

        return GlucoseStats(
            count: count,
            averageMgdl: mean,
            gmiPercent: gmi,
            cvPercent: cv,
            sdMgdl: sd,
            tirBelowUrgent: pct { $0 < thresholds.urgentLow },
            tirBelow: pct { $0 >= thresholds.urgentLow && $0 < thresholds.low },
            tirInRange: pct { $0 >= thresholds.low && $0 <= thresholds.high },
            tirAbove: pct { $0 > thresholds.high && $0 < thresholds.urgentHigh },
            tirAboveUrgent: pct { $0 >= thresholds.urgentHigh }
        )
    }
}
