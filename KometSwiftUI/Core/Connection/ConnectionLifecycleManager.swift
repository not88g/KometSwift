// Observes UIApplication lifecycle and connects/disconnects accordingly.
// Mirrors connection_lifecycle_manager.dart.

import UIKit
import Combine

final class ConnectionLifecycleManager {
    static let shared = ConnectionLifecycleManager()

    private var cancellables = Set<AnyCancellable>()

    func start() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in Task { await ConnectionManager.shared.connect() } }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                // Keep connection alive in background for a while; actual teardown
                // happens via BGTaskScheduler if the OS terminates the process.
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { _ in Task { await ConnectionManager.shared.disconnect() } }
            .store(in: &cancellables)
    }
}
