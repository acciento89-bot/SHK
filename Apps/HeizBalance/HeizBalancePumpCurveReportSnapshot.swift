import Foundation

struct HeizBalancePumpCurveReportSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-pump-curves-v1"

    var schema: String
    var calculationProfile: String
    var technicalMetricsProfile: String?
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var operatingPoint: OperatingPointData?
    var automaticPumpSelectionReleased: Bool
    var notice: String
    var datasets: [DatasetData]
    var selectedPump: HeizBalancePumpSelection?
    var selectedPumpMatchesOperatingPoint: Bool?

    struct OperatingPointData: Codable, Hashable {
        var volumeFlowM3H: Double
        var requiredHeadM: Double
        var fluidDensityKGPerM3: Double?
        var requiredHydraulicPowerW: Double?
    }

    struct DatasetData: Codable, Hashable, Identifiable {
        var id: String
        var manufacturer: String
        var datasetName: String
        var datasetVersion: String
        var sourceReference: String
        var sourceURL: String?
        var usageBasis: HeizBalancePumpProductDataset.UsageBasis
        var rightsNote: String?
        var products: [ProductData]
    }

    struct ProductData: Codable, Hashable, Identifiable {
        var id: String
        var productName: String
        var series: String?
        var articleNumber: String?
        var sourceReference: String?
        var curves: [CurveData]

        var displayName: String {
            [series, productName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
        }
    }

    struct CurveData: Codable, Hashable, Identifiable {
        var id: String
        var label: String
        var controlMode: String?
        var speedRPM: Double?
        var sourceReference: String?
        var status: EvaluationStatus
        var evaluation: EvaluationData?
        var points: [PointData]
    }

    enum EvaluationStatus: String, Codable, Hashable {
        case evaluated
        case operatingPointUnavailable
        case outsideDocumentedRange
    }

    struct EvaluationData: Codable, Hashable {
        var availableHeadM: Double
        var requiredHeadM: Double
        var headReserveM: Double
        var technicallySufficient: Bool
        var electricalInputPowerW: Double?
        var lowerPointID: String
        var upperPointID: String
        var exactDocumentedPoint: Bool
        var requiredHydraulicPowerW: Double?
        var availableHydraulicPowerW: Double?
        var headReservePercent: Double?
        var requiredHydraulicToElectricalRatio: Double?
        var documentedFlowPosition: Double?
    }

    struct PointData: Codable, Hashable, Identifiable {
        var id: String
        var volumeFlowM3H: Double
        var headM: Double
        var electricalInputPowerW: Double?
    }
}

extension HeizBalanceProject {
    @MainActor
    func pumpCurveReportSnapshot(
        datasets: [HeizBalancePumpProductDataset],
        generatedAt: Date = Date()
    ) -> HeizBalancePumpCurveReportSnapshot {
        let hydraulic = hydraulicSystemPreparationState().result
        let operatingPoint: HeizBalancePumpCurveReportSnapshot.OperatingPointData?

        if let hydraulic,
           hydraulic.pumpOperatingPointReady,
           let volumeFlowLPH = hydraulic.designTotalVolumeFlowLPH,
           let requiredHeadM = hydraulic.designNetworkHeadMeters {
            let volumeFlowM3H = volumeFlowLPH / 1_000
            let requiredHydraulicPowerW: Double?
            if let density = hydraulicFluidDensityKGPerM3 {
                requiredHydraulicPowerW = HeizBalancePumpTechnicalMetricsCalculator.calculate(
                    .init(
                        volumeFlowM3H: volumeFlowM3H,
                        requiredHeadM: requiredHeadM,
                        availableHeadM: requiredHeadM,
                        fluidDensityKGPerM3: density,
                        electricalInputPowerW: nil,
                        documentedMinimumFlowM3H: nil,
                        documentedMaximumFlowM3H: nil
                    )
                )?.requiredHydraulicPowerW
            } else {
                requiredHydraulicPowerW = nil
            }

            operatingPoint = .init(
                volumeFlowM3H: volumeFlowM3H,
                requiredHeadM: requiredHeadM,
                fluidDensityKGPerM3: hydraulicFluidDensityKGPerM3,
                requiredHydraulicPowerW: requiredHydraulicPowerW
            )
        } else {
            operatingPoint = nil
        }

        let heldSelection = HeizBalancePumpSelectionStore.shared.selection(projectID: id)
        let heldSelectionMatchesOperatingPoint: Bool?
        if let heldSelection {
            if let operatingPoint {
                heldSelectionMatchesOperatingPoint = heldSelection.matchesOperatingPoint(
                    volumeFlowM3H: operatingPoint.volumeFlowM3H,
                    requiredHeadM: operatingPoint.requiredHeadM
                )
            } else {
                heldSelectionMatchesOperatingPoint = false
            }
        } else {
            heldSelectionMatchesOperatingPoint = nil
        }

        let datasetData = datasets.map { dataset in
            HeizBalancePumpCurveReportSnapshot.DatasetData(
                id: dataset.id,
                manufacturer: dataset.manufacturer,
                datasetName: dataset.datasetName,
                datasetVersion: dataset.datasetVersion,
                sourceReference: dataset.source.reference,
                sourceURL: dataset.source.url,
                usageBasis: dataset.source.usageBasis,
                rightsNote: dataset.source.rightsNote,
                products: dataset.products.map { product in
                    .init(
                        id: product.id,
                        productName: product.productName,
                        series: product.series,
                        articleNumber: product.articleNumber,
                        sourceReference: product.sourceReference,
                        curves: product.curves.map { curve in
                            pumpCurveReportCurve(curve, operatingPoint: operatingPoint)
                        }
                    )
                }
            )
        }

        return .init(
            schema: HeizBalancePumpCurveReportSnapshot.schemaVersion,
            calculationProfile: HeizBalancePumpCurveOperatingPointCalculator.profileVersion,
            technicalMetricsProfile: HeizBalancePumpTechnicalMetricsCalculator.profileVersion,
            generatedAt: generatedAt,
            projectID: id,
            projectName: name,
            operatingPoint: operatingPoint,
            automaticPumpSelectionReleased: false,
            notice: "Technischer Pumpenkennlinienvergleich mit hydraulischen Leistungskennzahlen. Eine ausdrücklich festgehaltene Benutzerauswahl ist keine automatische Pumpenempfehlung. Pₕ,erf/P₁ ist eine technische Verhältniskennzahl und ausdrücklich keine ErP-/Hersteller-Effizienzfreigabe. Keine Extrapolation außerhalb dokumentierter Kennlinienbereiche.",
            datasets: datasetData,
            selectedPump: heldSelection,
            selectedPumpMatchesOperatingPoint: heldSelectionMatchesOperatingPoint
        )
    }

