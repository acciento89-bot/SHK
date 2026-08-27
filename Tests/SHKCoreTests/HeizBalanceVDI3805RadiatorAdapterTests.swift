import Foundation
import Testing
@testable import SHKCore

struct HeizBalanceVDI3805RadiatorAdapterTests {
    @Test
    func convertsValidMappedDatasetIntoNativeDataset() throws {
        let mapped = makeMappedDataset()
        let native = try #require(mapped.convertedDataset())

        #expect(native.schema == HeizBalanceRadiatorProductDataset.schemaVersion)
        #expect(native.manufacturer == "Beispiel Hersteller")
        #expect(native.products.count == 1)
        #expect(native.products[0].nominalPowerDeltaT50W == 2500)
        #expect(native.products[0].sourceReference == "record-4711")
        #expect(native.source.rightsNote?.contains("VDI 3805 Blatt 6:2022-01") == true)
        #expect(native.isValid)
    }

    @Test
    func importDecoderDetectsVDI3805MappingEnvelope() throws {
        let mapped = makeMappedDataset()
        let data = try JSONEncoder().encode(mapped)
        let receipt = try HeizBalanceRadiatorDatasetImportDecoder.decode(data: data)

        #expect(receipt.dataset.id == mapped.id)
        #expect(receipt.dataset.products.first?.model == "22-600-1200")

        switch receipt.origin {
        case .vdi3805Mapped(let standardReference, let mappingProfileVersion):
            #expect(standardReference == "VDI 3805 Blatt 6:2022-01")
            #expect(mappingProfileVersion == "licensed-converter-v1")
        case .native:
            Issue.record("Expected VDI 3805 mapped origin")
        }
    }

    @Test
    func importDecoderStillAcceptsNativeDataset() throws {
        let mapped = makeMappedDataset()
        let native = try #require(mapped.convertedDataset())
        let data = try JSONEncoder().encode(native)
        let receipt = try HeizBalanceRadiatorDatasetImportDecoder.decode(data: data)

        #expect(receipt.dataset == native)
        #expect(receipt.origin == .native)
    }

    @Test
    func rejectsWrongStandardPart() {
        var mapped = makeMappedDataset()
        mapped.standardReference = "VDI 3805 Blatt 22:2019-03"

        #expect(mapped.validationIssues.contains(.unsupportedStandardPart))
        #expect(mapped.convertedDataset() == nil)
    }

    @Test
    func rejectsMappedProductWithInvalidDimensions() {
        var mapped = makeMappedDataset()
        mapped.products[0].widthMM = -1200

        #expect(mapped.validationIssues.contains(.invalidProduct("product-1")))
    }

    @Test
    func importDecoderRejectsUnknownSchema() throws {
        let data = try #require("{\"schema\":\"unknown-v9\"}".data(using: .utf8))

        do {
            _ = try HeizBalanceRadiatorDatasetImportDecoder.decode(data: data)
            Issue.record("Expected unsupported schema error")
        } catch let error as HeizBalanceRadiatorDatasetImportDecoder.ImportError {
            #expect(error == .unsupportedSchema("unknown-v9"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private func makeMappedDataset() -> HeizBalanceVDI3805RadiatorMappedDataset {
        .init(
            schema: HeizBalanceVDI3805RadiatorMappedDataset.schemaVersion,
            id: "example-vdi3805-radiators",
            manufacturer: "Beispiel Hersteller",
            datasetName: "Fiktiver Mapping-Test",
            datasetVersion: "2026-08-25",
            standardReference: "VDI 3805 Blatt 6:2022-01",
            mappingProfileVersion: "licensed-converter-v1",
            source: .init(
                reference: "Fiktive Testquelle",
                url: nil,
                usageBasis: .userProvided,
                rightsNote: "Nur Testdaten"
            ),
            products: [
                .init(
                    id: "product-1",
                    series: "Testserie",
                    model: "22-600-1200",
                    kind: "Plattenheizkörper",
                    nominalPowerDeltaT50W: 2500,
                    exponent: 1.3,
                    widthMM: 1200,
                    heightMM: 600,
                    depthMM: 102,
                    articleNumber: "TEST-4711",
                    sourceReference: nil,
                    originalRecordReference: "record-4711"
                )
            ]
        )
    }
}
