import Foundation
import Library
import NetworkExtension

AppRuntime(
    configuration: {
        ChorusBoxConfiguration(
            platform: .systemExtension,
            applicationName: "SFM",
            usesSystemExtension: true,
            isBeta: false
        )
    },
    options: .init(configurationMode: .configure)
)
.start()

autoreleasepool {
    NEProvider.startSystemExtensionMode()
}

dispatchMain()
