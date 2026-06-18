import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var store: AppStore

    @State private var period = 1
    @State private var loaded: [GlucoseReading] = []
    @State private var loading = false

    private var units: GlucoseUnits { store.displayUnits }

    private var stats: GlucoseStats {
        StatisticsCompute.stats(readings: loaded, thresholds: store.thresholds)
    }

    private var agpData: [HourlyPercentiles] {
        StatisticsCompute.hourlyPercentiles(readings: loaded, units: units)
    }

    private func yVal(_ mgdl: Double) -> Double { units == .mmol ? mgdl / 18.0182 : mgdl }
    private var yDomain: ClosedRange<Double> { units == .mmol ? (40/18.0182)...(300/18.0182) : 40...300 }

    var body: some View {
        List {
            Picker("Period", selection: $period) {
                Text("24h").tag(1)
                Text("7d").tag(7)
                Text("30d").tag(30)
                Text("90d").tag(90)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)

            Section("Glucose") {
                if loading && loaded.isEmpty {
                    ProgressView().frame(maxWidth: .infinity)
                } else if period == 1 {
                    glucoseChart
                } else {
                    agpChart
                }
            }

            Section("Time in Range") {
                tirPieChart
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
        .task(id: period) { await load() }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        store.ensureConfigured()
        if let data = try? await store.client.fetchEntries(sinceDays: period) {
            loaded = data
        }
    }

    private var glucoseChart: some View {
        Chart {
            ForEach(loaded) { r in
                PointMark(x: .value("T", r.date), y: .value("G", yVal(Double(r.mgdl))))
                    .foregroundStyle(color(for: Formatting.classify(mgdl: r.mgdl, thresholds: store.thresholds)))
                    .symbolSize(period == 1 ? 12 : 4)
            }
            RuleMark(y: .value("L", yVal(Double(store.thresholds.low))))
                .foregroundStyle(.green.opacity(0.35)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
            RuleMark(y: .value("H", yVal(Double(store.thresholds.high))))
                .foregroundStyle(.green.opacity(0.35)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 4]))
        }
        .chartYScale(domain: yDomain)
        .frame(height: 200)
    }

    // AGP band colors (match AAPS): outer P10–P90 darker steel blue, inner P25–P75 lighter sky blue.
    private let agpOuter = Color(red: 0.17, green: 0.40, blue: 0.66)
    private let agpInner = Color(red: 0.40, green: 0.67, blue: 0.92)

    private var agpLegend: some View {
        HStack(spacing: 14) {
            Text("10%/90%").foregroundColor(agpOuter)
            Text("25%/75%").foregroundColor(agpInner)
            Text("50% (median)").foregroundColor(.primary)
        }
        .font(.caption.weight(.semibold))
        .frame(maxWidth: .infinity)
    }

    private var agpChart: some View {
        VStack(spacing: 8) {
        agpLegend
        Chart {
            // Outer band (P10–P90): darker steel blue, drawn first (full width).
            ForEach(agpData) { hp in
                AreaMark(
                    x: .value("Hour", hp.hour),
                    yStart: .value("P10", hp.p10),
                    yEnd: .value("P90", hp.p90)
                )
                .foregroundStyle(agpOuter)
                .interpolationMethod(.monotone)
            }
            // Inner band (P25–P75): lighter sky blue, drawn opaque on top of the outer band.
            ForEach(agpData) { hp in
                AreaMark(
                    x: .value("Hour", hp.hour),
                    yStart: .value("P25", hp.p25),
                    yEnd: .value("P75", hp.p75)
                )
                .foregroundStyle(agpInner)
                .interpolationMethod(.monotone)
            }
            // Median
            ForEach(agpData) { hp in
                LineMark(
                    x: .value("Hour", hp.hour),
                    y: .value("P50", hp.p50)
                )
                .foregroundStyle(Color.white)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.monotone)
            }
            // High threshold — yellow
            RuleMark(y: .value("High", yVal(Double(store.thresholds.high))))
                .foregroundStyle(Color.yellow.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            // Low threshold — red
            RuleMark(y: .value("Low", yVal(Double(store.thresholds.low))))
                .foregroundStyle(Color.red.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXScale(domain: 0...23)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: [0, 3, 6, 9, 12, 15, 18, 21, 23]) { value in
                AxisGridLine().foregroundStyle(Color.white.opacity(0.12))
                AxisTick()
                AxisValueLabel {
                    if let h = value.as(Int.self) {
                        Text("\(h)").font(.caption2)
                    }
                }
            }
        }
        .frame(height: 240)
        }
    }

    private var tirPieChart: some View {
        let segments: [(String, Double, Color)] = [
            ("Urg Low", stats.tirBelowUrgent, .red),
            ("Low", stats.tirBelow, .yellow),
            ("In Range", stats.tirInRange, .green),
            ("High", stats.tirAbove, .yellow),
            ("Urg High", stats.tirAboveUrgent, .red),
        ].filter { $0.1 > 0 }

        let total = segments.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return AnyView(EmptyView()) }

        return AnyView(
            GeometryReader { geo in
                let radius = min(geo.size.width, geo.size.height) / 2
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ZStack {
                    ForEach(segments.indices, id: \.self) { i in
                        let startAngle: Double = segments.prefix(i).reduce(0) { $0 + $1.1 } / total * 360
                        let endAngle: Double = startAngle + segments[i].1 / total * 360
                        Path { path in
                            path.move(to: center)
                            path.addArc(center: center, radius: radius,
                                        startAngle: .degrees(startAngle - 90),
                                        endAngle: .degrees(endAngle - 90),
                                        clockwise: false)
                            path.closeSubpath()
                        }
                        .fill(segments[i].2)
                    }
                    Circle().fill(Color(.systemBackground)).frame(width: radius * 0.6, height: radius * 0.6)
                    Text("\(String(format: "%.0f", stats.tirInRange))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .frame(height: 220)
        )
    }

    private func color(for c: GlucoseClassification) -> Color {
        switch c {
        case .urgentLow, .urgentHigh: return .red
        case .low, .high: return .yellow
        case .inRange: return .green
        }
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
