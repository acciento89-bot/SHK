import Foundation
import UIKit
import CoreText

@MainActor enum SuitePDF {
    enum ExportError: Error { case cannotLayOutText }
    /// CoreText paginates the actual UTF-16 text range; no fixed-line truncation.
    static func write(text: String, title: String) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 4
        let ink = UIColor(red: 0.10, green: 0.18, blue: 0.21, alpha: 1)
        let teal = UIColor(red: 0.02, green: 0.42, blue: 0.43, alpha: 1)
        let attributed = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: ink, .paragraphStyle: paragraph])
        let setter = CTFramesetterCreateWithAttributedString(attributed)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator as String: "SHK Werkstatt", kCGPDFContextTitle as String: title]
        var failed = false
        let data = UIGraphicsPDFRenderer(bounds: page, format: format).pdfData { context in
            var offset = 0, pageNumber = 0
            repeat {
                context.beginPage(); pageNumber += 1
                "SHK WERKSTATT".draw(at: CGPoint(x: 44, y: 30), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: teal])
                let header = NSMutableParagraphStyle(); header.lineBreakMode = .byTruncatingTail
                title.draw(in: CGRect(x: 44, y: 49, width: page.width-88, height: 26), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 19), .foregroundColor: ink, .paragraphStyle: header])
                context.cgContext.setStrokeColor(teal.withAlphaComponent(0.35).cgColor)
                context.cgContext.setLineWidth(0.7); context.cgContext.move(to: CGPoint(x: 44, y: 86)); context.cgContext.addLine(to: CGPoint(x: page.width-44, y: 86)); context.cgContext.strokePath()
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: page.height); context.cgContext.scaleBy(x: 1, y: -1)
                let body = CGPath(rect: CGRect(x: 44, y: 56, width: page.width-88, height: page.height-160), transform: nil)
                let frame = CTFramesetterCreateFrame(setter, CFRange(location: offset, length: 0), body, nil)
                CTFrameDraw(frame, context.cgContext)
                let visible = CTFrameGetVisibleStringRange(frame)
                context.cgContext.restoreGState()
                String(pageNumber).draw(at: CGPoint(x: page.width-56, y: page.height-35), withAttributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: ink])
                guard visible.length > 0 || attributed.length == 0 else { failed = true; break }
                offset += visible.length
            } while offset < attributed.length
        }
        guard !failed else { throw ExportError.cannotLayOutText }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SHK-Projekt-\(UUID().uuidString).pdf")
        try data.write(to: url, options: .atomic)
        return url
    }
}
