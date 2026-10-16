import XCTest
import StoreKitTest

/// Opt-in native screenshots; data are seeded into an isolated debug archive by
/// the host, never embedded in or activated by the distribution app.
final class SuiteStoreScreenshots: XCTestCase {
    @MainActor private var app: XCUIApplication!
    @MainActor private func tab(_ label: String) -> XCUIElement {
        let phone = app.tabBars.buttons[label]
        return phone.exists ? phone : app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }
    @MainActor private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "store-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor private func reach(_ element: XCUIElement) {
        for _ in 0..<9 { if element.isHittable { return }; app.swipeUp() }
        XCTFail("Native screenshot control is unreachable: \(element)")
    }
    @MainActor func testCaptureGerman() throws { try capture(language: "de") }
    @MainActor func testCaptureEnglish() throws { try capture(language: "en") }
    @MainActor private func capture(language: String) throws {
        guard ProcessInfo.processInfo.environment["SHK_STORE_CAPTURE"] == "1" else { throw XCTSkip("Opt-in store capture only") }
        continueAfterFailure = false
        let configuration = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "SHKWerkstatt", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: configuration)
        session.resetToDefaultState(); session.clearTransactions(); session.disableDialogs = true
        defer { session.clearTransactions() }
        XCUIDevice.shared.orientation = .portrait
        let de = language == "de"
        app = XCUIApplication()
        app.launchArguments = ["--uitest-id", "store-" + language, "-AppleLanguages", "(\(language))", "-AppleLocale", de ? "de_DE" : "en_GB", "-suite-language", "system", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"]
        app.launch()
        let card = app.buttons["project-card-" + (de ? "Haus Lindenweg" : "Linden House")]
        XCTAssertTrue(card.waitForExistence(timeout: 10), "The actual example archive must be loaded before screenshots")
        shot(language + "-01-projects")
        card.tap()
        XCTAssertTrue(app.buttons["module-heat"].waitForExistence(timeout: 5))
        shot(language + "-02-connected-project")
        for (index, module) in ["heat", "pipe", "volume", "air", "cold", "service"].enumerated() {
            let link = app.buttons["module-" + module]; reach(link); link.tap()
            let back = app.navigationBars.buttons[de ? "Haus Lindenweg" : "Linden House"]
            XCTAssertTrue(back.waitForExistence(timeout: 4))
            if module == "heat" || module == "pipe" { app.swipeUp() }
            shot(language + "-\(index + 3)-" + module)
            back.tap()
        }
        let report = app.buttons["report-open"]; reach(report); report.tap()
        XCTAssertTrue(app.buttons["report-share-text"].waitForExistence(timeout: 5))
        shot(language + "-09-report")
        app.buttons[de ? "Fertig" : "Done"].tap()
        tab("Pro").tap()
        XCTAssertTrue(app.buttons["store-restore"].waitForExistence(timeout: 4))
        reach(app.buttons["store-purchase"])
        shot(language + "-10-pro-review")
        tab(de ? "Rechner" : "Calculators").tap()
        XCTAssertTrue(app.buttons["calculator-heat"].waitForExistence(timeout: 4))
        shot(language + "-11-workshop-tools")
        tab(de ? "Projekte" : "Projects").tap()
        let projectBack = app.navigationBars.buttons[de ? "Projekte" : "Projects"]
        if projectBack.exists { projectBack.tap() }
        let settings = app.buttons[de ? "Einstellungen" : "Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 4)); settings.tap()
        XCTAssertTrue(app.buttons[de ? "Fertig" : "Done"].waitForExistence(timeout: 4))
        shot(language + "-12-workshop-settings")
        app.buttons[de ? "Fertig" : "Done"].tap()
        XCTAssertTrue(app.buttons["project-new"].waitForExistence(timeout: 4))
        tab("Pro").tap()
        let purchase = app.buttons["store-purchase"]
        XCTAssertTrue(purchase.waitForExistence(timeout: 4)); XCTAssertTrue(purchase.isEnabled)
        purchase.tap()
        XCTAssertTrue(app.staticTexts[de ? "Pro ist freigeschaltet" : "Pro is unlocked"].waitForExistence(timeout: 8), "The custom copper button must perform the actual local StoreKit purchase")
    }
}
