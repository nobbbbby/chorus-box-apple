import XCTest
@testable import ApplicationLibrary

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
    }
}
