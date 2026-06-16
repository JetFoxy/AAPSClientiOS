import Foundation

enum LoopState {
    case looping, warning, stale, unknown
}

enum LoopStateCalc {
    static func from(statusTimestamp: Date?, now: Date) -> LoopState {
        guard let t = statusTimestamp else { return .unknown }
        let age = now.timeIntervalSince(t) / 60
        if age < 7 { return .looping }
        if age < 15 { return .warning }
        return .stale
    }
}
