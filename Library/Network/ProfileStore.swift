import Combine
import Foundation
import OSLog

@MainActor
public final class ProfileStore: ObservableObject {
    @Published public private(set) var profile: ExtensionProfile?
    @Published public private(set) var isLoading = true
    @Published public private(set) var isEmpty = false
    @Published public private(set) var error: Error?

    private var reloadTask: Task<Void, Never>?
    private let loader: () async throws -> ExtensionProfile?
    private let logger = AppLog.logger(category: "profile-store")

    public init(loader: @escaping () async throws -> ExtensionProfile? = { try await ExtensionProfile.load() }) {
        self.loader = loader
    }

    deinit {
        reloadTask?.cancel()
    }

    public func reload() {
        logger.info("reload requested")
        reloadTask?.cancel()
        reloadTask = Task { await loadProfile() }
    }

    public func loadProfile() async {
        logger.info("loadProfile start")
        isLoading = true
        error = nil
        do {
            let loadedProfile = try await withTimeout(seconds: 10) { [self] in
                try await loader()
            }
            isLoading = false
            isEmpty = loadedProfile == nil
            guard let loadedProfile else {
                if profile != nil {
                    profile = nil
                }
                logger.warn("loadProfile completed: nil profile")
                return
            }
            if profile !== loadedProfile {
                loadedProfile.register()
                profile = loadedProfile
                logger.info("loadProfile completed: new profile loaded")
            } else {
                profile?.objectWillChange.send()
                logger.info("loadProfile completed: profile refreshed")
            }
        } catch ProfileLoadError.timeout {
            isLoading = false
            self.error = ProfileLoadError.timeout
            isEmpty = true
            profile = nil
            logger.warn("loadProfile timed out")
        } catch is CancellationError {
            isLoading = false
            self.error = ProfileLoadError.cancelled
            isEmpty = true
            profile = nil
            logger.warn("loadProfile cancelled")
        } catch {
            isLoading = false
            self.error = error
            isEmpty = true
            profile = nil
            logger.error("loadProfile error", fields: ["error": .privateValue(error.localizedDescription)])
        }
    }

    public func clearError() {
        error = nil
    }
}

enum ProfileLoadError: LocalizedError {
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Setup needed: install the network extension and create/import a profile in Profiles, then try again."
        case .cancelled:
            return "Profile loading was cancelled. Install the network extension and create/import a profile in Profiles, then try again."
        }
    }
}

private extension ProfileStore {
    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw ProfileLoadError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
