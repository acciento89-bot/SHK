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
                let text = "HeizBalance · hydraulischer Netzbaum · technische Vorbereitung · Seite \(pageNumber)"
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
            draw("Profil: \(snapshot.profileVersion)", font: .systemFont(ofSize: 8))
            draw("Netz gültig: \(snapshot.networkValid ? "Ja" : "Nein") · Verbraucher zugeordnet: \(snapshot.assignedConsumerCount)/\(snapshot.consumerCount) · veraltete Rohrverknüpfungen: \(snapshot.staleLinkedPipeCount)", font: .systemFont(ofSize: 8), spacing: 8)

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

            draw("Verknüpfte gemeinsame Rohrabschnitte", font: .boldSystemFont(ofSize: 11), spacing: 5)
            if snapshot.linkedPipes.isEmpty {
                draw("Keine Rohrabschnitte mit Netzsegment verknüpft.", font: .systemFont(ofSize: 8), color: .darkGray)
            }
            for pipe in snapshot.linkedPipes {
                draw("\(pipe.floorName) · \(pipe.roomName) · \(pipe.surfaceName) · \(pipe.pipeName)", font: .boldSystemFont(ofSize: 8), spacing: 1)
                let stored = pipe.storedVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen"
                let calculated = pipe.calculatedVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen"
                draw("Segment \(pipe.segmentName) · gespeichert \(stored) · aktuell berechnet \(calculated) · \(pipe.current ? "aktuell" : "neu synchronisieren")", font: .systemFont(ofSize: 7.5), color: pipe.current ? .black : .systemOrange, indent: 8, spacing: 4)
            }

            footer()
        }
    }
}
