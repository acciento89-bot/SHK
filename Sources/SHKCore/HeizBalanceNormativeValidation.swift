import Foundation

enum HeizBalanceNormativeModuleID: String, Codable, CaseIterable, Sendable {
    case transmissionExterior
    case transmissionAdjacent
    case transmissionGround
    case thermalBridges
    case ventilationMinimum
    case infiltration
    case mechanicalVentilation
    case heatingUp
    case roomAggregation
    case buildingAggregation

    var displayName: String {
        switch self {
        case .transmissionExterior: "Transmission Außenbauteile"
        case .transmissionAdjacent: "Transmission angrenzende Bereiche"
        case .transmissionGround: "Transmission Erdreich"
        case .thermalBridges: "Wärmebrücken"
        case .ventilationMinimum: "Lüftung / Mindestluftwechsel"
        case .infiltration: "Infiltration"
        case .mechanicalVentilation: "Mechanische Lüftung"
        case .heatingUp: "Wiederaufheizung"
        case .roomAggregation: "Raumaggregation"
        case .buildingAggregation: "Gebäudeaggregation"
        }
    }
}

struct HeizBalanceNormativeModuleEvidence: Equatable, Sendable {
    var moduleID: HeizBalanceNormativeModuleID
    var specificationVerified: Bool
    var referenceCaseCount: Int
    var passedReferenceCaseCount: Int

    var referenceCoverageComplete: Bool {
        referenceCaseCount > 0 && passedReferenceCaseCount == referenceCaseCount
    }
}

struct HeizBalanceNormativeReadinessReport: Equatable, Sendable {
    var requiredModules: [HeizBalanceNormativeModuleID]
    var missingSpecificationModules: [HeizBalanceNormativeModuleID]
    var missingReferenceValidationModules: [HeizBalanceNormativeModuleID]
    var profileLifecycleReady: Bool
    var explicitReleaseFlagEnabled: Bool

    var canProduceNormativeOutput: Bool {
        profileLifecycleReady
            && explicitReleaseFlagEnabled
            && missingSpecificationModules.isEmpty
            && missingReferenceValidationModules.isEmpty
    }
}

enum HeizBalanceNormativeReadiness {
    static func requiredModules(
        for engineID: HeizBalanceCalculationEngineID
    ) -> [HeizBalanceNormativeModuleID] {
        switch engineID {
        case .technicalPreviewV1:
            []
        case .deRoomHeatLoad2017_2020:
            [
                .transmissionExterior,
                .transmissionAdjacent,
                .transmissionGround,
                .thermalBridges,
                .ventilationMinimum,
                .infiltration,
                .mechanicalVentilation,
                .heatingUp,
                .roomAggregation,
                .buildingAggregation
            ]
        }
    }

    static func evaluate(
        profile: HeizBalanceCalculationProfile,
        evidence: [HeizBalanceNormativeModuleEvidence]
    ) -> HeizBalanceNormativeReadinessReport {
        let required = requiredModules(for: profile.engineID)
        var evidenceByModule: [HeizBalanceNormativeModuleID: HeizBalanceNormativeModuleEvidence] = [:]
        for item in evidence {
            evidenceByModule[item.moduleID] = item
        }

        let missingSpecification = required.filter {
            evidenceByModule[$0]?.specificationVerified != true
        }

        let missingReferences = required.filter {
            evidenceByModule[$0]?.referenceCoverageComplete != true
        }

        return HeizBalanceNormativeReadinessReport(
            requiredModules: required,
            missingSpecificationModules: missingSpecification,
            missingReferenceValidationModules: missingReferences,
            profileLifecycleReady: profile.validationState.allowsReferenceValidatedExecution,
            explicitReleaseFlagEnabled: profile.normativeOutputAllowed
        )
    }
}

extension HeizBalanceCalculationValidationState {
    var displayName: String {
        switch self {
        case .developmentOnly: "In Entwicklung"
        case .specificationVerified: "Spezifikation verifiziert"
        case .referenceValidated: "Referenzfälle validiert"
        case .released: "Freigegeben"
        }
    }

    var allowsReferenceValidatedExecution: Bool {
        switch self {
        case .referenceValidated, .released: true
        case .developmentOnly, .specificationVerified: false
        }
    }
}

struct HeizBalanceReferenceMetricExpectation: Equatable, Sendable {
    var key: String
    var expectedValue: Double
    var absoluteTolerance: Double
}

struct HeizBalanceReferenceMetricFailure: Equatable, Sendable {
    enum Reason: Equatable, Sendable {
        case missingActualValue
        case nonFiniteActualValue
        case outsideTolerance(actualValue: Double, expectedValue: Double, tolerance: Double)
    }

    var key: String
    var reason: Reason
}

struct HeizBalanceReferenceCaseValidationResult: Equatable, Sendable {
    var caseID: String
    var failures: [HeizBalanceReferenceMetricFailure]

    var passed: Bool { failures.isEmpty }
}

enum HeizBalanceReferenceCaseValidator {
    static func validate(
        caseID: String,
        expectations: [HeizBalanceReferenceMetricExpectation],
        actualValues: [String: Double]
    ) -> HeizBalanceReferenceCaseValidationResult {
        let failures = expectations.compactMap { expectation -> HeizBalanceReferenceMetricFailure? in
            guard let actual = actualValues[expectation.key] else {
                return .init(key: expectation.key, reason: .missingActualValue)
            }

            guard actual.isFinite else {
                return .init(key: expectation.key, reason: .nonFiniteActualValue)
            }

            let tolerance = max(0, expectation.absoluteTolerance)
            let difference = abs(actual - expectation.expectedValue)
            guard difference <= tolerance else {
                return .init(
                    key: expectation.key,
                    reason: .outsideTolerance(
                        actualValue: actual,
                        expectedValue: expectation.expectedValue,
                        tolerance: tolerance
                    )
                )
            }

            return nil
        }

        return HeizBalanceReferenceCaseValidationResult(caseID: caseID, failures: failures)
    }
}
