import Foundation
import UIKit

struct HeizBalanceLowTemperatureReportPDFRenderer {
    static func render(_ snapshot: HeizBalanceLowTemperatureReportSnapshot) -> Data {
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
        private let snapshot: HeizBalanceLowTemperatureReportSnapshot
        private let margin: CGFloat = 42
        private let footerHeight: CGFloat = 34
        private var y: CGFloat = 0
        private var pageNumber = 0

        private let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        private let sectionFont = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        private let bodyFont = UIFont.systemFont(ofSize: 9.5, weight: .regular)
        private let boldFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
        private let smallFont = UIFont.systemFont(ofSize: 8, weight: .regular)

        init(
            context: UIGraphicsPDFRendererContext,
            pageBounds: CGRect,
            snapshot: HeizBalanceLowTemperatureReportSnapshot
        ) {
            self.context = context
            self.pageBounds = pageBounds
            self.snapshot = snapshot
        }

        private var contentWidth: CGFloat {
            pageBounds.width - 2 * margin
        }

        private var contentBottom: CGFloat {
            pageBounds.height - margin - footerHeight
        }

        func render() {
            beginPage()
            line("Niedertemperatur-Check", font: titleFont, spacingAfter: 4)
            paragraph(
                "Technische Heizflächenbewertung mit konstanter Wasserspreizung. Keine Wärmepumpenauslegung, keine COP-/Bivalenzbewertung und kein normativer Heizlastnachweis.",
                font: boldFont,
                spacingAfter: 12
            )

            section("Rechenstand")
            keyValue("Projekt", snapshot.projectName)
            keyValue("Snapshot-Schema", snapshot.schema)
            keyValue("Rechenprofil", snapshot.calculationProfile)
            keyValue("Erzeugt", snapshot.generatedAt.formatted(date: .numeric, time: .standard))
            keyValue("Technische Vorbereitung", snapshot.technicalPreparationOnly ? "Ja" : "Nein")

            section("Systemauswertung")
            keyValue("Verwendete Spreizung", format(snapshot.waterTemperatureDifferenceK, unit: "K", decimals: 1))
            keyValue(
                "Vergleich VL / RL",
                temperaturePair(
                    flow: snapshot.comparisonFlowTemperatureC,
                    returnTemperature: snapshot.comparisonReturnTemperatureC
                )
            )
            keyValue("Heizflächen auswertbar", "\(snapshot.evaluableSurfaceCount) / \(snapshot.surfaceCount)")
            keyValue("Abdeckung vollständig", snapshot.coverageComplete ? "Ja" : "Nein")
            keyValue("Minimaler System-Vorlauf", format(snapshot.minimumSystemFlowTemperatureC, unit: "°C", decimals: 1), emphasized: true)
            keyValue("Zugehöriger Rücklauf", format(snapshot.minimumSystemReturnTemperatureC, unit: "°C", decimals: 1))
            keyValue("Begrenzende Heizfläche", snapshot.limitingSurfaceName ?? "—")
            if let sufficient = snapshot.comparisonSufficient {
                keyValue("Vergleichssystem ausreichend", sufficient ? "Ja" : "Nein", emphasized: true)
            } else {
                keyValue("Vergleichssystem ausreichend", "Nicht vollständig bewertbar")
            }

            section("Heizflächen")
            if snapshot.surfaces.isEmpty {
                paragraph("Keine Heizflächen für diesen Rechenstand vorhanden.")
            }

            for surface in snapshot.surfaces {
                ensureSpace(78)
                line(surface.displayName, font: boldFont, spacingAfter: 1)
                line(surface.floorName, font: smallFont, spacingAfter: 3)

                if let minimumFlow = surface.minimumFlowTemperatureC,
                   let minimumReturn = surface.minimumReturnTemperatureC {
                    keyValue(
                        "Mind. VL / RL",
                        "\(number(minimumFlow, 1)) / \(number(minimumReturn, 1)) °C",
                        indent: 10,
                        emphasized: true
                    )
                    keyValue("Leistung bei Vergleich", format(surface.comparisonAvailablePowerW, unit: "W", decimals: 0), indent: 10)
                    if let ratio = surface.comparisonCapacityRatio {
                        keyValue("Deckung Vergleich", "\(number(ratio * 100, 0)) %", indent: 10)
                    }
                    if let sufficient = surface.comparisonSufficient {
                        keyValue("Vergleich ausreichend", sufficient ? "Ja" : "Nein", indent: 10)
                    }
                } else {
                    paragraph("Nicht vollständig auswertbar.", font: boldFont, indent: 10, spacingAfter: 2)
                    for missing in surface.missingInputs {
                        paragraph("• \(missing)", font: smallFont, indent: 14, spacingAfter: 1)
                    }
                }
                y += 4
            }
        }

        private func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = margin

            draw(
                "HeizBalance · Niedertemperatur-Supplement",
                font: UIFont.systemFont(ofSize: 8, weight: .semibold),
                rect: CGRect(x: margin, y: 18, width: contentWidth, height: 12),
                color: .darkGray
            )
            draw(
                "Technische Vorbereitung",
                font: smallFont,
                rect: CGRect(x: margin, y: pageBounds.height - 25, width: contentWidth - 70, height: 12),
                color: .darkGray
            )
            draw(
                "Seite LT-\(pageNumber)",
                font: smallFont,
                rect: CGRect(x: margin, y: pageBounds.height - 25, width: contentWidth, height: 12),
                alignment: .right,
                color: .darkGray
            )
        }

