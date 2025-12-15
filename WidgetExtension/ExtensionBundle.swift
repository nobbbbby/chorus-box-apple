import Libbox
import Library
import SwiftUI
import WidgetKit
import ApplicationLibrary

@main
struct ExtensionBundle: WidgetBundle {
    private static let runtime = AppRuntime(
        configuration: {
            #if os(macOS)
                return ChorusBoxConfiguration(
                    platform: .macOS,
                    applicationName: "SFM",
                    usesSystemExtension: false,
                    isBeta: LibboxVersion().contains("-")
                )
            #elseif os(tvOS)
                return ChorusBoxConfiguration(
                    platform: .tvOS,
                    applicationName: "SFT",
                    usesSystemExtension: false,
                    isBeta: LibboxVersion().contains("-")
                )
            #else
                return ChorusBoxConfiguration(
                    platform: .iOS,
                    applicationName: "SFI",
                    usesSystemExtension: false,
                    isBeta: LibboxVersion().contains("-")
                )
            #endif
        }
    )

    init() {
        NavigationFeatureMetadataProvider.preload(for: NavigationPlatform.current)
        Self.runtime.start()
    }

    var body: some Widget {
        ServiceToggleControl()
    }
}
