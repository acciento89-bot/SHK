import Foundation
import UIKit

struct HeizBalancePumpCurveReportPDFRenderer {
    static func render(_ snapshot: HeizBalancePumpCurveReportSnapshot) -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        return UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            Writer(context: context, bounds: bounds, snapshot: snapshot).render()
        }
    }

    private final class Writer {
        private let context: UIGraphicsPDFRendererContext
        private let bounds: CGRect
        private let snapshot: HeizBalancePumpCurveReportSnapshot
        private let margin: CGFloat = 42
        private let footerHeight: CGFloat = 34
        private var y: CGFloat = 0
        private var page = 0

        private let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        private let sectionFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        private let headingFont = UIFont.systemFont(ofSize: 9.5, weight: .semibold)
        private let bodyFont = UIFont.systemFont(ofSize: 8.5)
        private let smallFont = UIFont.systemFont(ofSize: 7.5)

        init(
            context: UIGraphicsPDFRendererContext,
            bounds: CGRect,
            snapshot: HeizBalancePumpCurveReportSnapshot
        ) {
            self.context = context
            self.bounds = bounds
            self.snapshot = snapshot
        }

        private var width: CGFloat { bounds.width - 2 * margin }
        private var bottom: CGFloat { bounds.height - margin - footerHeight }

        func render() {
            beginPage()
            line("Pumpenkennlinien & Betriebspunkt", font: titleFont, after: 4)
            paragraph(snapshot.notice, font: headingFont, after: 10)

            section("Berichtsprofil")
            keyValue("Projekt", snapshot.projectName)
            keyValue("Snapshot", snapshot.schema)
            keyValue("Rechenprofil", snapshot.calculationProfile)
            keyValue("Erzeugt", DateFormatter.pumpReportDate.string(from: snapshot.generatedAt))
            keyValue("Automatische Pumpenauswahl", snapshot.automaticPumpSelectionReleased ? "Freigegeben" : "Nicht freigegeben")

            section("Technischer Projekt-Betriebspunkt")
            if let operatingPoint = snapshot.operatingPoint {
                keyValue("Volumenstrom", number(operatingPoint.volumeFlowM3H, 3) + " m³/h")
                keyValue("Erforderliche Förderhöhe", number(operatingPoint.requiredHeadM, 2) + " m")
                paragraph("Kennlinien werden ausschließlich innerhalb ihres dokumentierten Volumenstrombereichs ausgewertet. Zwischenwerte sind lineare technische Zwischenwerte; außerhalb wird nicht extrapoliert.", font: smallFont, after: 8)
            } else {
                paragraph("Projekt-Betriebspunkt ist noch nicht vollständig berechenbar. Pumpenkennlinien werden deshalb nur dokumentiert, nicht bewertet.")
            }

            section("Festgehaltene Benutzerauswahl")
            if let selection = snapshot.selectedPump {
                keyValue("Auswahl-Snapshot", selection.schema)
                keyValue("Festgehalten", DateFormatter.pumpReportDate.string(from: selection.selectedAt))
                keyValue("Hersteller / Produkt", selection.displayName, bold: true)
                keyValue("Kennlinie", selection.curveLabel)
                if let mode = selection.controlMode, !mode.isEmpty {
                    keyValue("Regel-/Betriebsart", mode)
                }
                if let speed = selection.speedRPM {
                    keyValue("Drehzahl", number(speed, 0) + " 1/min")
                }
                if let article = selection.articleNumber, !article.isEmpty {
                    keyValue("Artikelnummer", article)
                }
                keyValue("Katalog / Datenstand", selection.datasetName + " · " + selection.datasetVersion)
                keyValue("Quelle", selection.sourceReference)
                keyValue("Nutzungsgrundlage", selection.usageBasis.title)
                keyValue("Rechenprofil bei Auswahl", selection.calculationProfile)
                keyValue("Volumenstrom bei Auswahl", number(selection.operatingPointVolumeFlowM3H, 3) + " m³/h")
                keyValue("Erforderliche Förderhöhe", number(selection.requiredHeadM, 2) + " m")
                keyValue("Kennlinien-Förderhöhe", number(selection.availableHeadM, 2) + " m")
                keyValue("Reserve bei Auswahl", number(selection.headReserveM, 2) + " m")
                if let power = selection.electricalInputPowerW {
                    keyValue("Elektrische Aufnahme", number(power, 1) + " W")
                }
                keyValue("Dokumentierte Kennlinienpunkte", "\(selection.documentedPoints.count)")
                keyValue(
                    "Bezug zum aktuellen Betriebspunkt",
                    snapshot.selectedPumpMatchesOperatingPoint == true
                        ? "Unverändert"
                        : "Neu zu bewerten – Betriebspunkt geändert oder unvollständig",
                    bold: true
                )
                paragraph("Diese Pumpe/Kennlinie wurde ausdrücklich durch den Benutzer festgehalten. Der Snapshot dokumentiert die damalige technische Bewertung; er ist keine automatische Empfehlung, Effizienzfreigabe oder Herstellerfreigabe.", font: smallFont, after: 8)
            } else {
                paragraph("Zum Exportzeitpunkt ist keine Pumpe/Kennlinie ausdrücklich als Projektauswahl festgehalten.")
            }

            if snapshot.datasets.isEmpty {
                section("Pumpenkataloge")
                paragraph("Keine Pumpenkataloge zum Exportzeitpunkt importiert. Eine oben dokumentierte festgehaltene Auswahl bleibt als eigener Projektsnapshot erhalten.")
                return
            }

            for dataset in snapshot.datasets {
                section("\(dataset.manufacturer) · \(dataset.datasetName)")
                keyValue("Datenstand", dataset.datasetVersion)
                keyValue("Quelle", dataset.sourceReference)
                keyValue("Nutzungsgrundlage", dataset.usageBasis.title)

                for product in dataset.products {
                    ensure(34)
                    line(product.displayName, font: headingFont, indent: 8, after: 2)
                    if let article = product.articleNumber, !article.isEmpty {
                        keyValue("Artikel", article, indent: 14)
                    }

                    for curve in product.curves {
                        render(curve: curve)
                    }
                }
            }
        }

        private func render(curve: HeizBalancePumpCurveReportSnapshot.CurveData) {
            ensure(48)
            line(curve.label, font: headingFont, indent: 16, after: 1)
            if let mode = curve.controlMode, !mode.isEmpty {
                keyValue("Regel-/Betriebsart", mode, indent: 22)
            }
            if let speed = curve.speedRPM {
                keyValue("Drehzahl", number(speed, 0) + " 1/min", indent: 22)
            }

            switch curve.status {
            case .evaluated:
                if let evaluation = curve.evaluation {
                    keyValue(
                        "Technischer Status",
                        evaluation.technicallySufficient ? "Betriebspunkt hydraulisch abgedeckt" : "Förderhöhe nicht ausreichend",
                        indent: 22,
                        bold: true
                    )
                    keyValue("Kennlinien-Förderhöhe", number(evaluation.availableHeadM, 2) + " m", indent: 22)
                    keyValue("Erforderliche Förderhöhe", number(evaluation.requiredHeadM, 2) + " m", indent: 22)
                    keyValue("Reserve", number(evaluation.headReserveM, 2) + " m", indent: 22)
                    if let power = evaluation.electricalInputPowerW {
                        keyValue("Elektrische Aufnahme", number(power, 1) + " W", indent: 22)
                    }
                    keyValue(
                        "Zwischenwert",
                        evaluation.exactDocumentedPoint
                            ? "Exakt dokumentierter Punkt \(evaluation.lowerPointID)"
                            : "Linear zwischen \(evaluation.lowerPointID) und \(evaluation.upperPointID)",
                        indent: 22
                    )
                }

            case .outsideDocumentedRange:
                keyValue("Technischer Status", "Nicht bewertbar – keine Extrapolation", indent: 22, bold: true)

            case .operatingPointUnavailable:
                keyValue("Technischer Status", "Projekt-Betriebspunkt unvollständig", indent: 22)
            }

            keyValue("Dokumentierte Punkte", "\(curve.points.count)", indent: 22)
            if let source = curve.sourceReference, !source.isEmpty {
                keyValue("Kennlinienquelle", source, indent: 22)
            }
            y += 4
        }

        private func beginPage() {
            context.beginPage()
            page += 1
            y = margin
            draw("HeizBalance · Pumpenkennlinien", font: smallFont, rect: CGRect(x: margin, y: 18, width: width, height: 12), color: .darkGray)
            draw("Seite \(page)", font: smallFont, rect: CGRect(x: margin, y: bounds.height - 25, width: width, height: 12), alignment: .right, color: .darkGray)
            draw("Technischer Vergleich · explizite Auswahl ≠ Empfehlung", font: smallFont, rect: CGRect(x: margin, y: bounds.height - 25, width: width - 60, height: 12), color: .darkGray)
        }

        private func ensure(_ height: CGFloat) {
            if y + height > bottom { beginPage() }
        }

        private func section(_ text: String) {
            ensure(28)
            y += 7
            line(text, font: sectionFont, after: 3)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: bounds.width - margin, y: y))
            UIColor.lightGray.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            y += 6
        }

        private func keyValue(_ key: String, _ value: String, indent: CGFloat = 0, bold: Bool = false) {
            let x = margin + indent
            let rowWidth = width - indent
            let keyWidth = max(145, rowWidth * 0.42)
            let valueWidth = rowWidth - keyWidth - 8
            let valueFont = bold ? headingFont : bodyFont
            let height = max(
                measured(key, font: bodyFont, width: keyWidth),
                measured(value, font: valueFont, width: valueWidth),
                10
            )
            ensure(height + 3)
            draw(key, font: bodyFont, rect: CGRect(x: x, y: y, width: keyWidth, height: height + 2), color: .darkGray)
            draw(value.isEmpty ? "—" : value, font: valueFont, rect: CGRect(x: x + keyWidth + 8, y: y, width: valueWidth, height: height + 2), alignment: .right)
            y += height + 3
        }

        private func line(_ text: String, font: UIFont, indent: CGFloat = 0, after: CGFloat = 3) {
            let lineWidth = width - indent
            let height = measured(text, font: font, width: lineWidth)
            ensure(height + after)
            draw(text, font: font, rect: CGRect(x: margin + indent, y: y, width: lineWidth, height: height + 2))
            y += height + after
        }

        private func paragraph(_ text: String, font: UIFont? = nil, after: CGFloat = 5) {
            let actual = font ?? bodyFont
            let height = measured(text, font: actual, width: width)
            ensure(height + after)
            draw(text, font: actual, rect: CGRect(x: margin, y: y, width: width, height: height + 3))
            y += height + after
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

        private func measured(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
            let style = NSMutableParagraphStyle()
            style.lineBreakMode = .byWordWrapping
            style.lineSpacing = 1
            return ceil(
                (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font, .paragraphStyle: style],
                    context: nil
                ).height
            )
        }

        private func number(_ value: Double, _ decimals: Int) -> String {
            value.formatted(.number.precision(.fractionLength(0...decimals)))
        }
    }
}

private extension DateFormatter {
    static let pumpReportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
