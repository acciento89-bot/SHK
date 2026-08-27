import Foundation

extension HeizBalanceHeatingSurface {
    func terminalPipeCircuitPreparation(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double,
        densityKGPerM3: Double?,
        kinematicViscosityMM2S: Double?
    ) -> HeizBalanceHydronicCircuitCalculator.Result? {
        guard let hydronic = hydronicPreparation(
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                roomTemperatureC: roomTemperatureC
              ),
              let densityKGPerM3,
              let kinematicViscosityMM2S,
              densityKGPerM3 > 0,
              kinematicViscosityMM2S > 0 else {
            return nil
        }

        let branches = (pipeSections ?? []).filter { $0.effectiveRole == .heatingSurfaceBranch }
        guard !branches.isEmpty else { return nil }

        var inputs: [HeizBalanceHydronicCircuitCalculator.PipeSectionInput] = []
        for section in branches {
            guard let innerDiameterMM = section.innerDiameterMM,
                  let lengthM = section.lengthM,
                  let roughnessMM = section.roughnessMM else {
                return nil
            }
            inputs.append(
                .init(
                    id: section.id.uuidString,
                    name: section.name,
                    volumeFlowLPH: hydronic.targetVolumeFlowLPH,
                    innerDiameterMM: innerDiameterMM,
                    lengthM: lengthM,
                    roughnessMM: roughnessMM,
                    zetaTotal: section.zetaTotal
                )
            )
        }

        return HeizBalanceHydronicCircuitCalculator.calculate(
            .init(
                targetVolumeFlowLPH: hydronic.targetVolumeFlowLPH,
                densityKGPerM3: densityKGPerM3,
                kinematicViscosityM2S: kinematicViscosityMM2S * 1e-6,
                sections: inputs
            )
        )
    }

    func terminalCircuitPressureLossSummary(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double,
        densityKGPerM3: Double?,
        kinematicViscosityMM2S: Double?
    ) -> HeizBalanceCircuitPressureLossSummaryCalculator.Result? {
        guard let pipeCircuit = terminalPipeCircuitPreparation(
            flowTemperatureC: flowTemperatureC,
            returnTemperatureC: returnTemperatureC,
            roomTemperatureC: roomTemperatureC,
            densityKGPerM3: densityKGPerM3,
            kinematicViscosityMM2S: kinematicViscosityMM2S
        ) else {
            return nil
        }

        let components = (hydraulicLossComponents ?? []).map {
            HeizBalanceCircuitPressureLossSummaryCalculator.ComponentInput(
                id: $0.id.uuidString,
                pressureLossKPa: $0.pressureLossKPa
            )
        }

        return HeizBalanceCircuitPressureLossSummaryCalculator.calculate(
            .init(
                partialPipePressureLossKPa: pipeCircuit.partialPressureLossKPa,
                completePipePressureLossKPa: pipeCircuit.completePressureLossKPa,
                components: components,
                componentAssessmentComplete: isHydraulicComponentAssessmentComplete
            )
        )
    }
}