        private func ensureSpace(_ height: CGFloat) {
            if y + height > contentBottom {
                beginPage()
            }
        }

        private func section(_ text: String) {
            ensureSpace(28)
            y += 7
            line(text, font: sectionFont, spacingAfter: 5)
        }

        private func keyValue(
            _ key: String,
            _ value: String,
            indent: CGFloat = 0,
            emphasized: Bool = false
        ) {
            ensureSpace(17)
            let keyWidth = contentWidth * 0.50
            draw(
                key,
                font: bodyFont,
                rect: CGRect(x: margin + indent, y: y, width: keyWidth - indent, height: 15),
                color: .darkGray
            )
            draw(
                value,
                font: emphasized ? boldFont : bodyFont,
                rect: CGRect(x: margin + keyWidth, y: y, width: contentWidth - keyWidth, height: 15),
                alignment: .right
            )
            y += 15
        }

        private func line(
            _ text: String,
            font: UIFont,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 3
        ) {
            let height = textHeight(text, font: font, width: contentWidth - indent)
            ensureSpace(height + spacingAfter)
            draw(
                text,
                font: font,
                rect: CGRect(x: margin + indent, y: y, width: contentWidth - indent, height: height)
            )
            y += height + spacingAfter
        }

        private func paragraph(
            _ text: String,
            font: UIFont? = nil,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 5
        ) {
            let usedFont = font ?? bodyFont
            let height = textHeight(text, font: usedFont, width: contentWidth - indent)
            ensureSpace(height + spacingAfter)
            draw(
                text,
                font: usedFont,
                rect: CGRect(x: margin + indent, y: y, width: contentWidth - indent, height: height),
                color: .darkGray
            )
            y += height + spacingAfter
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
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style
            ]
            text.draw(in: rect, withAttributes: attributes)
        }

        private func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            return ceil(rect.height) + 1
        }

        private func temperaturePair(flow: Double?, returnTemperature: Double?) -> String {
            guard let flow, let returnTemperature else { return "—" }
            return "\(number(flow, 1)) / \(number(returnTemperature, 1)) °C"
        }

        private func format(_ value: Double?, unit: String, decimals: Int) -> String {
            guard let value else { return "—" }
            return format(value, unit: unit, decimals: decimals)
        }

        private func format(_ value: Double, unit: String, decimals: Int) -> String {
            let suffix = unit.isEmpty ? "" : " \(unit)"
            return number(value, decimals) + suffix
        }

        private func number(_ value: Double, _ decimals: Int) -> String {
            value.formatted(.number.precision(.fractionLength(decimals)))
        }
    }
}
