import Foundation

public enum RadiatorTemperatureMethod: String, Sendable {
    case automatic
    case arithmetic
    case logarithmic
}

public struct RadiatorTemperatureEvaluation: Sendable {
    public let deltaTK: Double
    public let referenceDeltaTK: Double
    public let method: RadiatorTemperatureMethod
    public let ratioC: Double

    public init(deltaTK: Double, referenceDeltaTK: Double, method: RadiatorTemperatureMethod, ratioC: Double) {
        self.deltaTK = deltaTK
        self.referenceDeltaTK = referenceDeltaTK
        self.method = method
        self.ratioC = ratioC
    }
}

public extension RadiatorCalculator {
    /// Arithmetische mittlere Übertemperatur gegenüber der Raumluft.
    static func arithmeticTemperatureDifferenceK(flowC: Double, returnC: Double, roomC: Double) -> Double {
        guard flowC >= returnC else { return 0 }
        return max(0, ((flowC + returnC) / 2) - roomC)
    }

    /// Logarithmische mittlere Übertemperatur.
    /// ΔTlog = (tV - tR) / ln((tV - ti) / (tR - ti))
    static func logarithmicTemperatureDifferenceK(flowC: Double, returnC: Double, roomC: Double) -> Double {
        guard flowC >= returnC else { return 0 }
        let flowDifference = flowC - roomC
        let returnDifference = returnC - roomC
        guard flowDifference > 0, returnDifference > 0 else { return 0 }

        if abs(flowC - returnC) < 0.000_001 {
            return flowDifference
        }

        let denominator = log(flowDifference / returnDifference)
        guard denominator.isFinite, abs(denominator) > 0.000_001 else { return 0 }
        let result = (flowC - returnC) / denominator
        return result.isFinite ? max(0, result) : 0
    }

    /// Verhältnis c = (tR - ti) / (tV - ti).
    static func temperatureRatioC(flowC: Double, returnC: Double, roomC: Double) -> Double {
        let denominator = flowC - roomC
        guard denominator > 0 else { return 0 }
        return (returnC - roomC) / denominator
    }

    /// Automatik entsprechend gebräuchlicher EN-442-Herstellerunterlagen:
    /// bei c < 0,7 logarithmisch, sonst arithmetisch.
    static func temperatureEvaluation(
        flowC: Double,
        returnC: Double,
        roomC: Double,
        method requestedMethod: RadiatorTemperatureMethod = .automatic
    ) -> RadiatorTemperatureEvaluation {
        let c = temperatureRatioC(flowC: flowC, returnC: returnC, roomC: roomC)
        let resolvedMethod: RadiatorTemperatureMethod

        switch requestedMethod {
        case .automatic:
            resolvedMethod = c > 0 && c < 0.7 ? .logarithmic : .arithmetic
        case .arithmetic, .logarithmic:
            resolvedMethod = requestedMethod
        }

        switch resolvedMethod {
        case .logarithmic:
            return .init(
                deltaTK: logarithmicTemperatureDifferenceK(flowC: flowC, returnC: returnC, roomC: roomC),
                referenceDeltaTK: logarithmicTemperatureDifferenceK(flowC: 75, returnC: 65, roomC: 20),
                method: .logarithmic,
                ratioC: c
            )
        case .arithmetic, .automatic:
            return .init(
                deltaTK: arithmeticTemperatureDifferenceK(flowC: flowC, returnC: returnC, roomC: roomC),
                referenceDeltaTK: 50,
                method: .arithmetic,
                ratioC: c
            )
        }
    }

    static func correctedPowerW(
        nominalPowerDeltaT50W: Double,
        flowC: Double,
        returnC: Double,
        roomC: Double,
        exponent: Double,
        method: RadiatorTemperatureMethod = .automatic
    ) -> Double {
        let evaluation = temperatureEvaluation(flowC: flowC, returnC: returnC, roomC: roomC, method: method)
        guard nominalPowerDeltaT50W > 0,
              evaluation.deltaTK > 0,
              evaluation.referenceDeltaTK > 0,
              exponent > 0 else { return 0 }

        return nominalPowerDeltaT50W * pow(evaluation.deltaTK / evaluation.referenceDeltaTK, exponent)
    }

    static func requiredNominalPowerDeltaT50W(
        requiredActualPowerW: Double,
        flowC: Double,
        returnC: Double,
        roomC: Double,
        exponent: Double,
        method: RadiatorTemperatureMethod = .automatic
    ) -> Double {
        let evaluation = temperatureEvaluation(flowC: flowC, returnC: returnC, roomC: roomC, method: method)
        guard requiredActualPowerW > 0,
              evaluation.deltaTK > 0,
              evaluation.referenceDeltaTK > 0,
              exponent > 0 else { return 0 }

        let factor = pow(evaluation.deltaTK / evaluation.referenceDeltaTK, exponent)
        guard factor > 0 else { return 0 }
        return requiredActualPowerW / factor
    }

    static func radiatorCount(requiredPowerW: Double, actualPowerPerRadiatorW: Double) -> Int {
        guard requiredPowerW > 0, actualPowerPerRadiatorW > 0 else { return 0 }
        return Int(ceil(requiredPowerW / actualPowerPerRadiatorW))
    }
}
