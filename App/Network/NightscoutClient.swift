import Foundation

protocol NightscoutClient {
    func authorize() async throws
    func fetchEntries(limit: Int) async throws -> [GlucoseReading]
    func fetchTreatments(since: Date?) async throws -> [Treatment]
    func fetchDeviceStatus() async throws -> LoopStatus?
    func fetchProfile() async throws -> NsProfile
    func fetchProfileStore() async throws -> NsProfileStore
    func postTreatment(_ payload: [String: Any]) async throws
    /// Latest care-portal events (site/sensor/insulin/battery) — these are infrequent and fall
    /// outside the general treatments window, so they need a dedicated eventType-filtered query.
    func fetchCareEvents() async throws -> [Treatment]
}

extension NightscoutClient {
    // Default keeps existing conformers (mocks) compiling; live client overrides.
    func fetchCareEvents() async throws -> [Treatment] { try await fetchTreatments(since: nil) }
}
