import XCTest

final class FieldWorkflowUITests: XCTestCase {
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
    private func enter(_ value: String, in label: String, app: XCUIApplication) {
        let field = app.textFields[label]
        let form = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.scrollViews.firstMatch
        // Start at the top: opening a disclosure can leave its first fields above the viewport.
        for _ in 0..<4 { form.swipeDown() }
        for _ in 0..<16 where !field.isHittable {
            form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
                .press(forDuration: 0.05, thenDragTo: form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)))
        }
        XCTAssertTrue(field.isHittable, "Input must be reachable: " + label)
        field.tap(); field.typeText(value)
    }
    func testCreatePersistAndReadFieldProject() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
        app.launch()
        let variants = [
            ("Bestandsaufnahme starten", "Gebäudename", "Raum hinzufügen"),
            ("Fließweg anlegen", "Bezeichnung", "Abschnitt hinzufügen"),
            ("Einmessung beginnen", "Anlage / Projekt", "Auslass hinzufügen"),
            ("Serviceverlauf starten", "Anlage / Auftrag", "Messung hinzufügen")
        ]
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label IN %@", variants.map { $0.0 })).firstMatch.waitForExistence(timeout: 15))
        capture(app, "01-home")
        let variant = try XCTUnwrap(variants.first { app.buttons[$0.0].exists })
        app.buttons[variant.0].tap()
        let name = app.textFields[variant.1]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Praxisprüfung " + String(UUID().uuidString.prefix(8)))
        let projectName = try XCTUnwrap(name.value as? String)
        app.buttons[variant.2].tap()
        if variant.0 == "Bestandsaufnahme starten" {
            app.buttons["Raum 1"].tap()
            enter("800", in: "Ermittelte Raumheizlast, W", app: app)
            enter("1600", in: "Gesamte Nennleistung bei ΔT50, W", app: app)
        }
        if variant.0 == "Serviceverlauf starten" {
            let disclosure = app.buttons.matching(NSPredicate(format: "label CONTAINS ':'")).firstMatch
            disclosure.tap()
            let fields = [("Sauggastemperatur, °C", "8"), ("Sättigung Verdampfung · Taupunkt, °C", "2"), ("Sättigung Kondensation · Blasenpunkt, °C", "40"), ("Flüssigkeitsleitung, °C", "35")]
            for (label, number) in fields {
                enter(number, in: label, app: app)
            }
        }
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
        capture(app, "04-accessibility-home")
        let savedProject = app.staticTexts[projectName]
        for _ in 0..<8 where !savedProject.isHittable { app.swipeUp() }
        XCTAssertTrue(savedProject.exists)
        savedProject.tap()
        capture(app, "05-accessibility-detail")
    }
}
