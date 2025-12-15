import Combine
import Foundation
import Library

@MainActor
public final class AppShellState: ObservableObject {
    public let profiles: ProfileStore
    public let logs: LogStreamStore

    public let openSettings = PassthroughSubject<Void, Never>()
    public let profileUpdate = PassthroughSubject<Void, Never>()
    public let selectedProfileUpdate = PassthroughSubject<Void, Never>()

    @Published public var emptyProfiles = false

    private var cancellables: Set<AnyCancellable> = []

    public init(
        profiles: ProfileStore? = nil,
        logs: LogStreamStore? = nil
    ) {
        NSLog("[AppShellState] init begin")
        let resolvedProfiles = profiles ?? ProfileStore()
        let resolvedLogs = logs ?? LogStreamStore()
        self.profiles = resolvedProfiles
        self.logs = resolvedLogs
        NSLog("[AppShellState] init finished")

        resolvedProfiles.$profile
            .sink { profile in resolvedLogs.handleProfileChange(profile) }
            .store(in: &cancellables)

        profileUpdate
            .sink { [weak self] _ in
                self?.profiles.reload()
            }
            .store(in: &cancellables)

        selectedProfileUpdate
            .sink { [weak self] _ in
                self?.profiles.reload()
            }
            .store(in: &cancellables)
    }

    public func refreshProfile() {
        NSLog("[AppShellState] refreshProfile() invoked")
        profiles.reload()
    }

    public func clearProfileError() {
        profiles.clearError()
    }
}
