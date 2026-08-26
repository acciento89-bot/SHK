import Foundation
import UIKit

struct HeizBalanceHydraulicNetworkReportPDFRenderer {
    static func render(_ snapshot: HeizBalanceHydraulicNetworkReportSnapshot) -> Data {
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: page)

        return renderer.pdfData { context in
            let margin: CGFloat = 38
            let width = page.width - margin * 2
            var y: CGFloat = 0
            var pageNumber = 0

            func height(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
                ceil((text as NSString).boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font],
                    context: nil
                ).height)
            }

            func draw(_ text: String, font: UIFont, color: UIColor = .black, indent: CGFloat = 0, spacing: CGFloat = 3) {
                let actualWidth = width - indent
                let h = height(text, font: font, width: actualWidth)
                if y + h + spacing > page.height - 48 {
                    beginPage()
                }
                (text as NSString).draw(
                    in: CGRect(x: margin + indent, y: y, width: actualWidth, height: h + 2),
                    withAttributes: [.font: font, .foregroundColor: color]
                )
                y += h + spacing
            }

            func footer() {
                let text = "HeizBalance · hydraulischer Netzbaum / Pfade · technische Vorbereitung · Seite \(pageNumber)"
                (text as NSString).draw(
                    in: CGRect(x: margin, y: page.height - 27, width: width, height: 12),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 7), .foregroundColor: UIColor.darkGray]
                )
            }

            func beginPage() {
                if pageNumber > 0 { footer() }
                context.beginPage()
                pageNumber += 1
                y = 34
                draw("HeizBalance · Hydraulischer Netzbaum", font: .boldSystemFont(ofSize: 16), spacing: 2)
                draw(snapshot.projectName, font: .boldSystemFont(ofSize: 10), color: .darkGray, spacing: 7)
            }

            beginPage()
            draw(snapshot.notice, font: .systemFont(ofSize: 8), color: .darkGray, spacing: 8)
            draw("Status", font: .boldSystemFont(ofSize: 11), spacing: 4)
            draw("Q-Profil: \(snapshot.profileVersion)", font: .systemFont(ofSize: 8))
            draw("Netz gültig: \(snapshot.networkValid ? "Ja" : "Nein") · Verbraucher zugeordnet: \(snapshot.assignedConsumerCount)/\(snapshot.consumerCount) · veraltete Legacy-Verknüpfungen: \(snapshot.staleLinkedPipeCount)", font: .systemFont(ofSize: 8), spacing: 3)

            if snapshot.centralPathModeActive == true {
                let profile = snapshot.pathProfileVersion ?? "—"
                let owned = snapshot.segmentOwnedPipeCount ?? 0
                let linked = snapshot.centralLinkedPipeCount ?? 0
                let legacy = snapshot.unlinkedLegacySharedPipeCount ?? 0
                draw("Pfadprofil: \(profile) · direkt am Segment: \(owned) · Legacy verknüpft: \(linked) · Legacy/manuell: \(legacy)", font: .systemFont(ofSize: 8), color: (linked + legacy) > 0 ? .systemOrange : .black, spacing: 8)
            } else {
                draw("Zentraler Shared-Edge-/Pfadmodus: nicht aktiv – noch keine gemeinsame Segmentgeometrie", font: .systemFont(ofSize: 8), color: .darkGray, spacing: 8)
            }

            draw("Segmente", font: .boldSystemFont(ofSize: 11), spacing: 5)
            if snapshot.segments.isEmpty {
                draw("Keine Netzsegmente erfasst.", font: .systemFont(ofSize: 8), color: .darkGray, spacing: 8)
            }

            for segment in snapshot.segments.sorted(by: { lhs, rhs in
                if lhs.depth == rhs.depth { return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending }
                return lhs.depth < rhs.depth
            }) {
                let indent = CGFloat(min(segment.depth, 6)) * 12
                draw(segment.name, font: .boldSystemFont(ofSize: 9), indent: indent, spacing: 1)
                let parent = segment.parentName.map { " · übergeordnet: \($0)" } ?? " · Wurzel"
                draw("direkt \(segment.directConsumers.count) · nachgelagert \(segment.downstreamConsumerCount)\(parent)", font: .systemFont(ofSize: 7.5), color: .darkGray, indent: indent + 8, spacing: 1)
                let flow = segment.designVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen (bekannt: " + segment.knownVolumeFlowLPH.formatted(.number.precision(.fractionLength(0...1))) + " l/h)"
                draw("Segment-Q: \(flow)", font: .systemFont(ofSize: 8), color: segment.designVolumeFlowLPH == nil ? .systemOrange : .black, indent: indent + 8, spacing: 1)

                if snapshot.centralPathModeActive == true {
                    let pipeCount = segment.centralPipeSectionCount ?? 0
                    let ownedCount = segment.segmentOwnedPipeSectionCount ?? 0
                    if let complete = segment.completePressureLossKPa {
                        draw("Rohrabschnitte gesamt: \(pipeCount) · direkt im Segment: \(ownedCount) · Segment-Δp: \(complete.formatted(.number.precision(.fractionLength(0...3)))) kPa", font: .systemFont(ofSize: 8), indent: indent + 8, spacing: 1)
                    } else {
                        let known = segment.knownPressureLossKPa ?? 0
                        draw("Rohrabschnitte gesamt: \(pipeCount) · direkt im Segment: \(ownedCount) · Segment-Δp unvollständig · bekannt: \(known.formatted(.number.precision(.fractionLength(0...3)))) kPa", font: .systemFont(ofSize: 8), color: .systemOrange, indent: indent + 8, spacing: 1)
                    }
                }

                if !segment.directConsumers.isEmpty {
                    draw("Direkte Verbraucher: " + segment.directConsumers.joined(separator: " · "), font: .systemFont(ofSize: 7.5), indent: indent + 8, spacing: 1)
                }
                if !segment.unresolvedConsumers.isEmpty {
                    draw("Q offen: " + segment.unresolvedConsumers.joined(separator: " · "), font: .systemFont(ofSize: 7.5), color: .systemOrange, indent: indent + 8, spacing: 1)
                }
                if !segment.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    draw(segment.note, font: .systemFont(ofSize: 7.5), color: .darkGray, indent: indent + 8, spacing: 3)
                } else {
                    y += 3
                }
            }

            if snapshot.centralPathModeActive == true {
                draw("Verbraucherpfade", font: .boldSystemFont(ofSize: 11), spacing: 5)
                let paths = snapshot.consumerPaths ?? []
                if paths.isEmpty {
                    draw("Keine vollständige Pfadauswertung verfügbar.", font: .systemFont(ofSize: 8), color: .systemOrange, spacing: 6)
                }
                for path in paths {
                    draw(path.displayName, font: .boldSystemFont(ofSize: 8.5), spacing: 1)
                    let chain = path.pathSegmentNames.isEmpty ? "keinem Segment zugeordnet" : path.pathSegmentNames.joined(separator: " → ")
                    draw("Pfad: \(chain)", font: .systemFont(ofSize: 7.5), color: path.pathSegmentNames.isEmpty ? .systemOrange : .darkGray, indent: 8, spacing: 1)
                    let shared = path.knownSharedPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))
                    let terminal = path.terminalKnownPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))
                    let known = path.knownPathPressureLossKPa.formatted(.number.precision(.fractionLength(0...3)))
                    if let complete = path.completePathPressureLossKPa {
                        draw("Shared \(shared) kPa + terminal \(terminal) kPa = Kreis \(complete.formatted(.number.precision(.fractionLength(0...3)))) kPa", font: .systemFont(ofSize: 7.5), indent: 8, spacing: 4)
                    } else {
                        draw("Shared bekannt \(shared) kPa + terminal bekannt \(terminal) kPa = bekannt \(known) kPa · vollständiger Kreis-Δp offen", font: .systemFont(ofSize: 7.5), color: .systemOrange, indent: 8, spacing: 4)
                    }
                }
            }

            if !snapshot.linkedPipes.isEmpty {
                draw("Verknüpfte Legacy-Rohrabschnitte", font: .boldSystemFont(ofSize: 11), spacing: 5)
                for pipe in snapshot.linkedPipes {
                    draw("\(pipe.floorName) · \(pipe.roomName) · \(pipe.surfaceName) · \(pipe.pipeName)", font: .boldSystemFont(ofSize: 8), spacing: 1)
                    let stored = pipe.storedVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen"
                    let calculated = pipe.calculatedVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen"
                    draw("Segment \(pipe.segmentName) · Altformat unter Heizfläche · gespeichert \(stored) · aktuell berechnet \(calculated) · \(pipe.current ? "aktuell" : "neu synchronisieren")", font: .systemFont(ofSize: 7.5), color: pipe.current ? .systemOrange : .systemOrange, indent: 8, spacing: 4)
                }
                draw("Diese Altabschnitte bleiben rechenbar, können aber ohne Geometrieverlust in die Segmentstruktur migriert werden.", font: .systemFont(ofSize: 8), color: .systemOrange, spacing: 5)
            }

            if let legacy = snapshot.unlinkedLegacySharedPipeCount,
               snapshot.centralPathModeActive == true,
               legacy > 0 {
                draw("Hinweis: \(legacy) unverknüpfte Legacy-Shared-Rohrabschnitt(e) bleiben im Projekt erhalten, werden im zentralen Pfadmodus aber nicht zusätzlich gezählt.", font: .systemFont(ofSize: 8), color: .systemOrange, spacing: 5)
            }

            footer()
        }
    }
}
