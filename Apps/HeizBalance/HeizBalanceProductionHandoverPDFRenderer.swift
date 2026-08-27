import Foundation
import UIKit

struct HeizBalanceProductionHandoverPDFRenderer {
    static func render(_ snapshot: HeizBalanceProductionHandoverSnapshot) -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            Writer(context: context, pageBounds: pageBounds, snapshot: snapshot).render()
        }
    }

    private final class Writer {
        private let context: UIGraphicsPDFRendererContext
        private let pageBounds: CGRect
        private let snapshot: HeizBalanceProductionHandoverSnapshot
        private let margin: CGFloat = 42
        private let footerHeight: CGFloat = 36
        private var y: CGFloat = 0
        private var pageNumber = 0

        private let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        private let sectionFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        private let bodyFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        private let smallFont = UIFont.systemFont(ofSize: 8, weight: .regular)
        private let smallBoldFont = UIFont.systemFont(ofSize: 8, weight: .semibold)

        init(
            context: UIGraphicsPDFRendererContext,
            pageBounds: CGRect,
            snapshot: HeizBalanceProductionHandoverSnapshot
        ) {
            self.context = context
            self.pageBounds = pageBounds
            self.snapshot = snapshot
        }

        private var contentWidth: CGFloat { pageBounds.width - 2 * margin }
        private var contentBottom: CGFloat { pageBounds.height - margin - footerHeight }

        func render() {
            beginPage()
            line("HeizBalance", font: titleFont, spacingAfter: 2)
            line("Technische Übergabe-Zusammenfassung", font: .systemFont(ofSize: 14, weight: .semibold), spacingAfter: 10)
            paragraph(snapshot.notice, font: smallFont, color: .darkGray, spacingAfter: 12)

            section("Projekt & Verantwortliche")
            keyValue("Projekt", snapshot.projectName)
            keyValue("Kunde / Auftraggeber", snapshot.customerName)
            keyValue("Adresse", snapshot.address)
            keyValue("Firma / Betrieb", snapshot.documentation.companyName)
            keyValue("Techniker vor Ort", snapshot.documentation.technicianName)
            keyValue("Bearbeiter / Ersteller", snapshot.documentation.preparedBy)
            keyValue("Projektstatus", snapshot.documentation.projectStatusTitle, emphasized: true)
            keyValue("Bericht erzeugt", DateFormatter.heizBalanceProductionDate.string(from: snapshot.generatedAt))
            if let executionDate = snapshot.documentation.executionDate {
                keyValue("Ausführung / Ortstermin", DateFormatter.heizBalanceProductionDay.string(from: executionDate))
            }
            keyValue("Übergabe an", snapshot.documentation.handoverRecipient)

            section("Kompakte technische Übersicht")
            let s = snapshot.summary
            keyValue("Geschosse", "\(s.floorCount)")
            keyValue("Räume", "\(s.roomCount)")
            keyValue("Wärmeverlust-Vorbereitung vollständig", "\(s.heatLossReadyRoomCount) / \(s.roomCount)")
            keyValue("Heizflächenkreise", "\(s.heatingSurfaceCount)")
            keyValue("Ziel-Volumenstrom verfügbar", "\(s.targetFlowReadyCount) / \(s.heatingSurfaceCount)")
            keyValue("Vollständiger Kreis-Δp", "\(s.circuitPressureReadyCount) / \(s.heatingSurfaceCount)")
            keyValue("Aktuelle Ventileinstellungen", "\(s.currentValveSettingCount)")
            keyValue("Ventileinstellungen neu bewerten", "\(s.staleValveSettingCount)")
            keyValue("Ventile ohne festgehaltene Einstellung", "\(s.valveWithoutHeldSettingCount)")
            keyValue("Festgehaltene Pumpe", s.pumpSelectionPresent ? "Ja" : "Nein")
            if let current = s.pumpSelectionCurrent {
                keyValue("Pumpenauswahl aktuell", current ? "Ja" : "Neu bewerten")
            }
            keyValue("Offene technische Punkte", "\(s.openTechnicalItemCount)", emphasized: s.openTechnicalItemCount > 0)

            if !snapshot.floors.isEmpty {
                section("Projektumfang nach Geschoss")
                for floor in snapshot.floors {
                    ensureSpace(26)
                    line(floor.name, font: smallBoldFont, spacingAfter: 1)
                    keyValue("Räume", "\(floor.roomCount)", indent: 10)
                    keyValue("Heizflächen", "\(floor.heatingSurfaceCount)", indent: 10)
                    keyValue("Wärmeverlust vollständig", "\(floor.heatLossReadyRoomCount) / \(floor.roomCount)", indent: 10)
                }
            }

            if !snapshot.documentation.handoverNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                section("Übergabehinweis / Restpunkte")
                paragraph(snapshot.documentation.handoverNote, spacingAfter: 10)
            }

            renderSignatureArea()
        }

        private func renderSignatureArea() {
            ensureSpace(170)
            section("Übergabe / Unterschriften")
            paragraph(
                "Die Unterschrift bestätigt ausschließlich die Übergabe bzw. Kenntnisnahme des dokumentierten technischen Arbeitsstands. Sie stellt keine automatische Norm-, Verfahren-B-, GEG-/BEG-, Förder- oder Herstellerfreigabe dar.",
                font: smallFont,
                color: .darkGray,
                spacingAfter: 24
            )

            let leftX = margin
            let rightX = margin + contentWidth * 0.53
            let columnWidth = contentWidth * 0.43
            drawSignatureLine(x: leftX, width: columnWidth)
            drawSignatureLine(x: rightX, width: columnWidth)
            y += 5

            let technicianLabel = snapshot.documentation.signaturePrintedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Techniker / Bearbeiter"
                : "Techniker / Bearbeiter · \(snapshot.documentation.signaturePrintedName)"
            draw(technicianLabel, font: smallFont, rect: CGRect(x: leftX, y: y, width: columnWidth, height: 20), color: .darkGray)

            let recipientLabel = snapshot.documentation.handoverRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Auftraggeber / Empfänger"
                : "Auftraggeber / Empfänger · \(snapshot.documentation.handoverRecipient)"
            draw(recipientLabel, font: smallFont, rect: CGRect(x: rightX, y: y, width: columnWidth, height: 20), color: .darkGray)
            y += 34

            drawSignatureLine(x: leftX, width: columnWidth)
            drawSignatureLine(x: rightX, width: columnWidth)
            y += 5
            draw("Ort / Datum", font: smallFont, rect: CGRect(x: leftX, y: y, width: columnWidth, height: 18), color: .darkGray)
            draw("Ort / Datum", font: smallFont, rect: CGRect(x: rightX, y: y, width: columnWidth, height: 18), color: .darkGray)

            if !snapshot.documentation.signaturePlace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                y += 20
                paragraph("Vorgesehener Ort: \(snapshot.documentation.signaturePlace)", font: smallFont, color: .darkGray)
            }
        }

        private func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = margin

            draw(
                "HeizBalance · Übergabe-Zusammenfassung",
                font: smallBoldFont,
                rect: CGRect(x: margin, y: 18, width: contentWidth, height: 14),
                color: .darkGray
            )
            draw(
                "Technische Vorbereitung · \(snapshot.schema) · Seite \(pageNumber)",
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
            y += 8
            line(text, font: sectionFont, spacingAfter: 6)
        }

        private func keyValue(
            _ key: String,
            _ value: String,
            indent: CGFloat = 0,
            emphasized: Bool = false
        ) {
            let rowX = margin + indent
            let rowWidth = contentWidth - indent
            let keyWidth = max(150, rowWidth * 0.46)
            let valueWidth = rowWidth - keyWidth - 8
            let valueText = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value
            let valueFont = emphasized ? smallBoldFont : smallFont
            let height = max(
                11,
                measuredHeight(key, font: smallFont, width: keyWidth),
                measuredHeight(valueText, font: valueFont, width: valueWidth)
            )
            ensureSpace(height + 4)
            draw(key, font: smallFont, rect: CGRect(x: rowX, y: y, width: keyWidth, height: height + 2), color: .darkGray)
            draw(valueText, font: valueFont, rect: CGRect(x: rowX + keyWidth + 8, y: y, width: valueWidth, height: height + 2), alignment: .right)
            y += height + 4
        }

        private func line(_ text: String, font: UIFont, spacingAfter: CGFloat = 3) {
            let height = measuredHeight(text, font: font, width: contentWidth)
            ensureSpace(height + spacingAfter)
            draw(text, font: font, rect: CGRect(x: margin, y: y, width: contentWidth, height: height + 2))
            y += height + spacingAfter
        }

        private func paragraph(
            _ text: String,
            font: UIFont? = nil,
            color: UIColor = .black,
            spacingAfter: CGFloat = 5
        ) {
            let actualFont = font ?? bodyFont
            var words = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard !words.isEmpty else { return }

            while !words.isEmpty {
                var available = contentBottom - y
                if available < actualFont.lineHeight * 2 {
                    beginPage()
                    available = contentBottom - y
                }

                let full = words.joined(separator: " ")
                let fullHeight = measuredHeight(full, font: actualFont, width: contentWidth)
                if fullHeight <= available {
                    draw(full, font: actualFont, rect: CGRect(x: margin, y: y, width: contentWidth, height: fullHeight + 3), color: color)
                    y += fullHeight + spacingAfter
                    break
                }

                var low = 1
                var high = words.count
                var best = 0
                while low <= high {
                    let mid = (low + high) / 2
                    let candidate = words.prefix(mid).joined(separator: " ")
                    if measuredHeight(candidate, font: actualFont, width: contentWidth) <= available {
                        best = mid
                        low = mid + 1
                    } else {
                        high = mid - 1
                    }
                }

                if best == 0 {
                    beginPage()
                    continue
                }

                let chunk = words.prefix(best).joined(separator: " ")
                let chunkHeight = measuredHeight(chunk, font: actualFont, width: contentWidth)
                draw(chunk, font: actualFont, rect: CGRect(x: margin, y: y, width: contentWidth, height: chunkHeight + 3), color: color)
                words.removeFirst(best)
                if !words.isEmpty {
                    beginPage()
                } else {
                    y += chunkHeight + spacingAfter
                }
            }
        }

        private func drawSignatureLine(x: CGFloat, width: CGFloat) {
            context.cgContext.setStrokeColor(UIColor.darkGray.cgColor)
            context.cgContext.setLineWidth(0.6)
            context.cgContext.move(to: CGPoint(x: x, y: y))
            context.cgContext.addLine(to: CGPoint(x: x + width, y: y))
            context.cgContext.strokePath()
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
            style.lineSpacing = 1
            (text as NSString).draw(
                with: rect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style],
                context: nil
            )
        }

        private func measuredHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byWordWrapping
            style.lineSpacing = 1
            let rect = (text as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font, .paragraphStyle: style],
                context: nil
            )
            return ceil(rect.height)
        }
    }
}

private extension DateFormatter {
    static let heizBalanceProductionDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let heizBalanceProductionDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
