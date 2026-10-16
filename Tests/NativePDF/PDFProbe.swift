import Foundation
import UIKit
import PDFKit

@MainActor func verifyPDF() throws {
    let first = "ANLAGE LINDENWEG · ΔT 10 K · 3,14 l · 45 °C"
    let last = "ENDE-DES-LETZTEN-BEFUNDS-7391"
    let body = first + "\n" + (1...240).map { "Messpunkt \($0): 1,4 bar · Herstellerdaten, tatsächliche Messungen und Quellenangabe prüfen. Vorlauf45°C; Rücklauf35°C." }.joined(separator: "\n") + "\n" + last
    let url = try SuitePDF.write(text: body, title: "Haus Lindenweg")
    guard let document = PDFDocument(url: url), let text = document.string else { fatalError("PDF_NOT_READABLE") }
    precondition(document.pageCount >= 3, "LONG_REPORT_DID_NOT_PAGINATE")
    precondition(text.contains("ANLAGE LINDENWEG"), "FIRST_FINDING_LOST")
    precondition(text.contains(last), "LAST_FINDING_TRUNCATED")
    precondition(text.contains("ΔT") && text.contains("3,14") && text.contains("°C"), "TECHNICAL_UNITS_LOST")
    precondition(text.contains("Messpunkt 240"), "REPORT_ENTRIES_TRUNCATED")
    print("SUITE_NATIVE_PDF_PASS pages=\(document.pageCount) path=\(url.path)")
    try FileManager.default.removeItem(at: url)
}
@main struct PDFProbe { @MainActor static func main() throws { try verifyPDF() } }
