import Foundation
import UIKit

struct HeizBalanceAdjustmentListPDFRenderer {
    static func render(_ snapshot: HeizBalanceAdjustmentListSnapshot) -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            Writer(context: context, pageBounds: pageBounds, snapshot: snapshot).render()
        }
    }

    private final class Writer {
        private let context: UIGraphicsPDFRendererContext
        private let pageBounds: CGRect
        private let snapshot: HeizBalanceAdjustmentListSnapshot
        private let margin: CGFloat = 38
        private let footerHeight: CGFloat = 34
        private var y: CGFloat = 0
        private var pageNumber = 0

        private let titleFont = UIFont.systemFont(ofSize: 17, weight: .bold)
        private let sectionFont = UIFont.systemFont(ofSize: 11, weight: .bold)
        private let rowTitleFont = UIFont.systemFont(ofSize: 9, weight: .semibold)
        private let bodyFont = UIFont.systemFont(ofSize: 8, weight: .regular)
        private let smallFont = UIFont.systemFont(ofSize: 7.5, weight: .regular)
        private let smallBoldFont = UIFont.systemFont(ofSize: 7.5, weight: .semibold)

        init(
            context: UIGraphicsPDFRendererContext,
            pageBounds: CGRect,
            snapshot: HeizBalanceAdjustmentListSnapshot
        ) {
            self.context = context
            self.pageBounds = pageBounds
            self.snapshot = snapshot
        }

        private var contentWidth: CGFloat { pageBounds.width - margin * 2 }
        private var contentBottom: CGFloat { pageBounds.height - margin - footerHeight }

        func render() {
            beginPage()
            renderProjectHeader()
            renderSummary()
            renderPump()
            renderRows()
        }

        private func renderProjectHeader() {
            line("HeizBalance · Baustellen-Einstellliste", font: titleFont, spacingAfter: 5)
            line(snapshot.projectName, font: .systemFont(ofSize: 11, weight: .semibold), spacingAfter: 2)
            let meta = [snapshot.customerName, snapshot.address]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " · ")
            if !meta.isEmpty {
                paragraph(meta, font: bodyFont, color: .darkGray, spacingAfter: 5)
            }
            paragraph(snapshot.notice, font: bodyFont, color: .darkGray, spacingAfter: 9)
        }

        private func renderSummary() {
            section("Übersicht")
            let s = snapshot.summary
            paragraph(
                "Kreise: \(s.circuitCount) · Q vollständig: \(s.flowReadyCount)/\(s.circuitCount) · Δp vollständig: \(s.pressureReadyCount)/\(s.circuitCount)",
                font: bodyFont,
                spacingAfter: 3
            )
            paragraph(
                "Aktuelle Thermostateinstellungen: \(s.currentThermostatSettingCount) · Rücklauf: \(s.currentReturnSettingCount) · neu zu bewerten: \(s.staleValveSettingCount) · ohne festgehaltene Einstellung: \(s.valveWithoutHeldSettingCount)",
                font: bodyFont,
                spacingAfter: 8
            )
        }

        private func renderPump() {
            guard let pump = snapshot.pump else { return }
            section("Pumpe")
            paragraph(
                "\(pump.displayName) · Kennlinie \(pump.curveLabel) · Q \(pump.operatingPointVolumeFlowM3H.formatted(.number.precision(.fractionLength(0...3)))) m³/h · H erf. \(pump.requiredHeadM.formatted(.number.precision(.fractionLength(0...2)))) m · Reserve \(pump.headReserveM.formatted(.number.precision(.fractionLength(0...2)))) m",
                font: bodyFont,
                color: pump.selectionCurrent ? .black : .systemOrange,
                spacingAfter: 3
            )
            if !pump.selectionCurrent {
                paragraph("Pumpenauswahl: neu bewerten", font: smallBoldFont, color: .systemOrange, spacingAfter: 7)
            }
        }

        private func renderRows() {
            section("Heizflächenkreise")
            let floorNames = snapshot.rows.reduce(into: [String]()) { names, row in
                if !names.contains(row.floorName) { names.append(row.floorName) }
            }

            if floorNames.isEmpty {
                paragraph("Keine Heizflächenkreise erfasst.", font: bodyFont)
                return
            }

            for floorName in floorNames {
                ensureSpace(34)
                line(floorName, font: .systemFont(ofSize: 10, weight: .bold), spacingAfter: 5)
                for row in snapshot.rows where row.floorName == floorName {
                    render(row: row)
                }
            }
        }

        private func render(row: HeizBalanceAdjustmentListSnapshot.Row) {
            let estimated = estimatedHeight(for: row)
            if estimated < contentBottom - margin {
                ensureSpace(estimated)
            } else {
                ensureSpace(45)
            }

            line("\(row.roomName) · \(row.surfaceName)", font: rowTitleFont, spacingAfter: 2)
            let flow = row.targetVolumeFlowLPH.map {
                $0.formatted(.number.precision(.fractionLength(0))) + " l/h"
            } ?? "offen"
            let dp = row.completeCircuitPressureLossKPa.map {
                $0.formatted(.number.precision(.fractionLength(0...2))) + " kPa"
            } ?? "offen"
            line("Q: \(flow) · Kreis-Δp: \(dp)", font: bodyFont, spacingAfter: 2)

            for valve in row.thermostatSettings {
                renderValve(prefix: "TV", valve: valve)
            }
            for valve in row.returnSettings {
                renderValve(prefix: "RL", valve: valve)
            }

            if !row.missingNotes.isEmpty {
                paragraph(
                    "Offen: " + row.missingNotes.joined(separator: " · "),
                    font: smallFont,
                    color: .systemOrange,
                    spacingAfter: 4
                )
            }

            ensureSpace(8)
            let lineY = y + 2
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(0.4)
            context.cgContext.move(to: CGPoint(x: margin, y: lineY))
            context.cgContext.addLine(to: CGPoint(x: pageBounds.width - margin, y: lineY))
            context.cgContext.strokePath()
            y += 8
        }

        private func renderValve(
            prefix: String,
            valve: HeizBalanceAdjustmentListSnapshot.ValveEntry
        ) {
            let product = [valve.manufacturer, valve.productName]
                .compactMap { $0 }
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
            paragraph(
                "\(prefix) \(valve.componentName)\(productPart) · \(required) · \(held)",
                font: smallFont,
                color: color,
                indent: 8,
                spacingAfter: 2
            )
        }

        private func estimatedHeight(for row: HeizBalanceAdjustmentListSnapshot.Row) -> CGFloat {
            var height: CGFloat = 28
            for valve in row.thermostatSettings + row.returnSettings {
                let product = [valve.manufacturer, valve.productName].compactMap { $0 }.joined(separator: " ")
                let required = valve.requiredKvM3H.map { $0.formatted(.number.precision(.fractionLength(3))) } ?? "offen"
                let held = valve.heldSetting ?? "nicht festgehalten"
                let text = "TV \(valve.componentName) · \(product) · Soll-kv \(required) · Einstellung \(held)"
                height += measuredHeight(text, font: smallFont, width: contentWidth - 8) + 2
            }
            if !row.missingNotes.isEmpty {
                height += measuredHeight("Offen: " + row.missingNotes.joined(separator: " · "), font: smallFont, width: contentWidth) + 5
            }
            return height + 10
        }

        private func beginPage() {
            context.beginPage()
            pageNumber += 1
            y = 34
            draw(
                "HeizBalance · Baustellen-Einstellliste",
                font: smallBoldFont,
                rect: CGRect(x: margin, y: 16, width: contentWidth, height: 12),
                color: .darkGray
            )
            draw(
                "Technische Vorbereitung · \(snapshot.schema) · Seite \(pageNumber)",
                font: UIFont.systemFont(ofSize: 7),
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
            y += 5
            line(text, font: sectionFont, spacingAfter: 5)
        }

        private func line(
            _ text: String,
            font: UIFont,
            color: UIColor = .black,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 3
        ) {
            let width = contentWidth - indent
            let height = measuredHeight(text, font: font, width: width)
            ensureSpace(height + spacingAfter)
            draw(text, font: font, rect: CGRect(x: margin + indent, y: y, width: width, height: height + 2), color: color)
            y += height + spacingAfter
        }

        private func paragraph(
            _ text: String,
            font: UIFont,
            color: UIColor = .black,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 5
        ) {
            var words = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard !words.isEmpty else { return }
            let width = contentWidth - indent

            while !words.isEmpty {
                var available = contentBottom - y
                if available < font.lineHeight * 2 {
                    beginPage()
                    available = contentBottom - y
                }

                let full = words.joined(separator: " ")
                let fullHeight = measuredHeight(full, font: font, width: width)
                if fullHeight <= available {
                    draw(full, font: font, rect: CGRect(x: margin + indent, y: y, width: width, height: fullHeight + 3), color: color)
                    y += fullHeight + spacingAfter
                    break
                }

                var low = 1
                var high = words.count
                var best = 0
                while low <= high {
                    let mid = (low + high) / 2
                    let candidate = words.prefix(mid).joined(separator: " ")
                    if measuredHeight(candidate, font: font, width: width) <= available {
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
                let chunkHeight = measuredHeight(chunk, font: font, width: width)
                draw(chunk, font: font, rect: CGRect(x: margin + indent, y: y, width: width, height: chunkHeight + 3), color: color)
                words.removeFirst(best)
                if !words.isEmpty {
                    beginPage()
                } else {
                    y += chunkHeight + spacingAfter
                }
            }
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
