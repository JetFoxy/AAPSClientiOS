import SwiftUI

struct ActionsView: View {
    @ObservedObject var store: AppStore
    let writer: NsTreatmentWriter

    @State private var carbsGrams: String = ""
    @State private var targetMgdl: String = "100"
    @State private var targetDuration: String = "60"
    @State private var targetReason: TtReason = .eatingSoon
    @State private var confirmAction: ConfirmAction?
    @State private var statusMessage: String?

    enum ConfirmAction {
        case carbs(Double)
        case tempTarget(Int, Int, TtReason)
        case cancelTarget
    }

    var body: some View {
        Form {
            Section("Carbs") {
                TextField("Grams", text: $carbsGrams)
                    .keyboardType(.decimalPad)
                Button("Send Carbs") {
                    guard let grams = Double(carbsGrams), grams > 0 else { return }
                    confirmAction = .carbs(grams)
                }
                .disabled(carbsGrams.isEmpty)
            }

            Section("Temporary Target") {
                TextField("Target (mg/dl)", text: $targetMgdl)
                    .keyboardType(.numberPad)
                TextField("Duration (min)", text: $targetDuration)
                    .keyboardType(.numberPad)
                Picker("Reason", selection: $targetReason) {
                    Text("Eating Soon").tag(TtReason.eatingSoon)
                    Text("Activity").tag(TtReason.activity)
                    Text("Hypo").tag(TtReason.hypo)
                    Text("Custom").tag(TtReason.custom)
                }
                Button("Set Target") {
                    guard let mgdl = Int(targetMgdl),
                          let dur = Int(targetDuration),
                          mgdl > 0, dur > 0 else { return }
                    confirmAction = .tempTarget(mgdl, dur, targetReason)
                }
                Button("Cancel Target", role: .destructive) {
                    confirmAction = .cancelTarget
                }
            }

            if let msg = statusMessage {
                Section {
                    Text(msg)
                        .foregroundColor(msg.hasPrefix("Error") ? .red : .green)
                }
            }
        }
        .navigationTitle("Actions")
        .alert("Confirm", isPresented: Binding(
            get: { confirmAction != nil },
            set: { if !$0 { confirmAction = nil } }
        )) {
            if case .cancelTarget = confirmAction {
                Button("Cancel Target", role: .destructive) { executeConfirmed() }
            } else {
                Button("Send") { executeConfirmed() }
            }
            Button("Cancel", role: .cancel) {
                confirmAction = nil
            }
        } message: {
            Text(confirmationMessage)
        }
    }

    private var confirmationMessage: String {
        switch confirmAction {
        case .carbs(let g): return "Send \(g)g carbs to Nightscout?"
        case .tempTarget(let mgdl, let min, let r): return "Set target \(mgdl) mg/dl for \(min) min (\(r.rawValue))?"
        case .cancelTarget: return "Cancel current temporary target?"
        case nil: return ""
        }
    }

    private func executeConfirmed() {
        guard let action = confirmAction else { return }
        confirmAction = nil
        Task {
            do {
                switch action {
                case .carbs(let grams):
                    try await writer.sendCarbs(grams: grams, at: Date())
                    statusMessage = "Carbs sent"
                case .tempTarget(let mgdl, let dur, let reason):
                    try await writer.sendTempTarget(targetMgdl: mgdl, durationMin: dur, reason: reason)
                    statusMessage = "Target set"
                case .cancelTarget:
                    try await writer.cancelTempTarget()
                    statusMessage = "Target cancelled"
                }
                try? await store.refresh()
            } catch {
                statusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
}
