import Foundation

struct HeizBalancePumpCurveOperatingPointCalculator {
    struct Input: Hashable {
        var targetVolumeFlowM3H: Double
        var requiredHeadM: Double
        var points: [HeizBalancePumpProductDataset.CurvePoint]
    }

    struct Result: Hashable {
        var targetVolumeFlowM3H: Double
        var requiredHeadM: Double
        var availableHeadM: Double
        var headReserveM: Double
        var technicallySufficient: Bool
        var interpolatedElectricalInputPowerW: Double?
        var lowerPointID: String
        var upperPointID: String
        var exactDocumentedPoint: Bool
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.targetVolumeFlowM3H.isFinite,
              input.targetVolumeFlowM3H >= 0,
              input.requiredHeadM.isFinite,
              input.requiredHeadM >= 0,
              input.points.count >= 2 else {
            return nil
        }

        let sorted = input.points.sorted { $0.volumeFlowM3H < $1.volumeFlowM3H }
        var previousFlow: Double?
        for point in sorted {
            guard point.volumeFlowM3H.isFinite,
                  point.volumeFlowM3H >= 0,
                  point.headM.isFinite,
                  point.headM >= 0,
                  point.electricalInputPowerW.map({ $0.isFinite && $0 > 0 }) ?? true else {
                return nil
            }
            if let previousFlow, point.volumeFlowM3H <= previousFlow {
                return nil
            }
            previousFlow = point.volumeFlowM3H
        }

        guard let first = sorted.first,
              let last = sorted.last,
              input.targetVolumeFlowM3H >= first.volumeFlowM3H,
              input.targetVolumeFlowM3H <= last.volumeFlowM3H else {
            // Deliberately no extrapolation outside the documented curve range.
            return nil
        }

        if let exact = sorted.first(where: { $0.volumeFlowM3H == input.targetVolumeFlowM3H }) {
            return result(
                input: input,
                availableHeadM: exact.headM,
                electricalInputPowerW: exact.electricalInputPowerW,
                lowerPointID: exact.id,
                upperPointID: exact.id,
                exactDocumentedPoint: true
            )
        }

        guard let upperIndex = sorted.firstIndex(where: { $0.volumeFlowM3H > input.targetVolumeFlowM3H }),
              upperIndex > sorted.startIndex else {
            return nil
        }

        let lower = sorted[sorted.index(before: upperIndex)]
        let upper = sorted[upperIndex]
        let flowSpan = upper.volumeFlowM3H - lower.volumeFlowM3H
        guard flowSpan > 0 else { return nil }

        let fraction = (input.targetVolumeFlowM3H - lower.volumeFlowM3H) / flowSpan
        let availableHeadM = lower.headM + fraction * (upper.headM - lower.headM)

        let electricalInputPowerW: Double?
        if let lowerPower = lower.electricalInputPowerW,
           let upperPower = upper.electricalInputPowerW {
            electricalInputPowerW = lowerPower + fraction * (upperPower - lowerPower)
        } else {
            electricalInputPowerW = nil
        }

        return result(
            input: input,
            availableHeadM: availableHeadM,
            electricalInputPowerW: electricalInputPowerW,
            lowerPointID: lower.id,
            upperPointID: upper.id,
            exactDocumentedPoint: false
        )
    }

    private static func result(
        input: Input,
        availableHeadM: Double,
        electricalInputPowerW: Double?,
        lowerPointID: String,
        upperPointID: String,
        exactDocumentedPoint: Bool
    ) -> Result {
        let reserve = availableHeadM - input.requiredHeadM
        return .init(
            targetVolumeFlowM3H: input.targetVolumeFlowM3H,
            requiredHeadM: input.requiredHeadM,
            availableHeadM: availableHeadM,
            headReserveM: reserve,
            technicallySufficient: reserve >= 0,
            interpolatedElectricalInputPowerW: electricalInputPowerW,
            lowerPointID: lowerPointID,
            upperPointID: upperPointID,
            exactDocumentedPoint: exactDocumentedPoint
        )
    }
}
