import Foundation
import Libbox

public enum Variant {
    private static var fallbackConfiguration: ChorusBoxConfiguration {
        let defaultName = "Chorus Box"
        let beta = LibboxVersion().contains("-")
        #if os(macOS)
            return ChorusBoxConfiguration(
                platform: .macOS,
                applicationName: defaultName,
                usesSystemExtension: false,
                isBeta: beta
            )
        #elseif os(tvOS)
            return ChorusBoxConfiguration(
                platform: .tvOS,
                applicationName: defaultName,
                usesSystemExtension: false,
                isBeta: beta
            )
        #else
            return ChorusBoxConfiguration(
                platform: .iOS,
                applicationName: defaultName,
                usesSystemExtension: false,
                isBeta: beta
            )
        #endif
    }

    private static var configuration: ChorusBoxConfiguration {
        if ChorusBoxConfiguration.isConfigured {
            return ChorusBoxConfiguration.current
        }
        return fallbackConfiguration
    }

    public static var platform: ChorusBoxConfiguration.Platform {
        configuration.platform
    }

    public static var applicationName: String {
        configuration.applicationName
    }

    public static var useSystemExtension: Bool {
        configuration.usesSystemExtension
    }

    public static var isBeta: Bool {
        configuration.isBeta
    }
}
