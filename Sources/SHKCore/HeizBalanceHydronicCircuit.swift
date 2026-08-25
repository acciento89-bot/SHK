import Foundation

enum HeizBalanceHydronicCircuitCalculator {
    struct PipeSectionInput: Sendable, Equatable {
        var id: String
        var name: String
        var volumeFlowLPH: Double
        var innerDiameterMM: Double
        var lengthM: Double
        var roughnessMM: Double
        var zetaTotal: Double?
    }

    struct Input: Sendable, Equatable {
        var targetVolumeFlowLPH: Double
        var densityKGPerM3: Double
        var kinematicViscosityM2S: Double
        var sections: [PipeSectionInput]
    }

    struct SectionResult: Sendable, Equatable {
        var id: String
        var name: String
        var volumeFlowLPH: Double
        var velocityMS: Double
        var reynoldsNumber: Double
        var pressureDropPaPerM: Double
        var straightPressureLossKPa: Double
        var localPressureLossKPa: Double?
        var combinedPressureLossKPa: Double?
    }

    struct Result: Sendable, Equatable {
        var targetVolumeFlowLPH: Double
        var sections: [SectionResult]
        var straightPipePressureLossKPa: Double
        var knownLocalPressureLossKPa: Double
        var partialPressureLossKPa: Double
        var completePressureLossKPa: Double?
        var completeHeadMeters: Double?
        var localResistanceCoverageComplete: Bool
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.targetVolumeFlowLPH > 0,
              input.densityKGPerM3 > 0,
              input.kinematicViscosityM2S > 0,
              !input.sections.isEmpty else {
            return nil
        }

        var sectionResults: [SectionResult] = []
        var straightTotal = 0.0
        var knownLocalTotal = 0.0
        var localCoverageComplete = true

        for section in input.sections {
            guard section.volumeFlowLPH.isFinite,
                  section.volumeFlowLPH > 0,
                  section.innerDiameterMM > 0,
                  section.lengthM >= 0,
                  section.roughnessMM >= 0 else {
                return nil
            }
            if let zeta = section.zetaTotal, zeta < 0 {
                return nil
            }

            let hydraulics = PipeCalculator.calculateExtended(
                volumeFlowLPH: section.volumeFlowLPH,
                innerDiameterMM: section.innerDiameterMM,
                lengthM: section.lengthM,
                roughnessMM: section.roughnessMM,
                zetaTotal: section.zetaTotal ?? 0,
                densityKGPerM3: input.densityKGPerM3,
                kinematicViscosityM2S: input.kinematicViscosityM2S
            )

            let localLoss: Double?
            let combinedLoss: Double?
            if section.zetaTotal != nil {
                localLoss = hydraulics.localPressureLossKPa
                combinedLoss = hydraulics.totalPressureLossIncludingLocalKPa
                knownLocalTotal += hydraulics.localPressureLossKPa
            } else {
                localLoss = nil
                combinedLoss = nil
                localCoverageComplete = false
            }

            straightTotal += hydraulics.base.totalPressureDropKPa
            sectionResults.append(
                SectionResult(
                    id: section.id,
                    name: section.name,
                    volumeFlowLPH: section.volumeFlowLPH,
                    velocityMS: hydraulics.base.velocityMS,
                    reynoldsNumber: hydraulics.reynoldsNumber,
                    pressureDropPaPerM: hydraulics.base.pressureDropPaPerM,
                    straightPressureLossKPa: hydraulics.base.totalPressureDropKPa,
                    localPressureLossKPa: localLoss,
                    combinedPressureLossKPa: combinedLoss
                )
            )
        }

        let partial = straightTotal + knownLocalTotal
        let complete = localCoverageComplete ? partial : nil
        let head = complete.map {
            PipeCalculator.metersWaterColumn(
                pressureLossKPa: $0,
                densityKGPerM3: input.densityKGPerM3
            )
        }

        return Result(
            targetVolumeFlowLPH: input.targetVolumeFlowLPH,
            sections: sectionResults,
            straightPipePressureLossKPa: straightTotal,
            knownLocalPressureLossKPa: knownLocalTotal,
            partialPressureLossKPa: partial,
            completePressureLossKPa: complete,
            completeHeadMeters: head,
            localResistanceCoverageComplete: localCoverageComplete
        )
    }
}
