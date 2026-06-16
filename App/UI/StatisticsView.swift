import SwiftUI

struct StatisticsView: View {
    @ObservedObject var store: AppStore

    @State private var period = 1

    private var readings: [GlucoseReading] {
        let cutoff = Date().addingTimeInterval(-Double(period) * 86400)
        return store.readings.filter { $0.date > cutoff }
    }

    private var stats: GlucoseStats {
        StatisticsCompute.stats(readings: readings, thresholds: store.thresholds)
    }

    private var units: GlucoseUnits { store.displayUnits }

    var body: some View {
        List {
            Picker("Period", selection: $period) {
                Text("24h").tag(1)
                Text("7d").tag(7)
                Text("30d").tag(30)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            Section("Time in Range") {
                tirBar
                HStack {
                    tirPill("Urg Low", stats.tirBelowUrgent, .red)
                    tirPill("Low", stats.tirBelow, .yellow)
                    tirPill("In Range", stats.tirInRange, .green)
                    tirPill("High", stats.tirAbove, .yellow)
                    tirPill("Urg High", stats.tirAboveUrgent, .red)
                }
                .font(.caption2)
            }

            Section("Metrics") {
                metricRow("Readings", "\(stats.count)")
                metricRow("Mean", Formatting.format(Int(stats.averageMgdl.rounded()), units: units))
                metricRow("GMI (eA1c)", String(format: "%.1f%%", stats.gmiPercent))
                metricRow("CV", String(format: "%.1f%%", stats.cvPercent))
                metricRow("SD", Formatting.format(Int(stats.sdMgdl.rounded()), units: units))
            }
        }
        .navigationTitle("Statistics")
    }

    private var tirBar: some View {
        let total = stats.tirBelowUrgent + stats.tirBelow + stats.tirInRange + stats.tirAbove + stats.tirAboveUrgent
        guard total > 0 else { return AnyView(EmptyView()) }
        return AnyView(
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(.red).frame(width: geo.size.width * stats.tirBelowUrgent / 100)
                    Rectangle().fill(.yellow).frame(width: geo.size.width * stats.tirBelow / 100)
                    Rectangle().fill(.green).frame(width: geo.size.width * stats.tirInRange / 100)
                    Rectangle().fill(.yellow).frame(width: geo.size.width * stats.tirAbove / 100)
                    Rectangle().fill(.red).frame(width: geo.size.width * stats.tirAboveUrgent / 100)
                }
                .cornerRadius(4)
            }
            .frame(height: 16)
        )
    }

    private func tirPill(_ label: String, _ pct: Double, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(label): \(String(format: "%.0f", pct))%")
        }
    }

    private func metricRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}
