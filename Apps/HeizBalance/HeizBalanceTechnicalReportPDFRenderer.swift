import Foundation
import UIKit

struct HeizBalanceTechnicalReportPDFRenderer {
    static func render(_ snapshot: HeizBalanceTechnicalReportSnapshot) -> Data {
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
        private let snapshot: HeizBalanceTechnicalReportSnapshot
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
            snapshot: HeizBalanceTechnicalReportSnapshot
        ) {
            self.context = context
            self.pageBounds = pageBounds
            self.snapshot = snapshot
        }

        func render() {
            beginPage()
            renderCoverAndProject()
            renderHydraulicSystem()

            for floor in snapshot.floors {
                section("Geschoss: \(floor.name)")
                if floor.rooms.isEmpty {
                    paragraph("Keine Räume erfasst.")
                }

                for room in floor.rooms {
                    render(room: room)
                }
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

            let header = "HeizBalance · Technischer Projektbericht"
            draw(
                header,
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
                "Technische Vorbereitung · kein freigegebener Norm-/Verfahren-B-Nachweis",
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

        private func renderCoverAndProject() {
            ensureSpace(120)
            line("HeizBalance", font: titleFont, spacingAfter: 2)
            line("Technischer Projektbericht", font: UIFont.systemFont(ofSize: 14, weight: .semibold), spacingAfter: 10)

            paragraph(snapshot.status.notice, font: headingFont, spacingAfter: 14)

            section("Projekt")
            keyValue("Projekt", snapshot.project.name)
            keyValue("Kunde / Auftraggeber", snapshot.project.customerName)
            keyValue("Adresse", snapshot.project.address)
            keyValue("Baujahr", snapshot.project.buildingYear)
            keyValue("Berichtsschema", snapshot.schema)
            keyValue("Erzeugt", DateFormatter.reportDate.string(from: snapshot.generatedAt))

            section("Auslegungsbedingungen")
            keyValue("Auslegungs-Außentemperatur", format(snapshot.project.designOutdoorTemperatureC, unit: "°C"))
            keyValue("Quelle Außentemperatur", sourceTitle(snapshot.project.designOutdoorTemperatureSource))
            keyValue(
                "Systemtemperaturen",
                temperaturePair(
                    flow: snapshot.project.designFlowTemperatureC,
                    returnTemperature: snapshot.project.designReturnTemperatureC
                )
            )
            keyValue("Quelle Systemtemperaturen", sourceTitle(snapshot.project.systemTemperatureSource))
            keyValue("Fluiddichte", format(snapshot.project.hydraulicFluidDensityKGPerM3, unit: "kg/m³", decimals: 1))
            keyValue("Kinematische Viskosität", format(snapshot.project.hydraulicKinematicViscosityMM2S, unit: "mm²/s", decimals: 3))
            keyValue("Quelle Fluidwerte", sourceTitle(snapshot.project.hydraulicFluidSource))

            if !snapshot.project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                section("Projektnotizen")
                paragraph(snapshot.project.notes)
            }
        }

        private func renderHydraulicSystem() {
            section("Hydrauliksystem")

            guard let system = snapshot.hydraulicSystem else {
                paragraph("Noch keine hydraulischen Heizflächenkreise berechenbar.")
                return
            }

            keyValue("Heizflächenkreise", "\(system.circuitCount)")
            keyValue("Volumenstrom vollständig", "\(system.knownFlowCircuitCount) / \(system.circuitCount)")
            keyValue("Kreis-Δp vollständig", "\(system.completePressureCircuitCount) / \(system.circuitCount)")
            keyValue("Bekannter Gesamtvolumenstrom", format(system.knownTotalVolumeFlowLPH, unit: "l/h", decimals: 0))
            keyValue("Auslegungs-Gesamtvolumenstrom", format(system.designTotalVolumeFlowLPH, unit: "l/h", decimals: 0))
            keyValue("Hydraulisch ungünstigster Kreis", system.unfavorableCircuitName ?? "—")
            keyValue("Erforderliches Netz-Δp", format(system.designNetworkPressureLossKPa, unit: "kPa", decimals: 2))
            keyValue("Äquivalente Förderhöhe", format(system.designNetworkHeadMeters, unit: "m", decimals: 2))
            keyValue("Technischer Betriebspunkt vollständig", system.pumpOperatingPointReady ? "Ja" : "Nein")
            keyValue("Pumpenauswahl freigegeben", system.pumpSelectionReleased ? "Ja" : "Nein")

            paragraph(
                "Für Parallelkreise wird der Gesamtvolumenstrom aus den Verbraucherströmen gebildet. Der maßgebende Netz-Druckverlust stammt aus dem hydraulisch ungünstigsten vollständigen Kreis; Parallelkreis-Druckverluste werden nicht addiert.",
                font: smallFont,
                spacingAfter: 10
            )
        }

        private func render(room: HeizBalanceTechnicalReportSnapshot.RoomData) {
            ensureSpace(95)
            subsection("Raum: \(room.name)\(room.roomNumber.isEmpty ? "" : " · Nr. \(room.roomNumber)")")
            keyValue(
                "Abmessungen",
                "\(number(room.lengthM, 2)) × \(number(room.widthM, 2)) × \(number(room.heightM, 2)) m"
            )
            keyValue("Grundfläche", format(room.floorAreaM2, unit: "m²", decimals: 2))
            keyValue("Raumvolumen", format(room.volumeM3, unit: "m³", decimals: 2))
            keyValue("Solltemperatur", format(room.targetTemperatureC, unit: "°C", decimals: 1))
            keyValue("Luftwechsel", format(room.airChangeRatePerHour, unit: "1/h", decimals: 2))
            keyValue("Quelle Luftwechsel", sourceTitle(room.airChangeSource))

            if let heatLoss = room.heatLoss {
                keyValue("Transmission technisch", format(heatLoss.transmissionHeatLossW, unit: "W", decimals: 0))
                keyValue("Lüftung technisch", format(heatLoss.ventilationHeatLossW, unit: "W", decimals: 0))
                keyValue("Raumsumme technisch", format(heatLoss.totalHeatLossW, unit: "W", decimals: 0), emphasized: true)
            } else {
                paragraph("Technische Wärmeverlust-Vorbereitung unvollständig.", font: headingFont)
                for missing in room.missingHeatLossInputs {
                    bullet(missing)
                }
            }

            if !room.components.isEmpty {
                subheading("Thermische Bauteile")
                for component in room.components {
                    ensureSpace(36)
                    line(component.name, font: headingFont, spacingAfter: 1)
                    keyValue("Art", component.kind, indent: 10)
                    keyValue("Fläche", format(component.areaM2, unit: "m²", decimals: 2), indent: 10)
                    keyValue("U-Wert", format(component.uValueWPerM2K, unit: "W/(m²·K)", decimals: 3), indent: 10)
                    keyValue("Quelle U-Wert", sourceTitle(component.uValueSource), indent: 10)
                    keyValue("Randbedingung", component.thermalBoundary, indent: 10)
                    if let temperature = component.customBoundaryTemperatureC {
                        keyValue("Temperatur Gegenseite", format(temperature, unit: "°C", decimals: 1), indent: 10)
                    }
                    if !component.note.isEmpty {
                        paragraph(component.note, font: smallFont, indent: 10, spacingAfter: 4)
                    }
                }
            }

            if room.heatingSurfaces.isEmpty {
                paragraph("Keine Heizflächen erfasst.", font: smallFont, spacingAfter: 10)
            } else {
                subheading("Heizflächen und Hydraulik")
                for surface in room.heatingSurfaces {
                    render(surface: surface)
                }
            }
        }

        private func render(surface: HeizBalanceTechnicalReportSnapshot.HeatingSurfaceData) {
            ensureSpace(95)
            line(surface.name, font: headingFont, spacingAfter: 1)
            let product = [surface.manufacturer, surface.model]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " · ")
            if !product.isEmpty {
                paragraph(product, font: smallFont, indent: 10, spacingAfter: 3)
            }

            keyValue("Art", surface.kind, indent: 10)
            keyValue("Nennleistung ΔT50", format(surface.nominalPowerDeltaT50W, unit: "W", decimals: 0), indent: 10)
            keyValue("Exponent n", format(surface.exponent, unit: "", decimals: 3), indent: 10)
            keyValue("Quelle Leistung", sourceTitle(surface.powerSource), indent: 10)
            keyValue("Zugeordnete erforderliche Leistung", format(surface.assignedRequiredPowerW, unit: "W", decimals: 0), indent: 10)
            keyValue("Verfügbare Leistung technisch", format(surface.availablePowerW, unit: "W", decimals: 0), indent: 10)
            keyValue("Ziel-Volumenstrom", format(surface.targetVolumeFlowLPH, unit: "l/h", decimals: 0), indent: 10)

            if !surface.pipeSections.isEmpty {
                paragraph("Rohrabschnitte", font: smallBoldFont, indent: 10, spacingAfter: 3)
                for pipe in surface.pipeSections {
                    ensureSpace(42)
                    line(pipe.name, font: smallBoldFont, indent: 18, spacingAfter: 1)
                    keyValue("Rolle", pipe.role, indent: 22)
                    keyValue("Verwendeter Volumenstrom", format(pipe.volumeFlowLPH, unit: "l/h", decimals: 0), indent: 22)
                    keyValue("Innendurchmesser", format(pipe.innerDiameterMM, unit: "mm", decimals: 2), indent: 22)
                    keyValue("Hydraulische Länge", format(pipe.lengthM, unit: "m", decimals: 2), indent: 22)
                    keyValue("Rauheit", format(pipe.roughnessMM, unit: "mm", decimals: 4), indent: 22)
                    keyValue("ζ-Summe", format(pipe.zetaTotal, unit: "", decimals: 3), indent: 22)
                    keyValue("Geschwindigkeit", format(pipe.velocityMS, unit: "m/s", decimals: 3), indent: 22)
                    keyValue("Reynolds-Zahl", format(pipe.reynoldsNumber, unit: "", decimals: 0), indent: 22)
                    keyValue("Rohrreibung", format(pipe.pressureDropPaPerM, unit: "Pa/m", decimals: 0), indent: 22)
                    keyValue("Gerader Rohrverlust", format(pipe.straightPressureLossKPa, unit: "kPa", decimals: 3), indent: 22)
                    keyValue("Lokaler Verlust", format(pipe.localPressureLossKPa, unit: "kPa", decimals: 3), indent: 22)
                }
            }

            if !surface.hydraulicComponents.isEmpty {
                paragraph("Hydraulische Bauteile", font: smallBoldFont, indent: 10, spacingAfter: 3)
                for component in surface.hydraulicComponents {
                    render(hydraulicComponent: component)
                }
            }

            if let circuit = surface.circuit {
                ensureSpace(52)
                paragraph("Kreiszusammenfassung", font: smallBoldFont, indent: 10, spacingAfter: 3)
                keyValue("Bekannter Rohrverlust", format(circuit.knownPipePressureLossKPa, unit: "kPa", decimals: 3), indent: 18)
                keyValue("Bekannte Bauteilverluste", format(circuit.knownComponentPressureLossKPa, unit: "kPa", decimals: 3), indent: 18)
                keyValue("Bekannte Kreissumme", format(circuit.knownCircuitPressureLossKPa, unit: "kPa", decimals: 3), indent: 18)
                keyValue("Vollständiger Kreis-Δp", format(circuit.completeCircuitPressureLossKPa, unit: "kPa", decimals: 3), indent: 18, emphasized: true)
                keyValue("Rohrweg vollständig", circuit.pipeCoverageComplete ? "Ja" : "Nein", indent: 18)
                keyValue("Bauteilaufnahme vollständig", circuit.componentCoverageComplete ? "Ja" : "Nein", indent: 18)
            }

            if !surface.note.isEmpty {
                paragraph(surface.note, font: smallFont, indent: 10, spacingAfter: 8)
            } else {
                y += 6
            }
        }

        private func render(hydraulicComponent: HeizBalanceTechnicalReportSnapshot.HydraulicComponentData) {
            ensureSpace(40)
            line(hydraulicComponent.name, font: smallBoldFont, indent: 18, spacingAfter: 1)
            keyValue("Art", hydraulicComponent.kind, indent: 22)
            keyValue("Δp", format(hydraulicComponent.pressureLossKPa, unit: "kPa", decimals: 3), indent: 22)
            keyValue("Quelle Δp", sourceTitle(hydraulicComponent.source), indent: 22)
            keyValue("Erforderlicher kv", format(hydraulicComponent.requiredKvM3H, unit: "m³/h", decimals: 3), indent: 22)

            if let valve = hydraulicComponent.valveProductData {
                paragraph("Dokumentierter Ventildatensatz", font: smallBoldFont, indent: 22, spacingAfter: 2)
                keyValue("Hersteller", valve.manufacturer, indent: 28)
                keyValue("Produkt", valve.productName, indent: 28)
                keyValue("Datenstand", valve.dataSetVersion, indent: 28)
                keyValue("Quelle / Referenz", valve.sourceReference, indent: 28)

                for point in valve.points {
                    keyValue(
                        "Voreinstellung \(point.setting.isEmpty ? "—" : point.setting)",
                        format(point.kvM3H, unit: "m³/h", decimals: 3),
                        indent: 28
                    )
                }

                if let comparison = valve.comparison {
                    keyValue("Unterer Datenpunkt", presetText(comparison.lowerSetting, comparison.lowerKvM3H), indent: 28)
                    keyValue("Oberer Datenpunkt", presetText(comparison.upperSetting, comparison.upperKvM3H), indent: 28)
                    keyValue(
                        "Technisch nächster Datenpunkt",
                        presetText(comparison.nearestSetting, comparison.nearestKvM3H),
                        indent: 28,
                        emphasized: true
                    )
                    keyValue("Abweichung zum Soll-kv", format(comparison.relativeDeviation * 100, unit: "%", decimals: 1), indent: 28)
                    keyValue("Soll-kv im Datenbereich", comparison.requiredKvInsideDataRange ? "Ja" : "Nein", indent: 28)
                    keyValue("Automatische Voreinstellung freigegeben", comparison.automaticPresetReleased ? "Ja" : "Nein", indent: 28)
                }
            }

            if !hydraulicComponent.note.isEmpty {
                paragraph(hydraulicComponent.note, font: smallFont, indent: 22, spacingAfter: 3)
            }
        }

        private func section(_ text: String) {
            ensureSpace(32)
            y += 8
            line(text, font: sectionFont, spacingAfter: 4)
            divider()
        }

        private func subsection(_ text: String) {
            ensureSpace(28)
            y += 5
            line(text, font: UIFont.systemFont(ofSize: 11.5, weight: .bold), spacingAfter: 4)
        }

        private func subheading(_ text: String) {
            ensureSpace(24)
            y += 4
            line(text, font: UIFont.systemFont(ofSize: 10, weight: .bold), spacingAfter: 3)
        }

        private func divider() {
            ensureSpace(8)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: y))
            path.addLine(to: CGPoint(x: pageBounds.width - margin, y: y))
            UIColor.lightGray.setStroke()
            path.lineWidth = 0.5
            path.stroke()
            y += 7
        }

        private func bullet(_ text: String) {
            paragraph("• \(text)", font: smallFont, indent: 10, spacingAfter: 1)
        }

        private func keyValue(
            _ key: String,
            _ value: String,
            indent: CGFloat = 0,
            emphasized: Bool = false
        ) {
            ensureSpace(18)
            let rowX = margin + indent
            let rowWidth = contentWidth - indent
            let keyWidth = max(150, rowWidth * 0.43)
            let valueWidth = rowWidth - keyWidth - 8
            let keyHeight = measuredHeight(key, font: smallFont, width: keyWidth)
            let valueFont = emphasized ? smallBoldFont : smallFont
            let valueHeight = measuredHeight(value, font: valueFont, width: valueWidth)
            let height = max(11, keyHeight, valueHeight)
            ensureSpace(height + 3)

            draw(
                key,
                font: smallFont,
                rect: CGRect(x: rowX, y: y, width: keyWidth, height: height + 2),
                color: .darkGray
            )
            draw(
                value.isEmpty ? "—" : value,
                font: valueFont,
                rect: CGRect(x: rowX + keyWidth + 8, y: y, width: valueWidth, height: height + 2),
                alignment: .right
            )
            y += height + 3
        }

        private func line(
            _ text: String,
            font: UIFont,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 3
        ) {
            let width = contentWidth - indent
            let height = measuredHeight(text, font: font, width: width)
            ensureSpace(height + spacingAfter)
            draw(
                text,
                font: font,
                rect: CGRect(x: margin + indent, y: y, width: width, height: height + 2)
            )
            y += height + spacingAfter
        }

        private func paragraph(
            _ text: String,
            font: UIFont? = nil,
            indent: CGFloat = 0,
            spacingAfter: CGFloat = 5
        ) {
            let actualFont = font ?? bodyFont
            let width = contentWidth - indent
            let height = measuredHeight(text, font: actualFont, width: width)
            ensureSpace(height + spacingAfter)
            draw(
                text,
                font: actualFont,
                rect: CGRect(x: margin + indent, y: y, width: width, height: height + 3)
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
            style.lineSpacing = 1

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

        private func sourceTitle(_ rawValue: String?) -> String {
            guard let rawValue,
                  let source = HeizBalanceInputSource(rawValue: rawValue) else {
                return "—"
            }
            return source.title
        }

        private func format(_ value: Double?, unit: String, decimals: Int = 2) -> String {
            guard let value, value.isFinite else { return "—" }
            return format(value, unit: unit, decimals: decimals)
        }

        private func format(_ value: Double, unit: String, decimals: Int = 2) -> String {
            guard value.isFinite else { return "—" }
            let valueText = number(value, decimals)
            return unit.isEmpty ? valueText : "\(valueText) \(unit)"
        }

        private func number(_ value: Double, _ decimals: Int) -> String {
            value.formatted(.number.precision(.fractionLength(0...decimals)))
        }

        private func temperaturePair(flow: Double?, returnTemperature: Double?) -> String {
            guard let flow, let returnTemperature else { return "—" }
            return "\(number(flow, 1)) / \(number(returnTemperature, 1)) °C"
        }

        private func presetText(_ setting: String?, _ kv: Double?) -> String {
            guard let setting, let kv else { return "—" }
            return "\(setting) · kv \(number(kv, 3)) m³/h"
        }
    }
}

private extension DateFormatter {
    static let reportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
