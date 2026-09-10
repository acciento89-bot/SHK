import XCTest

final class FieldWorkflowUITests: XCTestCase {
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testCreatePersistAndReadFieldProject() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()
        let variants = [
            ("Bestandsaufnahme starten", "Gebäudename", "Raum hinzufügen"),
            ("Fließweg anlegen", "Bezeichnung", "Abschnitt hinzufügen"),
            ("Einmessung beginnen", "Anlage / Projekt", "Auslass hinzufügen"),
            ("Serviceverlauf starten", "Anlage / Auftrag", "Messung hinzufügen")
        ]
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        capture(app, "01-home")
        let variant = try XCTUnwrap(variants.first { app.buttons[$0.0].exists })
        app.buttons[variant.0].tap()
        let name = app.textFields[variant.1]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Praxisprüfung " + String(UUID().uuidString.prefix(8)))
        let projectName = try XCTUnwrap(name.value as? String)
        app.buttons[variant.2].tap()
        capture(app, "02-editor")
        XCTAssertTrue(app.buttons["Speichern"].isEnabled)
        app.buttons["Speichern"].tap()
        XCTAssertTrue(app.staticTexts[projectName].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts[projectName].waitForExistence(timeout: 10))
        app.staticTexts[projectName].tap()
        capture(app, "03-saved-detail")
        // Saved results must remain readable with largest accessibility text and dark appearance.
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-AppleInterfaceStyle", "Dark"]
        app.launch()
        XCTAssertTrue(app.staticTexts[projectName].waitForExistence(timeout: 10))
        capture(app, "04-accessibility-home")
        app.staticTexts[projectName].tap()
        capture(app, "05-accessibility-detail")
    }
}
