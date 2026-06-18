import SwiftUI
import Charts

struct ProfileView: View {
    @ObservedObject var store: AppStore
    let writer: NsTreatmentWriter
    @State private var selectedName: String?
    @State private var switchPct = "100"
    @State private var switchDur = "0"

    private var units: GlucoseUnits { store.displayUnits }

    var body: some View {
        List {
            if let ps = store.profileStore {
                Section("Profiles") {
                    ForEach(ps.profileNames, id: \.self) { name in
                        profileCard(name, isActive: isActive(name))
                            .onTapGesture {
                                selectedName = name
                            }
                    }
                }
                if let active = store.activeProfileSwitch?.profileName,
                   let prof = store.profile {
                    Section("Active: \(active)") {
                        basalChart(prof)
                        targetChart(prof)
                        isfChart(prof)
                        icrChart(prof)
                    }
                }
            } else {
                Text("No profile loaded")
            }
        }
        .navigationTitle("Profile")
        .sheet(item: Binding(
            get: { selectedName.map { ProfileSelection(name: $0) } },
            set: { selectedName = $0?.name }
        )) { sel in
            profileSwitchSheet(for: sel.name)
        }
    }

    private func isActive(_ name: String) -> Bool {
        store.activeProfileSwitch?.profileName == name
    }

    private func profileSwitchSheet(for name: String) -> some View {
        NavigationStack {
            Form {
                TextField("Percentage (30-250)", text: $switchPct).keyboardType(.numberPad)
                TextField("Duration (0=permanent)", text: $switchDur).keyboardType(.numberPad)
            }
            .navigationTitle("Switch to \(name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { selectedName = nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Switch") {
                        switchTo(name)
                        selectedName = nil
                    }
                }
            }
        }
    }

    private func switchTo(_ name: String) {
        guard let pct = Int(switchPct), (30...250).contains(pct),
              let dur = Int(switchDur), dur >= 0 else { return }
        let json = store.profileStore?.rawJson[name]
        Task {
            do {
                try await writer.switchProfile(name: name, percentage: pct, durationMin: dur, profileJson: json)
                try? await store.refresh()
            } catch { }
        }
    }

    private func profileCard(_ name: String, isActive: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                if let pct = store.activeProfileSwitch?.percentage, isActive, pct != 100 {
                    Text("\(pct)%").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            if isActive {
                Text("Active").font(.caption).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.green.opacity(0.2)).cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }

    private struct ProfileSelection: Identifiable {
        let name: String
        var id: String { name }
    }

    // Charts (from R9.3)
    private func basalChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.basal.indices, id: \.self) { i in
                let b = p.basal[i]; let next = i + 1 < p.basal.count ? p.basal[i + 1].startSeconds : 86400
                RectangleMark(xStart: .value("S", secondsToHour(b.startSeconds)), xEnd: .value("E", secondsToHour(next)),
                              yStart: .value("R", 0), yEnd: .value("R", b.rate))
                .foregroundStyle(.blue.opacity(0.3))
            }
        }
        .chartYAxisLabel("U/h").chartXScale(domain: 0...24).frame(height: 100)
    }

    private func targetChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.basal.indices, id: \.self) { i in
                let s = secondsToHour(p.basal[i].startSeconds)
                let e = i + 1 < p.basal.count ? secondsToHour(p.basal[i + 1].startSeconds) : 24
                let lo = profileValue(blocks: p.targetLow, atSeconds: p.basal[i].startSeconds).map { yVal(Double($0)) } ?? 0
                let hi = profileValue(blocks: p.targetHigh, atSeconds: p.basal[i].startSeconds).map { yVal(Double($0)) } ?? 0
                RectangleMark(xStart: .value("S", s), xEnd: .value("E", e), yStart: .value("L", lo), yEnd: .value("H", hi))
                    .foregroundStyle(.green.opacity(0.3))
            }
        }
        .chartXScale(domain: 0...24).frame(height: 100)
    }

    private func isfChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.sensitivity.indices, id: \.self) { i in
                let s = p.sensitivity[i]; let next = i + 1 < p.sensitivity.count ? p.sensitivity[i + 1].startSeconds : 86400
                RectangleMark(xStart: .value("S", secondsToHour(s.startSeconds)), xEnd: .value("E", secondsToHour(next)),
                              yStart: .value("R", 0), yEnd: .value("R", yVal(Double(s.value))))
                .foregroundStyle(.orange.opacity(0.3))
            }
        }
        .chartXScale(domain: 0...24).frame(height: 80)
    }

    private func icrChart(_ p: NsProfile) -> some View {
        Chart {
            ForEach(p.carbRatio.indices, id: \.self) { i in
                let c = p.carbRatio[i]; let next = i + 1 < p.carbRatio.count ? p.carbRatio[i + 1].startSeconds : 86400
                RectangleMark(xStart: .value("S", secondsToHour(c.startSeconds)), xEnd: .value("E", secondsToHour(next)),
                              yStart: .value("R", 0), yEnd: .value("R", yVal(Double(c.value))))
                .foregroundStyle(.purple.opacity(0.3))
            }
        }
        .chartXScale(domain: 0...24).frame(height: 80)
    }

    private func secondsToHour(_ secs: Int) -> Double { Double(secs) / 3600 }
    private func yVal(_ mgdl: Double) -> Double { units == .mmol ? mgdl / 18.0182 : mgdl }
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
