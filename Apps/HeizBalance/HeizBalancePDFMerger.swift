import Foundation
import PDFKit

enum HeizBalancePDFMerger {
    static func merge(_ documents: [Data]) -> Data? {
        let output = PDFDocument()

        for data in documents {
            guard let document = PDFDocument(data: data) else { return nil }
            for index in 0..<document.pageCount {
                guard let page = document.page(at: index) else { return nil }
                output.insert(page, at: output.pageCount)
            }
        }

        guard output.pageCount > 0 else { return nil }
        return output.dataRepresentation()
    }
}
