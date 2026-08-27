import Foundation
import Testing
@testable import SHKCore

struct HeizBalanceVDI3805PumpAdapterTests {
    @Test
    func convertsValidMappingIntoPumpDataset() throws {
        let mapped = makeMappedDataset()
        let dataset = try #require(mapped.convertedDataset())

        #expect(dataset.schema == HeizBalancePumpProductDataset.schemaVersion)
        #expect(dataset.manufacturer == "Beispiel Pumpen")
        #expect(dataset.products.count == 1)
        #expect(dataset.products[0].curves.count == 1)
        #expect(dataset.products[0].curves[0].points.count == 3)
        #expect(dataset.products[0].curves[0].points[1].headM == 3.8)
        #expect(dataset.source.rightsNote?.contains("VDI 3805 Blatt 4:2021-02") == true)
        #expect(dataset.isValid)
    }

    @Test
    func decoderDetectsVDI3805PumpMapping() throws {
        let mapped = makeMappedDataset()
        let data = try JSONEncoder().encode(mapped)
        let receipt = try HeizBalancePumpDatasetImportDecoder.decode(data: data)

        #expect(receipt.dataset.id == mapped.id)
        switch receipt.origin {
        case .vdi3805Mapped(let standardReference, let mappingProfileVersion):
            #expect(standardReference == "VDI 3805 Blatt 4:2021-02")
            #expect(mappingProfileVersion == "authorized-pump-converter-v1")
        case .native:
            Issue.record("Expected VDI 3805 mapped origin")
        }
    }

    @Test
    func nativeDatasetRejectsDuplicateFlowPoint() throws {
        var dataset = try #require(makeMappedDataset().convertedDataset())
        let duplicate = HeizBalancePumpProductDataset.CurvePoint(
            id: "p4",
            volumeFlowM3H: 1.0,
            headM: 3.7,
            electricalInputPowerW: 25
        )
        dataset.products[0].curves[0].points.append(duplicate)

        #expect(
            dataset.validationIssues.contains(
                .duplicateFlowPoint(
                    productID: "pump-1",
                    curveID: "curve-max",
                    flowM3H: 1.0
                )
            )
        )
    }

    @Test
    func rejectsWrongStandardPart() {
        var mapped = makeMappedDataset()
        mapped.standardReference = "VDI 3805 Blatt 22:2019-03"

        #expect(mapped.validationIssues.contains(.unsupportedStandardPart))
        #expect(mapped.convertedDataset() == nil)
    }

    @Test
    func rejectsCurveWithOnlyOnePoint() {
        var mapped = makeMappedDataset()
        mapped.products[0].curves[0].points = [mapped.products[0].curves[0].points[0]]

        #expect(mapped.validationIssues.contains(.invalidMappedProduct("pump-1")))
    }

    private func makeMappedDataset() -> HeizBalanceVDI3805PumpMappedDataset {
        .init(
            schema: HeizBalanceVDI3805PumpMappedDataset.schemaVersion,
            id: "example-vdi3805-pumps",
            manufacturer: "Beispiel Pumpen",
            datasetName: "Fiktiver Pumpen-Mapping-Test",
            datasetVersion: "2026-08-25",
            standardReference: "VDI 3805 Blatt 4:2021-02",
            mappingProfileVersion: "authorized-pump-converter-v1",
            source: .init(
                reference: "Fiktive Testquelle",
                url: nil,
                usageBasis: .userProvided,
                rightsNote: "Nur Testdaten"
            ),
            products: [
                .init(
                    id: "pump-1",
                    productName: "Umwälzpumpe Test",
                    series: "Testserie",
                    articleNumber: "PUMP-TEST-1",
                    sourceReference: nil,
                    originalRecordReference: "record-pump-1",
                    curves: [
                        .init(
                            id: "curve-max",
                            label: "Maximale Kennlinie",
                            controlMode: "Dokumentierter Testmodus",
                            speedRPM: 2800,
                            sourceReference: nil,
                            originalRecordReference: "curve-record-1",
                            points: [
                                .init(id: "p1", volumeFlowM3H: 0, headM: 5.0, electricalInputPowerW: 18, originalRecordReference: nil),
                                .init(id: "p2", volumeFlowM3H: 1.0, headM: 3.8, electricalInputPowerW: 25, originalRecordReference: nil),
                                .init(id: "p3", volumeFlowM3H: 2.0, headM: 1.8, electricalInputPowerW: 34, originalRecordReference: nil)
                            ]
                        )
                    ]
                )
            ]
        )
    }
}
