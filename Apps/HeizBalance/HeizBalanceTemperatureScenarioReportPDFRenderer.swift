import Foundation
import UIKit

struct HeizBalanceTemperatureScenarioReportPDFRenderer {
    static func render(_ snapshot: HeizBalanceTemperatureScenarioReportSnapshot) -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)

        return renderer.pdfData { context in
            let writer = Writer(context: context, pageBounds: pageBounds, snapshot: snapshot)
            writer.render()
        }
    }

    private final class Writer {
        private let context: UIGraphicsPDFRendererContext
        private let pageBounds: CGRect
        private let snapshot: HeizBalanceTemperatureScenarioReportSnapshot
        private let margin: CGFloat = 42
        private let footerHeight: CGFloat = 34
        private var y: CGFloat = 0
        private var pageNumber = 0

        private let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        private let sectionFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        private let headingFont = UIFont.systemFont(ofSize: 10.5, weight: .semibold)
        private let bodyFont = UIFont.systemFont(ofSize: 9.5, weight: .regular)
        private let smallFont = UIFont.systemFont(ofSize: 8, weight: .regular)
        private let smallBoldFont = UIFont.systemFont(ofSize: 8, weight: .semibold)

        init(
            context: UIGraphicsPDFRendererContext,
            pageBounds: CGRect,
            snapshot: HeizBalanceTemperatureScenarioReportSnapshot
        ) {
            self.context = context
            self.pageBounds = pageBounds
            self.snapshot = snapshot
        }

        func render() {
            beginPage()
            line("HeizBalance", font: titleFont, spacingAfter: 2)
            line("Temperatur-Szenarien", font: UIFont.systemFont(ofSize: 14, weight: .semibold), spacingAfter: 10)
            paragraph(
                "Technische Heizflächenbewertung für explizite Vorlauf-/Rücklauftemperaturen. Keine Wärmepumpenauslegung, keine COP-/Bivalenzbewertung und kein normativer Heizlastnachweis.",
                font: headingFont,
                spacingAfter: 12
            )
            keyValue("Projekt", snapshot.projectName)
            keyValue("Snapshot", snapshot.schema)
            keyValue("Rechenprofil", snapshot.calculationProfile)
            keyValue("Erzeugt", DateFormatter.scenarioReportDate.string(from: snapshot.generatedAt))

            for scenario in snapshot.scenarios {
                render(scenario: scenario)
            }
        }

        private var contentWidth: CGFloat {
            pageBounds.width - 2 * margin
        }

        private var contentBottom: CGFloat {
            pageBounds.height - margin - footerHeight
        }

        private func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = margin

            draw(
                "HeizBalance · Temperatur-Szenarien",
                font: smallBoldFont,
                rect: CGRect(x: margin, y: 18, width: contentWidth, height: 14),
                color: .darkGray
            )
            draw(
                "Seite \(pageNumber)",
                font: smallFont,
                rect: CGRect(x: margin, y: pageBounds.height - 25, width: contentWidth, height: 12),
                alignment: .right,
                color: .darkGray
            )
            draw(
                "Technische Vorbereitung · keine Hersteller-Ersatzempfehlung",
                font: smallFont,
                rect: CGRect(x: margin, y: pageBounds.height - 25, width: contentWidth - 65, height: 12),
                color: .darkGray
            )
        }

        private func render(scenario: HeizBalanceTemperatureScenarioReportSnapshot.ScenarioData) {
            ensureSpace(105)
            section("\(scenario.title) · \(temperaturePair(flow: scenario.flowTemperatureC, returnTemperature: scenario.returnTemperatureC))")
            keyValue("Heizflächen auswertbar", "\(scenario.evaluableSurfaceCount) / \(scenario.surfaceCount)")
            keyValue("Heizflächen ausreichend", "\(scenario.sufficientSurfaceCount) / \(scenario.surfaceCount)")
            keyValue("Systemaussage vollständig", scenario.coverageComplete ? "Ja" : "Nein")

            if scenario.coverageComplete {
                keyValue("Alle Heizflächen ausreichend", scenario.allSufficient ? "Ja" : "Nein", emphasized: true)
                keyValue("Begrenzende Heizfläche", scenario.limitingSurfaceName ?? "—")
                keyValue("Schlechtester Deckungsgrad", percent(scenario.limitingCapacityRatio))
                if let factor = scenario.limitingNominalPowerFactor, factor > 1 {
                    keyValue("Erforderlicher Nennleistungsfaktor", "×\(number(factor, 2))", emphasized: true)
                    keyValue(
                        "Erforderliche ΔT50-Nennleistung begrenzend",
                        format(scenario.limitingRequiredNominalPowerDeltaT50W, unit: "W", decimals: 0)
                    )
                }
            } else {
                paragraph("Systemaussage gesperrt: mindestens eine Heizfläche ist für dieses Szenario nicht vollständig auswertbar.", font: smallFont)
            }

            subheading("Heizflächen")
            for surface in scenario.surfaces {
                render(surface: surface)
            }
        }

        private func render(surface: HeizBalanceTemperatureScenarioReportSnapshot.SurfaceData) {
            ensureSpace(56)
            line(surface.displayName, font: headingFont, spacingAfter: 1)
            line(surface.floorName, font: smallFont, indent: 10, spacingAfter: 2)

            if let available = surface.availablePowerW,
               let ratio = surface.capacityRatio,
               let sufficient = surface.sufficient,
               let requiredNominal = surface.requiredNominalPowerDeltaT50W,
               let factor = surface.nominalPowerFactor {
                keyValue("Verfügbare Leistung", format(available, unit: "W", decimals: 0), indent: 10)
                keyValue("Deckungsgrad", percent(ratio), indent: 10)
                keyValue("Ausreichend", sufficient ? "Ja" : "Nein", indent: 10)
                if !sufficient {
                    keyValue("Erforderliche ΔT50-Nennleistung", format(requiredNominal, unit: "W", decimals: 0), indent: 10)
                    keyValue("Faktor zur aktuellen Nennleistung", "×\(number(factor, 2))", indent: 10, emphasized: true)
                }
            } else {
                for missing in surface.missingInputs {
                    paragraph("• \(missing)", font: smallFont, indent: 10, spacingAfter: 1)
                }
            }
            y += 4
        }

        private func ensureSpace(_ height: CGFloat) {
            if y + height > contentBottom {
                beginPage()
            }
        }

        private func section(_ text: String) {
            ensureSpace(28)
            y += 8
            line(text, font: sectionFont, spacingAfter: 6)
        }

        private func subheading(_ text: String) {
            ensureSpace(22)
            y += 4
            line(text, font: headingFont, spacingAfter: 4)
        }

        private func keyValue(
            _ key: String,
            _ value: String,
            indent: CGFloat = 0,
            emphasized: Bool = false
        ) {
            ensureSpace(18)
            let keyWidth = max(190, (contentWidth - indent) * 0.48)
            let valueFont = emphasized ? headingFont : bodyFont
            draw(
                key,
                font: bodyFont,
                rect: CGRect(x: margin + indent, y: y, width: keyWidth, height: 16),
                color: .darkGray
            )
            draw(
                value.isEmpty ? "—" : value,
                font: valueFont,
                rect: CGRect(x: margin + indent + keyWidth, y: y, width: contentWidth - indent - keyWidth, height: 16),
                alignment: .right
            )
            y += 16
        }

        private func line(
            _ text: String,
            font: UIFont,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 3
        ) {
            let width = contentWidth - indent
            let height = textHeight(text, font: font, width: width)
            ensureSpace(height + spacingAfter)
            draw(text, font: font, rect: CGRect(x: margin + indent, y: y, width: width, height: height))
            y += height + spacingAfter
        }

        private func paragraph(
            _ text: String,
            font: UIFont? = nil,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 6
        ) {
            let usedFont = font ?? bodyFont
            let width = contentWidth - indent
            let height = textHeight(text, font: usedFont, width: width)
            ensureSpace(height + spacingAfter)
            draw(text, font: usedFont, rect: CGRect(x: margin + indent, y: y, width: width, height: height), color: .darkGray)
            y += height + spacingAfter
        }

        private func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            return ceil(rect.height) + 2
        }

        private func draw(
            _ text: String,
            font: UIFont,
            rect: CGRect,
            alignment: NSTextAlignment = .left,
            color: UIColor = .black
        ) {
            let style = NSMutableParagraphStyle()
            style.alignment = alignment
            style.lineBreakMode = .byWordWrapping
            (text as NSString).draw(
                with: rect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: style
                ],
                context: nil
            )
        }

        private func temperaturePair(flow: Double, returnTemperature: Double) -> String {
            "\(number(flow, 1)) / \(number(returnTemperature, 1)) °C"
        }

        private func percent(_ value: Double?) -> String {
            guard let value, value.isFinite else { return "—" }
            return "\(number(value * 100, 0)) %"
        }

        private func format(_ value: Double?, unit: String, decimals: Int) -> String {
            guard let value, value.isFinite else { return "—" }
            let numberText = number(value, decimals)
            return unit.isEmpty ? numberText : "\(numberText) \(unit)"
        }

        private func number(_ value: Double, _ decimals: Int) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = Locale(identifier: "de_DE")
            formatter.minimumFractionDigits = decimals
            formatter.maximumFractionDigits = decimals
            return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.*f", decimals, value)
        }
    }
}

private extension DateFormatter {
    static let scenarioReportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
