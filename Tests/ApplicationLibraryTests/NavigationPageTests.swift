import NetworkExtension
import XCTest
@testable import ApplicationLibrary
import Library

final class NavigationPageTests: XCTestCase {
    func testPagesForIOSIncludesCommonTabsOnly() {
        let pages = NavigationPage.pages(for: .iOS)
        XCTAssertTrue(pages.contains(.dashboard))
        XCTAssertTrue(pages.contains(.profiles))
        XCTAssertTrue(pages.contains(.settings))
        XCTAssertFalse(pages.contains(.groups))
        XCTAssertFalse(pages.contains(.connections))
    }

    func testPagesForMacOSIncludesDesktopSpecificTabs() {
        let pages = NavigationPage.pages(for: .macOS)
        XCTAssertTrue(pages.contains(.dashboard))
        XCTAssertTrue(pages.contains(.groups))
        XCTAssertTrue(pages.contains(.connections))
    }

    func testMacOSDefaultPagesExcludeDashboardAndProtectedTabs() {
        XCTAssertEqual(NavigationPage.macosDefaultPages, [.logs, .profiles, .settings])
    }

    func testGroupsRequireConnectedProfile() {
        XCTAssertFalse(NavigationPage.groups.visible(nil))

        let profile = ExtensionProfile(NEVPNManager())
        profile.status = .connected

        XCTAssertTrue(NavigationPage.groups.visible(profile))
    }
}
