import Foundation
import Testing
@testable import SHKCore

struct HeizBalanceVDI3805ValveAdapterTests {
    @Test
    func convertsValidMappingIntoValveDataset() throws {
        let mapped = makeMappedDataset()
        let dataset = try #require(mapped.convertedDataset())

        #expect(dataset.schema == HeizBalanceValveProductDataset.schemaVersion)
        #expect(dataset.manufacturer == "Beispiel Armaturen")
        #expect(dataset.products.count == 1)
        #expect(dataset.products[0].presetPoints.count == 3)
        #expect(dataset.products[0].presetPoints[1].kvM3H == 0.35)
        #expect(dataset.source.rightsNote?.contains("VDI 3805 Blatt 2:2021-12") == true)
        #expect(dataset.isValid)
    }

    @Test
    func decoderDetectsVDI3805ValveMapping() throws {
        let mapped = makeMappedDataset()
        let data = try JSONEncoder().encode(mapped)
        let receipt = try HeizBalanceValveDatasetImportDecoder.decode(data: data)

        #expect(receipt.dataset.id == mapped.id)
        switch receipt.origin {
        case .vdi3805Mapped(let standardReference, let mappingProfileVersion):
            #expect(standardReference == "VDI 3805 Blatt 2:2021-12")
            #expect(mappingProfileVersion == "authorized-valve-converter-v1")
        case .native:
            Issue.record("Expected VDI 3805 mapped origin")
        }
    }

    @Test
    func projectProductDataKeepsCatalogProvenance() throws {
        let dataset = try #require(makeMappedDataset().convertedDataset())
        let product = try #require(dataset.products.first)
        let projectData = product.projectProductData(dataset: dataset)

        #expect(projectData.manufacturer == dataset.manufacturer)
        #expect(projectData.datasetID == dataset.id)
        #expect(projectData.productID == product.id)
        #expect(projectData.articleNumber == "VALVE-TEST-1")
        #expect(projectData.usageBasis == HeizBalanceValveProductDataset.UsageBasis.userProvided.rawValue)
        #expect(projectData.presetPoints.count == 3)
    }

    @Test
    func rejectsWrongStandardPart() {
        var mapped = makeMappedDataset()
        mapped.standardReference = "VDI 3805 Blatt 6:2022-01"

        #expect(mapped.validationIssues.contains(.unsupportedStandardPart))
        #expect(mapped.convertedDataset() == nil)
    }

    @Test
    func rejectsDuplicatePresetSettingsInNativeDataset() throws {
        var dataset = try #require(makeMappedDataset().convertedDataset())
        dataset.products[0].presetPoints.append(
            .init(id: "duplicate", setting: "2", kvM3H: 0.4)
        )

        #expect(
            dataset.validationIssues.contains(
                .duplicatePresetSetting(productID: "valve-1", setting: "2")
            )
        )
    }

    private func makeMappedDataset() -> HeizBalanceVDI3805ValveMappedDataset {
        .init(
            schema: HeizBalanceVDI3805ValveMappedDataset.schemaVersion,
            id: "example-vdi3805-valves",
            manufacturer: "Beispiel Armaturen",
            datasetName: "Fiktiver Armaturen-Mapping-Test",
            datasetVersion: "2026-08-25",
            standardReference: "VDI 3805 Blatt 2:2021-12",
            mappingProfileVersion: "authorized-valve-converter-v1",
            source: .init(
                reference: "Fiktive Testquelle",
                url: nil,
                usageBasis: .userProvided,
                rightsNote: "Nur Testdaten"
            ),
            products: [
                .init(
                    id: "valve-1",
                    productName: "Thermostatventil Test",
                    kind: "Thermostatventil",
                    articleNumber: "VALVE-TEST-1",
                    sourceReference: nil,
                    originalRecordReference: "record-valve-1",
                    presetPoints: [
                        .init(id: "p1", setting: "1", kvM3H: 0.2, originalRecordReference: nil),
                        .init(id: "p2", setting: "2", kvM3H: 0.35, originalRecordReference: nil),
                        .init(id: "p3", setting: "3", kvM3H: 0.5, originalRecordReference: nil)
                    ]
                )
            ]
        )
    }
}
