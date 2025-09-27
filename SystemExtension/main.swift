import Foundation
import Library
import NetworkExtension

ChorusBoxConfiguration.configure(
    ChorusBoxConfiguration(
        platform: .systemExtension,
        applicationName: "SFM",
        usesSystemExtension: true,
        isBeta: false
    )
)

autoreleasepool {
    NEProvider.startSystemExtensionMode()
}

dispatchMain()
