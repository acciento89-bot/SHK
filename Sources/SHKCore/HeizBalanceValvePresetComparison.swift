import Foundation

enum HeizBalanceValvePresetComparisonCalculator {
    struct SettingPoint: Sendable, Equatable {
        var setting: String
        var kvM3H: Double
    }

    struct Input: Sendable, Equatable {
        var requiredKvM3H: Double
        var points: [SettingPoint]
    }

    struct Result: Sendable, Equatable {
        var requiredKvM3H: Double
        var minimumKvM3H: Double
        var maximumKvM3H: Double
        var lowerPoint: SettingPoint?
        var upperPoint: SettingPoint?
        var nearestPoint: SettingPoint
        var absoluteDeviationKvM3H: Double
        var relativeDeviation: Double
        var requiredKvInsideDataRange: Bool
        var exactMatch: Bool
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.requiredKvM3H.isFinite,
              input.requiredKvM3H > 0,
              !input.points.isEmpty else {
            return nil
        }

        var normalized: [SettingPoint] = []
        var seenSettings: Set<String> = []

        for point in input.points {
            let setting = point.setting.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !setting.isEmpty,
                  point.kvM3H.isFinite,
                  point.kvM3H > 0 else {
                return nil
            }

            let key = setting.lowercased()
            guard seenSettings.insert(key).inserted else {
                return nil
            }

            normalized.append(
                SettingPoint(
                    setting: setting,
                    kvM3H: point.kvM3H
                )
            )
        }

        normalized.sort {
            if $0.kvM3H == $1.kvM3H {
                return $0.setting.localizedStandardCompare($1.setting) == .orderedAscending
            }
            return $0.kvM3H < $1.kvM3H
        }

        guard let first = normalized.first,
              let last = normalized.last else {
            return nil
        }

        let lower = normalized.last(where: { $0.kvM3H <= input.requiredKvM3H })
        let upper = normalized.first(where: { $0.kvM3H >= input.requiredKvM3H })

        let nearest = normalized.min { lhs, rhs in
            let lhsDeviation = abs(lhs.kvM3H - input.requiredKvM3H)
            let rhsDeviation = abs(rhs.kvM3H - input.requiredKvM3H)
            if lhsDeviation == rhsDeviation {
                return lhs.kvM3H < rhs.kvM3H
            }
            return lhsDeviation < rhsDeviation
        }!

        let absoluteDeviation = abs(nearest.kvM3H - input.requiredKvM3H)
        let relativeDeviation = absoluteDeviation / input.requiredKvM3H
        let exactTolerance = max(1e-9, input.requiredKvM3H * 1e-9)

        return Result(
            requiredKvM3H: input.requiredKvM3H,
            minimumKvM3H: first.kvM3H,
            maximumKvM3H: last.kvM3H,
            lowerPoint: lower,
            upperPoint: upper,
            nearestPoint: nearest,
            absoluteDeviationKvM3H: absoluteDeviation,
            relativeDeviation: relativeDeviation,
            requiredKvInsideDataRange: input.requiredKvM3H >= first.kvM3H && input.requiredKvM3H <= last.kvM3H,
            exactMatch: absoluteDeviation <= exactTolerance
        )
    }
}
