import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct AAPSClientApp: App {
    @StateObject private var store: AppStore
    private let writer: NsTreatmentWriter
    private let bgScheduler: BackgroundScheduler

    init() {
        let keychain = KeychainStore(service: "org.diy.aapsclient")
        let nsUrl = ((try? keychain.get(.nsUrl)) ?? nil).flatMap(AppStore.normalizedURL)
        let accessToken = (try? keychain.get(.nsAccessToken)) ?? ""

        let client: NightscoutClient
        if let url = nsUrl, !accessToken.isEmpty {
            client = NightscoutClientLive(baseURL: url, accessToken: accessToken, transport: URLSessionTransport())
        } else {
            client = UnconfiguredClient()
        }

        let alarmEngine = AlarmEngineLive(notifier: UNNotifier())
        let store = AppStore(client: client, alarmEngine: alarmEngine)
        _store = StateObject(wrappedValue: store)
        writer = NsTreatmentWriterLive(client: client)
        bgScheduler = BackgroundScheduler(store: store)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    HomeView(store: store, writer: writer)
                }
                .tabItem { Label("tab.home", systemImage: "house") }

                NavigationStack {
                    HistoryView(store: store)
                }
                .tabItem { Label("tab.history", systemImage: "clock") }

                NavigationStack {
                    SettingsView(store: store)
                }
                .tabItem { Label("tab.settings", systemImage: "gear") }

                NavigationStack {
                    StatisticsView(store: store)
                }
                .tabItem { Label("Statistics", systemImage: "chart.bar") }
            }
            .task {
                bgScheduler.register()
                bgScheduler.schedule()
                try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                // Initial data refresh is owned by HomeView (.task) so errors surface there.
            }
        }
    }
}

final class UnconfiguredClient: NightscoutClient {
    func authorize() async throws { throw NsError.badURL }
    func fetchEntries(limit: Int) async throws -> [GlucoseReading] { throw NsError.badURL }
    func fetchTreatments(since: Date?) async throws -> [Treatment] { throw NsError.badURL }
    func fetchDeviceStatus() async throws -> LoopStatus? { throw NsError.badURL }
    func fetchProfile() async throws -> NsProfile { throw NsError.badURL }
    func fetchProfileStore() async throws -> NsProfileStore { throw NsError.badURL }
    func postTreatment(_ payload: [String: Any]) async throws { throw NsError.badURL }
}

final class URLSessionTransport: HttpTransport {
    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NsError.noNetwork
        }
        return (data, httpResponse)
    }
}
