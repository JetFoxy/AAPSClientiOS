import SwiftUI
import Charts

struct ProfileView: View {
    @ObservedObject var store: AppStore

    private var units: GlucoseUnits { store.displayUnits }
    private var profile: NsProfile? { store.profile }

    var body: some View {
        List {
            if let p = profile {
                Section("Basal (U/h)") {
                    basalChart(p)
                }
                Section("Target") {
                    targetChart(p)
                }
                Section("ISF (mg/dl per U)") {
                    isfChart(p)
                }
                Section("ICR (g per U)") {
                    icrChart(p)
                }
            } else {
                Text("No profile loaded")
            }
        }
        .navigationTitle("Profile")
    }

    private func basalChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.basal.indices, id: \.self) { i in
                let b = p.basal[i]
                let nextSecs = i + 1 < p.basal.count ? p.basal[i + 1].startSeconds : 86400
                RectangleMark(
                    xStart: .value("S", secondsToHour(b.startSeconds)),
                    xEnd: .value("E", secondsToHour(nextSecs)),
                    yStart: .value("R", 0),
                    yEnd: .value("R", b.rate)
                )
                .foregroundStyle(.blue.opacity(0.3))
            }
        }
        .chartYAxisLabel("U/h")
        .chartXScale(domain: 0...24)
        .frame(height: 120)
    }

    private func targetChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.basal.indices, id: \.self) { i in
                let startHour = secondsToHour(p.basal[i].startSeconds)
                let endHour = i + 1 < p.basal.count ? secondsToHour(p.basal[i + 1].startSeconds) : 24
                let lowVal = profileValue(blocks: p.targetLow, atSeconds: p.basal[i].startSeconds).map { yVal(Double($0)) } ?? 0
                let highVal = profileValue(blocks: p.targetHigh, atSeconds: p.basal[i].startSeconds).map { yVal(Double($0)) } ?? 0
                RectangleMark(
                    xStart: .value("S", startHour),
                    xEnd: .value("E", endHour),
                    yStart: .value("L", yVal(Double(lowVal))),
                    yEnd: .value("H", yVal(Double(highVal)))
                )
                .foregroundStyle(.green.opacity(0.3))
            }
        }
        .chartYAxisLabel(units == .mmol ? "mmol/l" : "mg/dl")
        .chartXScale(domain: 0...24)
        .frame(height: 120)
    }

    private func isfChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.sensitivity.indices, id: \.self) { i in
                let s = p.sensitivity[i]
                let nextSecs = i + 1 < p.sensitivity.count ? p.sensitivity[i + 1].startSeconds : 86400
                RectangleMark(
                    xStart: .value("S", secondsToHour(s.startSeconds)),
                    xEnd: .value("E", secondsToHour(nextSecs)),
                    yStart: .value("R", 0),
                    yEnd: .value("R", yVal(Double(s.value)))
                )
                .foregroundStyle(.orange.opacity(0.3))
            }
        }
        .chartXScale(domain: 0...24)
        .frame(height: 100)
    }

    private func icrChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.carbRatio.indices, id: \.self) { i in
                let c = p.carbRatio[i]
                let nextSecs = i + 1 < p.carbRatio.count ? p.carbRatio[i + 1].startSeconds : 86400
                RectangleMark(
                    xStart: .value("S", secondsToHour(c.startSeconds)),
                    xEnd: .value("E", secondsToHour(nextSecs)),
                    yStart: .value("R", 0),
                    yEnd: .value("R", yVal(Double(c.value)))
                )
                .foregroundStyle(.purple.opacity(0.3))
            }
        }
        .chartXScale(domain: 0...24)
        .frame(height: 100)
    }

    private func secondsToHour(_ secs: Int) -> Double {
        Double(secs) / 3600
    }

    private func yVal(_ mgdl: Double) -> Double {
        units == .mmol ? mgdl / 18.0182 : mgdl
    }
}

func profileValue(blocks: [ScheduledValue], atSeconds secs: Int) -> Int? {
    var best: ScheduledValue?
    for b in blocks {
        if b.startSeconds <= secs {
            if best == nil || b.startSeconds > best!.startSeconds { best = b }
        }
    }
    return best.map { Int($0.value) }
}
