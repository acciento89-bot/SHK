import Foundation
import UIKit

struct HeizBalanceRadiatorReplacementReportPDFRenderer {
    static func render(_ snapshot: HeizBalanceRadiatorReplacementReportSnapshot) -> Data {
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
        private let snapshot: HeizBalanceRadiatorReplacementReportSnapshot
        private let margin: CGFloat = 42
        private let footerHeight: CGFloat = 34
        private var y: CGFloat = 0
        private var pageNumber = 0

        private let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        private let sectionFont = UIFont.systemFont(ofSize: 13, weight: .bold)
        private let bodyFont = UIFont.systemFont(ofSize: 9.5)
        private let smallFont = UIFont.systemFont(ofSize: 8)
        private let smallBoldFont = UIFont.systemFont(ofSize: 8, weight: .semibold)

        init(
            context: UIGraphicsPDFRendererContext,
            pageBounds: CGRect,
            snapshot: HeizBalanceRadiatorReplacementReportSnapshot
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
            line("HeizBalance", font: titleFont, spacingAfter: 2)
            line("Festgehaltene Heizkörper-Auswahl", font: UIFont.systemFont(ofSize: 14, weight: .semibold), spacingAfter: 10)
            paragraph(
                "Dokumentation ausdrücklich vom Benutzer festgehaltener Katalogkandidaten. Keine automatische Produktempfehlung, keine Montagefreigabe und keine Herstellerfreigabe.",
                font: UIFont.systemFont(ofSize: 10.5, weight: .semibold),
                spacingAfter: 12
            )
            keyValue("Projekt", snapshot.projectName)
            keyValue("Snapshot", snapshot.schema)
            keyValue("Erzeugt", reportDateFormatter.string(from: snapshot.generatedAt))
            keyValue("Festgehaltene Auswahlen", "\(snapshot.entries.count)")

            if snapshot.entries.isEmpty {
                paragraph("Für dieses Projekt wurde noch kein Heizkörper-Katalogkandidat ausdrücklich festgehalten.", font: bodyFont, spacingAfter: 8)
                return
            }

            for entry in snapshot.entries {
                render(entry)
            }
        }

        private func render(_ entry: HeizBalanceRadiatorReplacementReportSnapshot.Entry) {
            ensureSpace(185)
            section(entry.roomName + " · " + entry.surfaceName)
            keyValue("Geschoss", entry.floorName)
            keyValue("Produkt", entry.selection.displayName, emphasized: true)
            keyValue("Datensatz", entry.selection.datasetName + " · " + entry.selection.datasetVersion)
            keyValue("Datensatz-ID", entry.selection.datasetID)
            keyValue("Produkt-ID", entry.selection.productID)
            if let article = entry.selection.articleNumber, !article.isEmpty {
                keyValue("Artikelnummer", article)
            }
            keyValue("Nutzungsgrundlage", entry.selection.usageBasis.title)
            keyValue("Quelle", entry.selection.sourceReference)
            if let productSource = entry.selection.productSourceReference, !productSource.isEmpty {
                keyValue("Produktquelle", productSource)
            }
            keyValue(
                "Bewertetes Ziel",
                number(entry.selection.targetFlowTemperatureC, decimals: 1)
                    + " / "
                    + number(entry.selection.targetReturnTemperatureC, decimals: 1)
                    + " °C"
            )
            keyValue("Aktuelles Ziel identisch", entry.currentTargetMatchesSelection ? "Ja" : "Nein", emphasized: !entry.currentTargetMatchesSelection)
            keyValue("Erforderliche Leistung", number(entry.selection.requiredPowerW, decimals: 0) + " W")
            keyValue("Leistung am Ziel", number(entry.selection.availablePowerW, decimals: 0) + " W")
            keyValue("Deckungsgrad", number(entry.selection.capacityRatio * 100, decimals: 0) + " %")
            keyValue("Nennleistung ΔT50", number(entry.selection.nominalPowerDeltaT50W, decimals: 0) + " W")
            keyValue("Exponent n", number(entry.selection.exponent, decimals: 3))

            let dimensions = dimensionText(entry.selection)
            if !dimensions.isEmpty {
                keyValue("Abmessungen", dimensions)
            }

            keyValue("Auswahlzeitpunkt", reportDateFormatter.string(from: entry.selection.selectedAt))

            if !entry.currentTargetMatchesSelection {
                paragraph(
                    "Hinweis: Das aktuell gespeicherte Sanierungsziel unterscheidet sich von dem Temperaturniveau, unter dem diese Auswahl festgehalten wurde. Vor Verwendung neu bewerten.",
                    font: smallBoldFont,
                    spacingAfter: 8
                )
            }
        }

        private func dimensionText(_ selection: HeizBalanceRadiatorReplacementSelection) -> String {
            var values: [String] = []
            if let width = selection.widthMM { values.append("B " + number(width, decimals: 0) + " mm") }
            if let height = selection.heightMM { values.append("H " + number(height, decimals: 0) + " mm") }
            if let depth = selection.depthMM { values.append("T " + number(depth, decimals: 0) + " mm") }
            return values.joined(separator: " · ")
        }

        private func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = margin

            draw(
                "HeizBalance · Heizkörper-Auswahl",
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
                "Technische Vorbereitung · explizite Benutzerauswahl",
                font: smallFont,
                rect: CGRect(x: margin, y: pageBounds.height - 25, width: contentWidth - 65, height: 12),
                color: .darkGray
            )
        }

        private func ensureSpace(_ height: CGFloat) {
            if y + height > contentBottom {
                beginPage()
            }
        }

        private func section(_ text: String) {
            ensureSpace(26)
            y += 8
            line(text, font: sectionFont, spacingAfter: 5)
        }

        private func keyValue(_ key: String, _ value: String, emphasized: Bool = false) {
            ensureSpace(20)
            let keyWidth = contentWidth * 0.37
            let valueWidth = contentWidth - keyWidth - 8
            let font = emphasized ? UIFont.systemFont(ofSize: 9.5, weight: .semibold) : bodyFont
            let keyRect = CGRect(x: margin, y: y, width: keyWidth, height: 16)
            let valueRect = CGRect(x: margin + keyWidth + 8, y: y, width: valueWidth, height: 16)
            draw(key, font: bodyFont, rect: keyRect, color: .darkGray)
            draw(value, font: font, rect: valueRect, alignment: .right)
            y += 17
        }

        private func line(_ text: String, font: UIFont, spacingAfter: CGFloat = 4) {
            ensureSpace(font.lineHeight + spacingAfter)
            let rect = CGRect(x: margin, y: y, width: contentWidth, height: font.lineHeight + 4)
            draw(text, font: font, rect: rect)
            y += font.lineHeight + spacingAfter
        }

        private func paragraph(_ text: String, font: UIFont, spacingAfter: CGFloat = 5) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.label
            ]
            let bounding = (text as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            ensureSpace(ceil(bounding.height) + spacingAfter)
            (text as NSString).draw(
                with: CGRect(x: margin, y: y, width: contentWidth, height: ceil(bounding.height) + 2),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            y += ceil(bounding.height) + spacingAfter
        }

        private func draw(
            _ text: String,
            font: UIFont,
            rect: CGRect,
            alignment: NSTextAlignment = .left,
            color: UIColor = .label
        ) {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = alignment
            paragraph.lineBreakMode = .byTruncatingTail
            (text as NSString).draw(
                in: rect,
                withAttributes: [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
            )
        }

        private func number(_ value: Double, decimals: Int) -> String {
            value.formatted(.number.precision(.fractionLength(decimals)))
        }

        private var reportDateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }
    }
}
