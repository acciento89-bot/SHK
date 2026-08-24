import Foundation

public enum PipeFlowRegime: String, Sendable {
    case laminar = "laminar"
    case transitional = "Übergangsbereich"
    case turbulent = "turbulent"
}

public struct ExtendedPipeHydraulics: Sendable {
    public let base: PipeHydraulics
    public let reynoldsNumber: Double
    public let flowRegime: PipeFlowRegime
    public let localPressureLossKPa: Double
    public let totalPressureLossIncludingLocalKPa: Double
    public let totalHeadMeters: Double

    public init(
        base: PipeHydraulics,
        reynoldsNumber: Double,
        flowRegime: PipeFlowRegime,
        localPressureLossKPa: Double,
        totalPressureLossIncludingLocalKPa: Double,
        totalHeadMeters: Double
    ) {
        self.base = base
        self.reynoldsNumber = reynoldsNumber
        self.flowRegime = flowRegime
        self.localPressureLossKPa = localPressureLossKPa
        self.totalPressureLossIncludingLocalKPa = totalPressureLossIncludingLocalKPa
        self.totalHeadMeters = totalHeadMeters
    }
}

public extension PipeCalculator {
    static func crossSectionAreaM2(innerDiameterMM: Double) -> Double {
        guard innerDiameterMM > 0 else { return 0 }
        let diameterM = innerDiameterMM / 1000
        return .pi * diameterM * diameterM / 4
    }

    static func requiredInnerDiameterMM(volumeFlowLPH: Double, targetVelocityMS: Double) -> Double {
        guard volumeFlowLPH > 0, targetVelocityMS > 0 else { return 0 }
        let qM3S = volumeFlowLPH / 1000 / 3600
        return sqrt((4 * qM3S) / (.pi * targetVelocityMS)) * 1000
    }

    static func maximumVolumeFlowLPH(innerDiameterMM: Double, maximumVelocityMS: Double) -> Double {
        let area = crossSectionAreaM2(innerDiameterMM: innerDiameterMM)
        guard area > 0, maximumVelocityMS > 0 else { return 0 }
        return area * maximumVelocityMS * 3600 * 1000
    }

    static func reynoldsNumber(
        volumeFlowLPH: Double,
        innerDiameterMM: Double,
        kinematicViscosityM2S: Double = 1.004e-6
    ) -> Double {
        guard volumeFlowLPH > 0, innerDiameterMM > 0, kinematicViscosityM2S > 0 else { return 0 }
        let area = crossSectionAreaM2(innerDiameterMM: innerDiameterMM)
        guard area > 0 else { return 0 }
        let qM3S = volumeFlowLPH / 1000 / 3600
        let velocity = qM3S / area
        let diameterM = innerDiameterMM / 1000
        return velocity * diameterM / kinematicViscosityM2S
    }

    static func flowRegime(reynoldsNumber: Double) -> PipeFlowRegime {
        if reynoldsNumber < 2300 {
            return .laminar
        } else if reynoldsNumber < 4000 {
            return .transitional
        } else {
            return .turbulent
        }
    }

    static func localPressureLossKPa(
        volumeFlowLPH: Double,
        innerDiameterMM: Double,
        zetaTotal: Double,
        densityKGPerM3: Double = 998.0
    ) -> Double {
        guard volumeFlowLPH > 0, innerDiameterMM > 0, zetaTotal > 0, densityKGPerM3 > 0 else { return 0 }
        let area = crossSectionAreaM2(innerDiameterMM: innerDiameterMM)
        guard area > 0 else { return 0 }
        let qM3S = volumeFlowLPH / 1000 / 3600
        let velocity = qM3S / area
        let dynamicPressurePa = densityKGPerM3 * velocity * velocity / 2
        return zetaTotal * dynamicPressurePa / 1000
    }

    static func metersWaterColumn(
        pressureLossKPa: Double,
        densityKGPerM3: Double = 998.0,
        gravityMS2: Double = 9.80665
    ) -> Double {
        guard pressureLossKPa > 0, densityKGPerM3 > 0, gravityMS2 > 0 else { return 0 }
        return pressureLossKPa * 1000 / (densityKGPerM3 * gravityMS2)
    }

    static func calculateExtended(
        volumeFlowLPH: Double,
        innerDiameterMM: Double,
        lengthM: Double,
        roughnessMM: Double = 0.01,
        zetaTotal: Double = 0,
        densityKGPerM3: Double = 998.0,
        kinematicViscosityM2S: Double = 1.004e-6
    ) -> ExtendedPipeHydraulics {
        let base = calculate(
            volumeFlowLPH: volumeFlowLPH,
            innerDiameterMM: innerDiameterMM,
            lengthM: lengthM,
            roughnessMM: roughnessMM,
            densityKGPerM3: densityKGPerM3,
            kinematicViscosityM2S: kinematicViscosityM2S
        )
        let reynolds = reynoldsNumber(
            volumeFlowLPH: volumeFlowLPH,
            innerDiameterMM: innerDiameterMM,
            kinematicViscosityM2S: kinematicViscosityM2S
        )
        let localLoss = localPressureLossKPa(
            volumeFlowLPH: volumeFlowLPH,
            innerDiameterMM: innerDiameterMM,
            zetaTotal: zetaTotal,
            densityKGPerM3: densityKGPerM3
        )
        let total = base.totalPressureDropKPa + localLoss

        return .init(
            base: base,
            reynoldsNumber: reynolds,
            flowRegime: flowRegime(reynoldsNumber: reynolds),
            localPressureLossKPa: localLoss,
            totalPressureLossIncludingLocalKPa: total,
            totalHeadMeters: metersWaterColumn(pressureLossKPa: total, densityKGPerM3: densityKGPerM3)
        )
    }

    static func pascalPerMeterToMbarPerMeter(_ pascalPerMeter: Double) -> Double {
        pascalPerMeter / 100
    }
}
