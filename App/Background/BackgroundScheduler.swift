import BackgroundTasks
import Foundation

final class BackgroundScheduler {
    static let refreshTaskId = "com.nightaps.aapsclientios.refresh"

    private let store: AppStore

    init(store: AppStore) {
        self.store = store
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskId, using: nil) { task in
            self.handleRefresh(task as! BGAppRefreshTask)
        }
    }

    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("bg: failed to schedule refresh: \(error)")
        }
    }

    private func handleRefresh(_ task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        Task {
            do {
                try await store.refresh()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
            schedule()
        }
    }
}
