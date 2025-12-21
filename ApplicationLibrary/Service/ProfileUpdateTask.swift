import Foundation
import Library

public enum ProfileUpdateTask {
    static let minUpdateInterval: TimeInterval = 15 * 60
    static let defaultUpdateInterval: TimeInterval = 60 * 60

    private static var timer: Timer?
    private static let logger = AppLog.logger(category: "profile-update-task")

    public static func configure() async throws {
        timer?.invalidate()
        timer = nil
        let profiles = try await ProfileManager.listAutoUpdateEnabled()
        if profiles.isEmpty {
            return
        }
        var updateInterval = profiles.map { it in
            it.autoUpdateIntervalOrDefault
        }.min()!
        if updateInterval < minUpdateInterval {
            updateInterval = minUpdateInterval
        }
        timer = Timer(fire: calculateEarliestBeginDate(profiles), interval: updateInterval, repeats: true) { _ in
            Task {
                await getAndupdateProfiles()
            }
        }
    }

    static func calculateEarliestBeginDate(_ profiles: [Profile]) -> Date {
        let nowTime = Date.now
        var earliestBeginDate = profiles.map { it in
            it.lastUpdated!.addingTimeInterval(it.autoUpdateIntervalOrDefault)
        }.min()!
        if earliestBeginDate <= nowTime {
            earliestBeginDate = nowTime
        }
        return earliestBeginDate
    }

    private nonisolated static func getAndupdateProfiles() async {
        do {
            let profiles = try await ProfileManager.listAutoUpdateEnabled()
            _ = await updateProfiles(profiles)
            logger.info("profile update task succeed")
        } catch {
            logger.error("profile update task failed", fields: ["error": .privateValue(error.localizedDescription)])
        }
    }

    static func updateProfiles(_ profiles: [Profile]) async -> Bool {
        var success = true
        for profile in profiles {
            if profile.lastUpdated! > Date(timeIntervalSinceNow: -profile.autoUpdateIntervalOrDefault) {
                continue
            }
            do {
                try await profile.updateRemoteProfile()
                logger.info("updated profile", fields: ["profile": .privateValue(profile.name)])
            } catch {
                logger.error(
                    "update profile failed",
                    fields: [
                        "profile": .privateValue(profile.name),
                        "error": .privateValue(error.localizedDescription),
                    ]
                )
                success = false
            }
        }
        return success
    }
}

extension Profile {
    var autoUpdateIntervalOrDefault: TimeInterval {
        if autoUpdateInterval > 0 {
            return TimeInterval(autoUpdateInterval * 60)
        } else {
            return ProfileUpdateTask.defaultUpdateInterval
        }
    }
}
