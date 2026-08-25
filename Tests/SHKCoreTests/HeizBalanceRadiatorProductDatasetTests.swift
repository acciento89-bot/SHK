import Foundation
import Testing
@testable import SHKCore

struct HeizBalanceRadiatorProductDatasetTests {
    @Test
    func decodesValidDocumentedDataset() throws {
        let json = #"""
        {
          "schema": "radiator-product-dataset-v1",
          "id": "demo-dataset-1",
          "manufacturer": "Demo Manufacturer",
          "datasetName": "Panel Radiators",
          "datasetVersion": "2026-08",
          "source": {
            "reference": "Authorized source reference",
            "url": "https://example.invalid/source",
            "usageBasis": "manufacturerAuthorized",
            "rightsNote": "Test only"
          },
          "products": [
            {
              "id": "p-1",
              "series": "Series A",
              "model": "Model 1",
              "kind": "panelRadiator",
              "nominalPowerDeltaT50W": 2700,
              "exponent": 1.3,
              "widthMM": 1000,
              "heightMM": 600,
              "depthMM": 105,
              "articleNumber": "A-1",
              "sourceReference": "Row 1"
            }
          ]
        }
        """#.data(using: .utf8)!

        let dataset = try JSONDecoder().decode(HeizBalanceRadiatorProductDataset.self, from: json)

        #expect(dataset.isValid)
        #expect(dataset.validationIssues.isEmpty)
        #expect(dataset.products.count == 1)
        #expect(dataset.products[0].displayName == "Series A · Model 1")
        #expect(dataset.products[0].matchingCandidate(datasetID: dataset.id).id == "demo-dataset-1::p-1")
    }

    @Test
    func rejectsMissingSourceAndInvalidProductValues() {
        let dataset = HeizBalanceRadiatorProductDataset(
            schema: HeizBalanceRadiatorProductDataset.schemaVersion,
            id: "dataset",
            manufacturer: "Manufacturer",
            datasetName: "Dataset",
            datasetVersion: "1",
            source: .init(
                reference: "",
                url: nil,
                usageBasis: .userProvided,
                rightsNote: nil
            ),
            products: [
                .init(
                    id: "bad",
                    series: "Series",
                    model: "Model",
                    kind: nil,
                    nominalPowerDeltaT50W: 0,
                    exponent: 1.3,
                    widthMM: -100,
                    heightMM: nil,
                    depthMM: nil,
                    articleNumber: nil,
                    sourceReference: nil
                )
            ]
        )

        #expect(!dataset.isValid)
        #expect(dataset.validationIssues.contains(.missingSourceReference))
        #expect(dataset.validationIssues.contains(.invalidProduct("bad")))
    }

    @Test
    func rejectsDuplicateAndReservedProductIdentifiers() {
        let product = HeizBalanceRadiatorProductDataset.Product(
            id: "p::1",
            series: "Series",
            model: "Model",
            kind: nil,
            nominalPowerDeltaT50W: 2000,
            exponent: 1.3,
            widthMM: nil,
            heightMM: nil,
            depthMM: nil,
            articleNumber: nil,
            sourceReference: nil
        )
        let dataset = HeizBalanceRadiatorProductDataset(
            schema: HeizBalanceRadiatorProductDataset.schemaVersion,
            id: "dataset",
            manufacturer: "Manufacturer",
            datasetName: "Dataset",
            datasetVersion: "1",
            source: .init(
                reference: "Reference",
                url: nil,
                usageBasis: .licensed,
                rightsNote: nil
            ),
            products: [product, product]
        )

        #expect(dataset.validationIssues.contains(.reservedSeparatorInProductID("p::1")))
        #expect(dataset.validationIssues.contains(.duplicateProductID("p::1")))
    }
}
