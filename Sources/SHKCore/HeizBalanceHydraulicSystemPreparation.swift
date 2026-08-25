import Foundation

enum HeizBalanceHydraulicSystemPreparationCalculator {
    struct CircuitInput: Sendable, Equatable {
        var id: String
        var name: String
        var targetVolumeFlowLPH: Double?
        var completePressureLossKPa: Double?
    }

    struct CircuitSummary: Sendable, Equatable {
        var id: String
        var name: String
        var pressureLossKPa: Double
    }

    struct Input: Sendable, Equatable {
        var circuits: [CircuitInput]
        var densityKGPerM3: Double?
    }

    struct Result: Sendable, Equatable {
        var circuitCount: Int
        var knownFlowCircuitCount: Int
        var completePressureCircuitCount: Int
        var knownTotalVolumeFlowLPH: Double
        var designTotalVolumeFlowLPH: Double?
        var flowCoverageComplete: Bool
        var pressureCoverageComplete: Bool
        var highestKnownPressureCircuit: CircuitSummary?
        var designUnfavorableCircuit: CircuitSummary?
        var designNetworkPressureLossKPa: Double?
        var designNetworkHeadMeters: Double?
        var pumpOperatingPointReady: Bool
    }

    static func calculate(_ input: Input) -> Result? {
        guard !input.circuits.isEmpty else { return nil }

        if let density = input.densityKGPerM3,
           (!density.isFinite || density <= 0) {
            return nil
        }

        var knownFlowCount = 0
        var completePressureCount = 0
        var knownFlowTotal = 0.0
        var highestKnown: CircuitSummary?

        for circuit in input.circuits {
            if let flow = circuit.targetVolumeFlowLPH {
                guard flow.isFinite, flow > 0 else { return nil }
                knownFlowCount += 1
                knownFlowTotal += flow
            }

            if let pressureLoss = circuit.completePressureLossKPa {
                guard pressureLoss.isFinite, pressureLoss >= 0 else { return nil }
                completePressureCount += 1
                if highestKnown == nil || pressureLoss > highestKnown!.pressureLossKPa {
                    highestKnown = CircuitSummary(
                        id: circuit.id,
                        name: circuit.name,
                        pressureLossKPa: pressureLoss
                    )
                }
            }
        }

        let flowComplete = knownFlowCount == input.circuits.count
        let pressureComplete = completePressureCount == input.circuits.count
        let designTotalFlow = flowComplete ? knownFlowTotal : nil
        let unfavorable = pressureComplete ? highestKnown : nil
        let networkPressureLoss = unfavorable?.pressureLossKPa

        let networkHead: Double?
        if let networkPressureLoss,
           let density = input.densityKGPerM3 {
            networkHead = PipeCalculator.metersWaterColumn(
                pressureLossKPa: networkPressureLoss,
                densityKGPerM3: density
            )
        } else {
            networkHead = nil
        }

        return Result(
            circuitCount: input.circuits.count,
            knownFlowCircuitCount: knownFlowCount,
            completePressureCircuitCount: completePressureCount,
            knownTotalVolumeFlowLPH: knownFlowTotal,
            designTotalVolumeFlowLPH: designTotalFlow,
            flowCoverageComplete: flowComplete,
            pressureCoverageComplete: pressureComplete,
            highestKnownPressureCircuit: highestKnown,
            designUnfavorableCircuit: unfavorable,
            designNetworkPressureLossKPa: networkPressureLoss,
            designNetworkHeadMeters: networkHead,
            pumpOperatingPointReady: flowComplete && pressureComplete
        )
    }
}
