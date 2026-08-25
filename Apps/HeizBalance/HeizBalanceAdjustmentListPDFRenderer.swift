import Foundation
import UIKit

struct HeizBalanceAdjustmentListPDFRenderer {
    static func render(_ snapshot: HeizBalanceAdjustmentListSnapshot) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            let margin: CGFloat = 38
            let contentWidth = pageRect.width - margin * 2
            var y: CGFloat = 0
            var page = 0

            func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
                let rect = (text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font],
                    context: nil
                )
                return ceil(rect.height)
            }

            @discardableResult
            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor = .black,
                x: CGFloat = margin,
                width: CGFloat = contentWidth,
                spacing: CGFloat = 3
            ) -> CGFloat {
                let height = textHeight(text, font: font, width: width)
                (text as NSString).draw(
                    in: CGRect(x: x, y: y, width: width, height: height + 2),
                    withAttributes: [.font: font, .foregroundColor: color]
                )
                y += height + spacing
                return height
            }

            func drawFooter() {
                let footer = "HeizBalance · technische Vorbereitung · keine Verfahren-B-/GEG-/BEG-/Herstellerfreigabe · Seite \(page)"
                let font = UIFont.systemFont(ofSize: 7)
                (footer as NSString).draw(
                    in: CGRect(x: margin, y: pageRect.height - 28, width: contentWidth, height: 12),
                    withAttributes: [.font: font, .foregroundColor: UIColor.darkGray]
                )
            }

            func startPage() {
                if page > 0 { drawFooter() }
                context.beginPage()
                page += 1
                y = 34
                drawText("HeizBalance · Baustellen-Einstellliste", font: .boldSystemFont(ofSize: 17), spacing: 5)
                drawText(snapshot.projectName, font: .boldSystemFont(ofSize: 11), spacing: 2)
                let meta = [snapshot.customerName, snapshot.address]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: " · ")
                if !meta.isEmpty {
                    drawText(meta, font: .systemFont(ofSize: 8), color: .darkGray, spacing: 5)
                }
                y += 4
            }

            func ensureSpace(_ height: CGFloat) {
                if y + height > pageRect.height - 46 {
                    startPage()
                }
            }

            startPage()

            drawText(
                snapshot.notice,
                font: .systemFont(ofSize: 8),
                color: .darkGray,
                spacing: 7
            )

            ensureSpace(65)
            drawText("Übersicht", font: .boldSystemFont(ofSize: 11), spacing: 4)
            let s = snapshot.summary
            drawText(
                "Kreise: \(s.circuitCount) · Q vollständig: \(s.flowReadyCount)/\(s.circuitCount) · Δp vollständig: \(s.pressureReadyCount)/\(s.circuitCount)",
                font: .systemFont(ofSize: 8)
            )
            drawText(
                "Aktuelle Thermostateinstellungen: \(s.currentThermostatSettingCount) · Rücklauf: \(s.currentReturnSettingCount) · neu zu bewerten: \(s.staleValveSettingCount) · ohne festgehaltene Einstellung: \(s.valveWithoutHeldSettingCount)",
                font: .systemFont(ofSize: 8),
                spacing: 7
            )

            if let pump = snapshot.pump {
                ensureSpace(48)
                drawText("Pumpe", font: .boldSystemFont(ofSize: 10), spacing: 3)
                drawText(
                    "\(pump.displayName) · Kennlinie \(pump.curveLabel) · Q \(pump.operatingPointVolumeFlowM3H.formatted(.number.precision(.fractionLength(0...3)))) m³/h · H erf. \(pump.requiredHeadM.formatted(.number.precision(.fractionLength(0...2)))) m · Reserve \(pump.headReserveM.formatted(.number.precision(.fractionLength(0...2)))) m",
                    font: .systemFont(ofSize: 8),
                    color: pump.selectionCurrent ? .black : .systemOrange
                )
                if !pump.selectionCurrent {
                    drawText("Pumpenauswahl: neu bewerten", font: .boldSystemFont(ofSize: 8), color: .systemOrange, spacing: 6)
                }
            }

            drawText("Heizflächenkreise", font: .boldSystemFont(ofSize: 11), spacing: 5)

            for row in snapshot.rows {
                let valveLineCount = row.thermostatSettings.count + row.returnSettings.count
                let estimated = CGFloat(42 + valveLineCount * 18 + max(1, row.missingNotes.count) * 10)
                ensureSpace(min(estimated, 180))

                let title = "\(row.floorName) · \(row.roomName) · \(row.surfaceName)"
                drawText(title, font: .boldSystemFont(ofSize: 9), spacing: 2)

                let flow = row.targetVolumeFlowLPH.map {
                    $0.formatted(.number.precision(.fractionLength(0))) + " l/h"
                } ?? "offen"
                let dp = row.completeCircuitPressureLossKPa.map {
                    $0.formatted(.number.precision(.fractionLength(0...2))) + " kPa"
                } ?? "offen"
                drawText("Q: \(flow) · Kreis-Δp: \(dp)", font: .systemFont(ofSize: 8), spacing: 2)

                for valve in row.thermostatSettings {
                    drawValve("TV", valve: valve, drawText: drawText)
                }
                for valve in row.returnSettings {
                    drawValve("RL", valve: valve, drawText: drawText)
                }

                if !row.missingNotes.isEmpty {
                    drawText(
                        "Offen: " + row.missingNotes.joined(separator: " · "),
                        font: .systemFont(ofSize: 7.5),
                        color: .systemOrange,
                        spacing: 3
                    )
                }

                let lineY = y + 2
                context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                context.cgContext.setLineWidth(0.4)
                context.cgContext.move(to: CGPoint(x: margin, y: lineY))
                context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: lineY))
                context.cgContext.strokePath()
                y += 7
            }

            drawFooter()
        }
    }

    private static func drawValve(
        _ prefix: String,
        valve: HeizBalanceAdjustmentListSnapshot.ValveEntry,
        drawText: (String, UIFont, UIColor, CGFloat, CGFloat, CGFloat) -> CGFloat
    ) {
        let product = [valve.manufacturer, valve.productName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let required = valve.requiredKvM3H.map {
            "Soll-kv " + $0.formatted(.number.precision(.fractionLength(3)))
        } ?? "Soll-kv offen"
        let held: String
        let color: UIColor
        if let setting = valve.heldSetting, let kv = valve.heldKvM3H {
            held = "Einstellung \(setting) · kv \(kv.formatted(.number.precision(.fractionLength(3))))"
            color = valve.selectionCurrent == false ? .systemOrange : .black
        } else {
            held = "Einstellung nicht festgehalten"
            color = .systemOrange
        }
        let productPart = product.isEmpty ? "" : " · " + product
        _ = drawText("\(prefix) \(valve.componentName)\(productPart) · \(required) · \(held)", .systemFont(ofSize: 7.5), color, 38, 519.2, 2)
    }
}
