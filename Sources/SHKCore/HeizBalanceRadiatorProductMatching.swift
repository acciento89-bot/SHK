import Foundation

enum HeizBalanceRadiatorProductMatchingCalculator {
    struct Candidate: Sendable, Equatable, Identifiable {
        var id: String
        var nominalPowerDeltaT50W: Double
        var exponent: Double
        var widthMM: Double?
        var heightMM: Double?
        var depthMM: Double?
    }

    struct Constraints: Sendable, Equatable {
        var maximumWidthMM: Double?
        var maximumHeightMM: Double?
        var maximumDepthMM: Double?

        init(
            maximumWidthMM: Double? = nil,
            maximumHeightMM: Double? = nil,
            maximumDepthMM: Double? = nil
        ) {
            self.maximumWidthMM = maximumWidthMM
            self.maximumHeightMM = maximumHeightMM
            self.maximumDepthMM = maximumDepthMM
        }
    }

    struct Input: Sendable, Equatable {
        var requiredPowerW: Double
        var roomTemperatureC: Double
        var flowTemperatureC: Double
        var returnTemperatureC: Double
        var candidates: [Candidate]
        var constraints: Constraints

        init(
            requiredPowerW: Double,
            roomTemperatureC: Double,
            flowTemperatureC: Double,
            returnTemperatureC: Double,
            candidates: [Candidate],
            constraints: Constraints = .init()
        ) {
            self.requiredPowerW = requiredPowerW
            self.roomTemperatureC = roomTemperatureC
            self.flowTemperatureC = flowTemperatureC
            self.returnTemperatureC = returnTemperatureC
            self.candidates = candidates
            self.constraints = constraints
        }
    }

    struct CandidateResult: Sendable, Equatable, Identifiable {
        var id: String { candidateID }
        var candidateID: String
        var nominalPowerDeltaT50W: Double
        var availablePowerW: Double
        var capacityRatio: Double
        var reservePowerW: Double
        var nominalReserveFactor: Double
        var sufficient: Bool
    }

    struct Result: Sendable, Equatable {
        var evaluatedCandidateCount: Int
        var dimensionRejectedCandidateCount: Int
        var invalidCandidateCount: Int
        var candidates: [CandidateResult]

        var sufficientCandidates: [CandidateResult] {
            candidates.filter(\.sufficient)
        }

        var smallestSufficientCandidate: CandidateResult? {
            sufficientCandidates.first
        }
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.requiredPowerW.isFinite,
              input.roomTemperatureC.isFinite,
              input.flowTemperatureC.isFinite,
              input.returnTemperatureC.isFinite,
              input.requiredPowerW > 0,
              input.flowTemperatureC > input.returnTemperatureC,
              input.returnTemperatureC > input.roomTemperatureC,
              constraintsAreValid(input.constraints) else {
            return nil
        }

        var results: [CandidateResult] = []
        var dimensionRejected = 0
        var invalidCandidates = 0

        for candidate in input.candidates {
            guard candidateIsValid(candidate) else {
                invalidCandidates += 1
                continue
            }

            guard matchesDimensions(candidate, constraints: input.constraints) else {
                dimensionRejected += 1
                continue
            }

            guard let scenarioResult = HeizBalanceTemperatureScenarioCalculator.calculate(
                .init(
                    nominalPowerDeltaT50W: candidate.nominalPowerDeltaT50W,
                    exponent: candidate.exponent,
                    requiredPowerW: input.requiredPowerW,
                    roomTemperatureC: input.roomTemperatureC,
                    flowTemperatureC: input.flowTemperatureC,
                    returnTemperatureC: input.returnTemperatureC
                )
            ) else {
                invalidCandidates += 1
                continue
            }

            let reservePower = scenarioResult.availablePowerW - input.requiredPowerW
            let nominalReserveFactor = candidate.nominalPowerDeltaT50W
                / scenarioResult.requiredNominalPowerDeltaT50W

            results.append(
                CandidateResult(
                    candidateID: candidate.id,
                    nominalPowerDeltaT50W: candidate.nominalPowerDeltaT50W,
                    availablePowerW: scenarioResult.availablePowerW,
                    capacityRatio: scenarioResult.capacityRatio,
                    reservePowerW: reservePower,
                    nominalReserveFactor: nominalReserveFactor,
                    sufficient: scenarioResult.sufficient
                )
            )
        }

        results.sort { lhs, rhs in
            if lhs.sufficient != rhs.sufficient {
                return lhs.sufficient && !rhs.sufficient
            }

            if lhs.sufficient {
                if abs(lhs.reservePowerW - rhs.reservePowerW) > 0.001 {
                    return lhs.reservePowerW < rhs.reservePowerW
                }
            } else if abs(lhs.capacityRatio - rhs.capacityRatio) > 0.000_001 {
                return lhs.capacityRatio > rhs.capacityRatio
            }

            if abs(lhs.nominalPowerDeltaT50W - rhs.nominalPowerDeltaT50W) > 0.001 {
                return lhs.nominalPowerDeltaT50W < rhs.nominalPowerDeltaT50W
            }

            return lhs.candidateID < rhs.candidateID
        }

        return Result(
            evaluatedCandidateCount: results.count,
            dimensionRejectedCandidateCount: dimensionRejected,
            invalidCandidateCount: invalidCandidates,
            candidates: results
        )
    }

    private static func constraintsAreValid(_ constraints: Constraints) -> Bool {
        [
            constraints.maximumWidthMM,
            constraints.maximumHeightMM,
            constraints.maximumDepthMM
        ]
        .compactMap { $0 }
        .allSatisfy { $0.isFinite && $0 > 0 }
    }

    private static func candidateIsValid(_ candidate: Candidate) -> Bool {
        guard !candidate.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              candidate.nominalPowerDeltaT50W.isFinite,
              candidate.exponent.isFinite,
              candidate.nominalPowerDeltaT50W > 0,
              candidate.exponent > 0 else {
            return false
        }

        return [candidate.widthMM, candidate.heightMM, candidate.depthMM]
            .compactMap { $0 }
            .allSatisfy { $0.isFinite && $0 > 0 }
    }

    private static func matchesDimensions(
        _ candidate: Candidate,
        constraints: Constraints
    ) -> Bool {
        if let maximumWidth = constraints.maximumWidthMM {
            guard let width = candidate.widthMM, width <= maximumWidth else { return false }
        }
        if let maximumHeight = constraints.maximumHeightMM {
            guard let height = candidate.heightMM, height <= maximumHeight else { return false }
        }
        if let maximumDepth = constraints.maximumDepthMM {
            guard let depth = candidate.depthMM, depth <= maximumDepth else { return false }
        }
        return true
    }
}
