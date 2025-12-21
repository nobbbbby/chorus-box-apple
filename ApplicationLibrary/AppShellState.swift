import Combine
import Foundation
import Library

@MainActor
public final class AppShellState: ObservableObject {
    public let profiles: ProfileStore

    public let openSettings = PassthroughSubject<Void, Never>()
    public let profileUpdate = PassthroughSubject<Void, Never>()
    public let selectedProfileUpdate = PassthroughSubject<Void, Never>()

    @Published public var emptyProfiles = false
    private let logger = AppLog.logger(category: "app-shell")

    private var cancellables: Set<AnyCancellable> = []

    public init(
        profiles: ProfileStore? = nil
    ) {
        logger.info("init begin")
        let resolvedProfiles = profiles ?? ProfileStore()
        self.profiles = resolvedProfiles
        logger.info("init finished")

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
        logger.info("refreshProfile invoked")
        profiles.reload()
    }

    public func clearProfileError() {
        profiles.clearError()
    }
}
