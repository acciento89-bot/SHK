import Foundation

public extension VentilationCalculator {
    static let commonRoundDiametersMM: [Double] = [
        80, 100, 125, 150, 160, 180, 200, 224, 250, 280, 315, 355, 400, 450, 500, 560, 630
    ]

    static func roundAreaM2(diameterMM: Double) -> Double {
        guard diameterMM > 0 else { return 0 }
        let diameterM = diameterMM / 1000
        return .pi * diameterM * diameterM / 4
    }

    static func roundVelocityMS(volumeFlowM3H: Double, diameterMM: Double) -> Double {
        let area = roundAreaM2(diameterMM: diameterMM)
        guard area > 0 else { return 0 }
        return max(0, volumeFlowM3H) / 3600 / area
    }

    static func rectangularAreaM2(widthMM: Double, heightMM: Double) -> Double {
        guard widthMM > 0, heightMM > 0 else { return 0 }
        return widthMM / 1000 * heightMM / 1000
    }

    static func rectangularRequiredHeightMM(
        volumeFlowM3H: Double,
        widthMM: Double,
        targetVelocityMS: Double
    ) -> Double {
        guard volumeFlowM3H > 0, widthMM > 0, targetVelocityMS > 0 else { return 0 }
        let qM3S = volumeFlowM3H / 3600
        let widthM = widthMM / 1000
        return qM3S / (widthM * targetVelocityMS) * 1000
    }

    /// Hydraulisch äquivalenter Runddurchmesser eines Rechteckkanals nach gebräuchlicher Näherung.
    /// Breite und Höhe müssen in derselben Einheit angegeben werden; bei mm ist das Ergebnis mm.
    static func equivalentRoundDiameterMM(widthMM: Double, heightMM: Double) -> Double {
        guard widthMM > 0, heightMM > 0 else { return 0 }
        let product = widthMM * heightMM
        let sum = widthMM + heightMM
        return 1.30 * pow(product, 0.625) / pow(sum, 0.25)
    }

    static func nextCommonRoundDiameterMM(requiredDiameterMM: Double) -> Double {
        guard requiredDiameterMM > 0 else { return 0 }
        return commonRoundDiametersMM.first(where: { $0 >= requiredDiameterMM }) ?? requiredDiameterMM
    }

    static func roomVolumeM3(lengthM: Double, widthM: Double, heightM: Double) -> Double {
        max(0, lengthM) * max(0, widthM) * max(0, heightM)
    }

    static func m3HToLitersPerSecond(_ volumeFlowM3H: Double) -> Double {
        volumeFlowM3H / 3.6
    }

    static func litersPerSecondToM3H(_ litersPerSecond: Double) -> Double {
        litersPerSecond * 3.6
    }

    static func m3HToCFM(_ volumeFlowM3H: Double) -> Double {
        volumeFlowM3H * 0.588577779
    }

    static func cfmToM3H(_ cfm: Double) -> Double {
        cfm / 0.588577779
    }
}