    private func pumpCurveReportCurve(
        _ curve: HeizBalancePumpProductDataset.Curve,
        operatingPoint: HeizBalancePumpCurveReportSnapshot.OperatingPointData?
    ) -> HeizBalancePumpCurveReportSnapshot.CurveData {
        let evaluation: HeizBalancePumpCurveOperatingPointCalculator.Result?
        let status: HeizBalancePumpCurveReportSnapshot.EvaluationStatus

        if let operatingPoint {
            evaluation = HeizBalancePumpCurveOperatingPointCalculator.calculate(
                .init(
                    targetVolumeFlowM3H: operatingPoint.volumeFlowM3H,
                    requiredHeadM: operatingPoint.requiredHeadM,
                    points: curve.points
                )
            )
            status = evaluation == nil ? .outsideDocumentedRange : .evaluated
        } else {
            evaluation = nil
            status = .operatingPointUnavailable
        }

        let metrics: HeizBalancePumpTechnicalMetricsCalculator.Result?
        if let evaluation,
           let operatingPoint,
           let density = operatingPoint.fluidDensityKGPerM3 {
            let flows = curve.points.map(\.volumeFlowM3H)
            metrics = HeizBalancePumpTechnicalMetricsCalculator.calculate(
                .init(
                    volumeFlowM3H: operatingPoint.volumeFlowM3H,
                    requiredHeadM: operatingPoint.requiredHeadM,
                    availableHeadM: evaluation.availableHeadM,
                    fluidDensityKGPerM3: density,
                    electricalInputPowerW: evaluation.interpolatedElectricalInputPowerW,
                    documentedMinimumFlowM3H: flows.min(),
                    documentedMaximumFlowM3H: flows.max()
                )
            )
        } else {
            metrics = nil
        }

        return .init(
            id: curve.id,
            label: curve.label,
            controlMode: curve.controlMode,
            speedRPM: curve.speedRPM,
            sourceReference: curve.sourceReference,
            status: status,
            evaluation: evaluation.map {
                .init(
                    availableHeadM: $0.availableHeadM,
                    requiredHeadM: $0.requiredHeadM,
                    headReserveM: $0.headReserveM,
                    technicallySufficient: $0.technicallySufficient,
                    electricalInputPowerW: $0.interpolatedElectricalInputPowerW,
                    lowerPointID: $0.lowerPointID,
                    upperPointID: $0.upperPointID,
                    exactDocumentedPoint: $0.exactDocumentedPoint,
                    requiredHydraulicPowerW: metrics?.requiredHydraulicPowerW,
                    availableHydraulicPowerW: metrics?.availableHydraulicPowerW,
                    headReservePercent: metrics?.headReservePercent,
                    requiredHydraulicToElectricalRatio: metrics?.requiredHydraulicToElectricalRatio,
                    documentedFlowPosition: metrics?.documentedFlowPosition
                )
            },
            points: curve.points.map {
                .init(
                    id: $0.id,
                    volumeFlowM3H: $0.volumeFlowM3H,
                    headM: $0.headM,
                    electricalInputPowerW: $0.electricalInputPowerW
                )
            }
        )
    }
}
