import XCTest

final class SuiteWorkflowUITests: XCTestCase {
    @MainActor private var app: XCUIApplication!
    @MainActor private func launchFreshApplication(language: String = "de", extra: [String] = []) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["--uitest-id", "suite-ui-" + UUID().uuidString, "-AppleLanguages", "(\(language))", "-AppleLocale", language == "de" ? "de_DE" : "en_GB", "-suite-language", "system", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"] + extra
        app.launch()
    }
    @MainActor private func tab(_ title: String) -> XCUIElement {
        // iPadOS renders native TabView as a top strip, outside XCUI.TabBar.
        let phone = app.tabBars.buttons[title]
        return phone.exists ? phone : app.buttons.matching(NSPredicate(format: "label == %@", title)).firstMatch
    }
    @MainActor private func backButton() -> XCUIElement {
        app.navigationBars.buttons.matching(NSPredicate(format: "label IN %@", ["Werkstatt Test", "Rechner", "Calculators"])).firstMatch
    }
    @MainActor func testProjectNotebookEntryExists() {
        launchFreshApplication()
        XCTAssertTrue(app.buttons["project-new"].waitForExistence(timeout: 8), "The unified project entry must be visible on normal launch")
        XCTAssertTrue(tab("Rechner").exists)
        XCTAssertTrue(tab("Pro").exists)
    }
    @MainActor func testProjectSurvivesRelaunchAndSharingActuallyOpens() {
        launchFreshApplication()
        let create = app.buttons["project-new"]
        XCTAssertTrue(create.waitForExistence(timeout: 8)); create.tap()
        let name = app.textFields["project-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3)); name.tap(); name.typeText("Haus Lindenweg")
        app.buttons["project-create"].tap()
        let project = app.buttons["project-card-Haus Lindenweg"]
        XCTAssertTrue(project.waitForExistence(timeout: 4)); project.tap()
        XCTAssertTrue(app.buttons["module-heat"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["module-pipe"].exists)
        XCTAssertTrue(app.buttons["module-volume"].exists)
        scrollTo(app.buttons["report-open"]); app.buttons["report-open"].tap()
        let share = app.buttons["report-share-text"]
        XCTAssertTrue(share.waitForExistence(timeout: 3)); share.tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 5) || app.buttons["Copy"].exists || app.buttons["Kopieren"].exists, "Real system sharing must appear on phone and iPad")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["project-card-Haus Lindenweg"].waitForExistence(timeout: 5))
    }
    @MainActor private func scrollTo(_ element: XCUIElement, allowPartialCard: Bool = false) {
        for _ in 0..<18 {
            // A native iPad sheet is smaller than the application window. Scroll
            // its own viewport; a window-wide swipe can move the background.
            let fillBar = app.navigationBars["Befüllung erfassen"]
            let modal = fillBar.exists
            let collection = app.collectionViews.firstMatch
            let scroll = app.scrollViews.firstMatch
            let container: XCUIElement? = modal ? nil : (collection.exists ? collection : (scroll.exists ? scroll : nil))
            let viewport: CGRect
            if modal {
                let bar = fillBar.frame
                viewport = CGRect(x: bar.minX, y: bar.maxY, width: bar.width, height: min(550, app.frame.maxY - bar.maxY - 34))
            } else { viewport = (container?.frame ?? app.frame).intersection(app.frame) }
            let top = modal ? viewport.minY + 8 : max(viewport.minY, app.navigationBars.firstMatch.frame.maxY) + 8
            let tabBar = app.tabBars.firstMatch
            let bottom = !modal && tabBar.exists ? min(viewport.maxY - 8, tabBar.frame.minY - 8) : viewport.maxY - 8
            let bounds = CGRect(x: viewport.minX, y: top, width: viewport.width, height: max(1, bottom - top))
            func swipe(up: Bool) {
                if container != nil {
                    // A native flick skips a short button between tall, fully
                    // wrapped accessibility cards, then oscillates past it.
                    let distance = element.exists ? abs(element.frame.midY - bounds.midY) : 180
                    let step = min(min(180, bounds.height * 0.55), max(12, distance))
                    let a = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: bounds.midX, dy: bounds.midY + (up ? step/2 : -step/2)))
                    let b = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: bounds.midX, dy: bounds.midY + (up ? -step/2 : step/2)))
                    a.press(forDuration: 0.1, thenDragTo: b, withVelocity: .slow, thenHoldForDuration: 0.1)
                    return
                }
                let near = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: viewport.midX, dy: viewport.minY + 100))
                let far = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: viewport.midX, dy: viewport.minY + min(400, viewport.height - 30)))
                if up { far.press(forDuration: 0.05, thenDragTo: near) } else { near.press(forDuration: 0.05, thenDragTo: far) }
            }
            if element.exists {
                let frame = element.frame
                if element.isHittable && frame.minY >= bounds.minY && frame.maxY <= bounds.maxY { return }
                if allowPartialCard && element.isHittable {
                    let title = element.staticTexts.firstMatch
                    if title.exists && title.isHittable && title.frame.minY >= bounds.minY && title.frame.maxY <= bounds.maxY { return }
                }
                if frame.minY < bounds.minY { swipe(up: false); continue }
            }
            swipe(up: true)
        }
        let tree = XCTAttachment(string: app.debugDescription); tree.lifetime = .keepAlways; add(tree)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.lifetime = .keepAlways; add(shot)
        XCTFail("Expected control must become fully reachable within its scrolling viewport")
    }
    @MainActor func testProShopHasExplicitRestoreAndPermanentPurchaseExplanation() {
        launchFreshApplication()
        XCTAssertTrue(tab("Pro").waitForExistence(timeout: 8)); tab("Pro").tap()
        XCTAssertTrue(app.buttons["store-restore"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["pro-permanent"].exists)
        XCTAssertTrue(app.buttons["store-purchase"].exists)
    }
    @MainActor func testNewColdMeasurementRequiresActualInputs() {
        launchFreshApplication()
        XCTAssertTrue(tab("Rechner").waitForExistence(timeout: 8)); tab("Rechner").tap()
        let cold = app.buttons["calculator-cold"]; scrollTo(cold); cold.tap()
        let addReading = app.buttons["cold-add-reading"]
        XCTAssertTrue(addReading.waitForExistence(timeout: 3)); addReading.tap()
        let save = app.buttons["cold-save-reading"]
        let appeared = save.waitForExistence(timeout: 3)
        if !appeared {
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.lifetime = .keepAlways; add(shot)
            let tree = XCTAttachment(string: app.debugDescription); tree.lifetime = .keepAlways; add(tree)
        }
        XCTAssertTrue(appeared, "A new actual measurement must open an explicit entry sheet")
        XCTAssertFalse(save.isEnabled, "Preset example temperatures must not be saved as actual measurements")
        XCTAssertTrue(app.textFields["cold-measured-suction"].exists)
    }
    @MainActor func testManufacturerComponentSheetActuallyOpens() {
        launchFreshApplication()
        tab("Rechner").tap()
        let volume = app.buttons["calculator-volume"]; scrollTo(volume); volume.tap()
        let addComponent = app.buttons["volume-add-component"]; scrollTo(addComponent); addComponent.tap()
        XCTAssertTrue(app.textFields["Bauteilbezeichnung"].waitForExistence(timeout: 3), "The actual component-entry sheet must be presented from a stable parent")
    }
    @MainActor func testFillCannotSaveAnUnenteredStartReadingAsZero() {
        launchFreshApplication()
        tab("Rechner").tap()
        let volume = app.buttons["calculator-volume"]; scrollTo(volume); volume.tap()
        let addComponent = app.buttons["volume-add-component"]; scrollTo(addComponent); addComponent.tap()
        let name = app.textFields["component-name"]; XCTAssertTrue(name.waitForExistence(timeout: 4))
        name.tap(); name.typeText("Testpuffer")
        let litres = app.textFields["component-unit-liters"]; litres.tap(); litres.typeText(XCUIKeyboardKey.delete.rawValue + "100")
        app.buttons["component-save"].tap()
        XCTAssertTrue(XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.buttons["component-save"])], timeout: 4) == .completed)
        let fill = app.buttons["volume-add-fill"]; scrollTo(fill); fill.tap()
        let save = app.buttons["fill-save-reading"]; XCTAssertTrue(save.waitForExistence(timeout: 4)); XCTAssertFalse(save.isEnabled)
        XCTAssertTrue(app.staticTexts["Unveränderliche Inventar-Basis: 100 l"].exists, "The reading must freeze the inventory after the newly added component")
        let end = app.textFields["fill-meter-after"]; end.tap(); end.typeText("100")
        app.buttons["Fertig"].tap() // Expose the complete switch below the keyboard.
        let boundary = app.switches["fill-confirm-boundary"]; scrollTo(boundary)
        // UIKit exposes the row as a Switch as well as the actual UISwitch.
        // Activate the native control; tapping the row label is not its action.
        let indicator = boundary.switches.firstMatch
        if indicator.exists { indicator.tap() }
        else { boundary.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: 0.5)).tap() }
        XCTAssertEqual(boundary.value as? String, "1", "The system boundary must actually be confirmed")
        XCTAssertFalse(save.isEnabled, "An untouched start field is missing, not a measured zero")
        let start = app.textFields["fill-meter-before"]
        scrollTo(start); start.tap(); start.typeText("0")
        app.buttons["Fertig"].tap()
        if !save.isEnabled {
            let tree = XCTAttachment(string: app.debugDescription); tree.name = "Actual-fill-entry-values"; tree.lifetime = .keepAlways; add(tree)
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "Actual-fill-entry-values"; shot.lifetime = .keepAlways; add(shot)
            print("FILL FIELD VALUES before=\(String(describing: start.value)) after=\(String(describing: end.value)) confirmation=\(String(describing: boundary.value))")
        }
        XCTAssertTrue(NSPredicate(format: "isEnabled == true").evaluate(with: save), "An explicitly measured zero is valid")
        save.tap()
        XCTAssertFalse(save.waitForExistence(timeout: 1), "The completed reading should be accepted and the sheet dismissed")
    }
    @MainActor func testTransfersAndRepeatedInventorySyncPersistWithoutDuplicates() {
        launchFreshApplication()
        app.buttons["project-new"].tap()
        let name = app.textFields["project-name"]; XCTAssertTrue(name.waitForExistence(timeout: 3)); name.tap(); name.typeText("Werkstatt Test")
        app.buttons["project-create"].tap()
        let card = app.buttons["project-card-Werkstatt Test"]; XCTAssertTrue(card.waitForExistence(timeout: 3)); card.tap()
        app.buttons["module-heat"].tap()
        let addRoom = app.buttons["heat-add-room"]; XCTAssertTrue(addRoom.waitForExistence(timeout: 3)); addRoom.tap()
        let transfer = app.buttons["heat-transfer-flow"]; scrollTo(transfer); transfer.tap()
        XCTAssertTrue(app.buttons["Übernehmen"].waitForExistence(timeout: 3)); app.buttons["Übernehmen"].tap()
        backButton().tap()
        let pipe = app.buttons["module-pipe"]; scrollTo(pipe); pipe.tap()
        let addPipe = app.buttons["pipe-add-section"]; XCTAssertTrue(addPipe.waitForExistence(timeout: 3)); addPipe.tap()
        for _ in 0..<2 {
            let sync = app.buttons["pipe-sync-volume"]; scrollTo(sync); sync.tap()
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Aktualisieren")).firstMatch.waitForExistence(timeout: 3)); app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Aktualisieren")).firstMatch.tap()
        }
        backButton().tap()
        let volume = app.buttons["module-volume"]; scrollTo(volume); volume.tap()
        XCTAssertTrue(app.staticTexts["Abschnitt 1"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Abschnitt 1").count, 1)
        backButton().tap(); app.buttons["project-save"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(card.waitForExistence(timeout: 5)); card.tap()
        scrollTo(volume); volume.tap()
        XCTAssertTrue(app.staticTexts["Abschnitt 1"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts.matching(identifier: "Abschnitt 1").count, 1)
    }

    @MainActor func testAllSixCalculatorsReturnToTheirParent() {
        launchFreshApplication()
        tab("Rechner").tap()
        for module in ["heat", "pipe", "volume", "air", "cold", "service"] {
            let link = app.buttons["calculator-" + module]; scrollTo(link); link.tap()
            let back = backButton()
            XCTAssertTrue(back.waitForExistence(timeout: 3)); back.tap()
            XCTAssertTrue(app.navigationBars["Rechner"].waitForExistence(timeout: 3))
        }
    }
    @MainActor func testEnglishLargestTextAndLandscapeKeepEssentialControlsReachable() {
        launchFreshApplication(language: "en", extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let create = app.buttons["project-new"]; scrollTo(create); XCTAssertTrue(create.isHittable)
        tab("Pro").tap()
        let restore = app.buttons["store-restore"]
        XCTAssertTrue(restore.waitForExistence(timeout: 3)); XCTAssertTrue(restore.isHittable)
        scrollTo(app.buttons["store-purchase"])
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "English-LargestText-Landscape"; shot.lifetime = .keepAlways; add(shot)
        tab("Calculators").tap()
        for (module, title) in [("heat", "Heating"), ("pipe", "Pipe route"), ("volume", "Water volume"), ("air", "Ventilation"), ("cold", "Refrigeration"), ("service", "Service")] {
            let card = app.buttons["calculator-" + module]
            scrollTo(card, allowPartialCard: true); XCTAssertTrue(card.isHittable)
            card.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 4))
            let back = app.navigationBars.buttons["Calculators"]
            XCTAssertTrue(back.exists); back.tap()
        }
        let tools = XCTAttachment(screenshot: app.screenshot()); tools.name = "English-LargestText-Tools"; tools.lifetime = .keepAlways; add(tools)
    }

}
