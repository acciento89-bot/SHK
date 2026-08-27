import Foundation

struct HeizBalanceNormativeQualificationRunnerDescriptor: Equatable, Sendable {
    var runnerID: String
    var runnerVersion: String
    var engineID: HeizBalanceCalculationEngineID
    var implementationFingerprint: String

    var isStructurallyValid: Bool {
        !runnerID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !runnerVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !implementationFingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct HeizBalanceNormativeQualificationExecutionRequest: Equatable, Sendable {
    var packageIdentity: HeizBalanceNormativeEvidenceCandidatePackage.Identity
    var reviewID: String
    var engineID: HeizBalanceCalculationEngineID
    var referenceCaseID: String
    var caseReference: String
    var moduleIDs: [HeizBalanceNormativeModuleID]
}

struct HeizBalanceNormativeQualificationMetric: Equatable, Sendable {
    var key: String
    var value: Double
}

protocol HeizBalanceNormativeQualificationRunner {
    var descriptor: HeizBalanceNormativeQualificationRunnerDescriptor { get }

    /// Executes a reference case without receiving the candidate package's expected values.
    /// The runner must resolve the independently reviewed fixture from `caseReference`.
    func execute(
        request: HeizBalanceNormativeQualificationExecutionRequest
    ) throws -> [HeizBalanceNormativeQualificationMetric]
}

struct HeizBalanceNormativeQualificationExecutionArtifact: Equatable, Sendable {
    var packageIdentity: HeizBalanceNormativeEvidenceCandidatePackage.Identity
    var reviewID: String
    var runner: HeizBalanceNormativeQualificationRunnerDescriptor
    var referenceCaseID: String
    var caseReference: String
    var moduleIDs: [HeizBalanceNormativeModuleID]
    var metrics: [HeizBalanceNormativeQualificationMetric]
}

struct HeizBalanceNormativeQualificationCaseResult: Equatable, Sendable {
    var referenceCaseID: String
    var artifact: HeizBalanceNormativeQualificationExecutionArtifact?
    var validation: HeizBalanceReferenceCaseValidationResult?
    var duplicateActualMetricKeys: [String]
    var unexpectedActualMetricKeys: [String]
    var executionError: String?

    var passed: Bool {
        artifact != nil
            && validation?.passed == true
            && duplicateActualMetricKeys.isEmpty
            && unexpectedActualMetricKeys.isEmpty
            && executionError == nil
    }
}

struct HeizBalanceNormativeQualificationReport: Equatable, Sendable {
    var packageIdentity: HeizBalanceNormativeEvidenceCandidatePackage.Identity
    var reviewID: String
    var runner: HeizBalanceNormativeQualificationRunnerDescriptor
    var structuralIssues: [String]
    var reviewEligible: Bool
    var caseResults: [HeizBalanceNormativeQualificationCaseResult]

    var allReferenceCasesExecuted: Bool {
        !caseResults.isEmpty
            && caseResults.allSatisfy { $0.artifact != nil && $0.executionError == nil }
    }

    var technicalQualificationPassed: Bool {
        structuralIssues.isEmpty
            && reviewEligible
            && allReferenceCasesExecuted
            && caseResults.allSatisfy(\.passed)
    }

    /// Batch 45 deliberately stops before evidence acceptance/promotion.
    /// Even a technically passing controlled run cannot feed normative readiness directly.
    var canAffectNormativeReadiness: Bool { false }
}

enum HeizBalanceNormativeQualificationHarness {
    static func run<Runner: HeizBalanceNormativeQualificationRunner>(
        package: HeizBalanceNormativeEvidenceCandidatePackage,
        review: HeizBalanceNormativeEvidenceReviewRecord,
        runner: Runner
    ) -> HeizBalanceNormativeQualificationReport {
        let reviewAssessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
            package: package,
            review: review
        )

        var structuralIssues: [String] = []
        let descriptor = runner.descriptor

        if !descriptor.isStructurallyValid {
            structuralIssues.append("Runner-Identität, Version oder Implementierungs-Fingerprint fehlt")
        }
        if descriptor.engineID != package.targetEngineID {
            structuralIssues.append("Runner-Engine stimmt nicht mit dem Evidenzpaket überein")
        }
        if review.packageIdentity != package.identity {
            structuralIssues.append("Review gehört nicht exakt zur ausgeführten Paketrevision")
        }
        if review.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            structuralIssues.append("Review-ID für Qualifikationslauf fehlt")
        }
        if package.referenceCases.isEmpty {
            structuralIssues.append("Keine ausführbaren Referenzfälle im Evidenzpaket")
        }

        guard structuralIssues.isEmpty, reviewAssessment.eligibleForQualificationReview else {
            return .init(
                packageIdentity: package.identity,
                reviewID: review.id,
                runner: descriptor,
                structuralIssues: structuralIssues,
                reviewEligible: reviewAssessment.eligibleForQualificationReview,
                caseResults: []
            )
        }

        let caseResults = package.referenceCases.map { referenceCase in
            execute(
                package: package,
                review: review,
                referenceCase: referenceCase,
                runner: runner
            )
        }

        return .init(
            packageIdentity: package.identity,
            reviewID: review.id,
            runner: descriptor,
            structuralIssues: structuralIssues,
            reviewEligible: true,
            caseResults: caseResults
        )
    }

    private static func execute<Runner: HeizBalanceNormativeQualificationRunner>(
        package: HeizBalanceNormativeEvidenceCandidatePackage,
        review: HeizBalanceNormativeEvidenceReviewRecord,
        referenceCase: HeizBalanceNormativeEvidenceCandidatePackage.ReferenceCaseCandidate,
        runner: Runner
    ) -> HeizBalanceNormativeQualificationCaseResult {
        let request = HeizBalanceNormativeQualificationExecutionRequest(
            packageIdentity: package.identity,
            reviewID: review.id,
            engineID: package.targetEngineID,
            referenceCaseID: referenceCase.id,
            caseReference: referenceCase.caseReference,
            moduleIDs: referenceCase.moduleIDs
        )

        do {
            let metrics = try runner.execute(request: request)
            let metricKeys = metrics.map { $0.key.trimmingCharacters(in: .whitespacesAndNewlines) }
            let duplicateKeys = duplicateValues(metricKeys)

            var actualValues: [String: Double] = [:]
            for metric in metrics where !metric.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let key = metric.key.trimmingCharacters(in: .whitespacesAndNewlines)
                if actualValues[key] == nil {
                    actualValues[key] = metric.value
                }
            }

            let expectedKeys = Set(referenceCase.expectations.map { $0.key })
            let actualKeys = Set(metricKeys.filter { !$0.isEmpty })
            let unexpectedKeys = actualKeys.subtracting(expectedKeys).sorted()

            let expectations = referenceCase.expectations.map {
                HeizBalanceReferenceMetricExpectation(
                    key: $0.key,
                    expectedValue: $0.expectedValue,
                    absoluteTolerance: $0.absoluteTolerance
                )
            }
            let validation = HeizBalanceReferenceCaseValidator.validate(
                caseID: referenceCase.id,
                expectations: expectations,
                actualValues: actualValues
            )
            let artifact = HeizBalanceNormativeQualificationExecutionArtifact(
                packageIdentity: package.identity,
                reviewID: review.id,
                runner: runner.descriptor,
                referenceCaseID: referenceCase.id,
                caseReference: referenceCase.caseReference,
                moduleIDs: referenceCase.moduleIDs,
                metrics: metrics
            )

            return .init(
                referenceCaseID: referenceCase.id,
                artifact: artifact,
                validation: validation,
                duplicateActualMetricKeys: duplicateKeys,
                unexpectedActualMetricKeys: unexpectedKeys,
                executionError: nil
            )
        } catch {
            return .init(
                referenceCaseID: referenceCase.id,
                artifact: nil,
                validation: nil,
                duplicateActualMetricKeys: [],
                unexpectedActualMetricKeys: [],
                executionError: error.localizedDescription
            )
        }
    }

    private static func duplicateValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var duplicates = Set<String>()
        for value in values where !value.isEmpty {
            if !seen.insert(value).inserted {
                duplicates.insert(value)
            }
        }
        return duplicates.sorted()
    }
}

enum HeizBalanceNormativeQualificationProductionAvailability: Equatable, Sendable {
    case unavailable(reason: String)

    var isRunnerRegistered: Bool { false }

    var reason: String {
        switch self {
        case .unavailable(let reason): reason
        }
    }
}

enum HeizBalanceNormativeQualificationProductionRegistry {
    /// There is intentionally no production normative runner in Batch 45.
    /// The reserved engine has no formula implementation or executable independent fixtures yet.
    static func availability(
        for engineID: HeizBalanceCalculationEngineID
    ) -> HeizBalanceNormativeQualificationProductionAvailability {
        switch engineID {
        case .technicalPreviewV1:
            .unavailable(reason: "Technische Vorberechnung ist kein Normprofil.")
        case .deRoomHeatLoad2017_2020:
            .unavailable(
                reason: "Kein produktiver Norm-Qualifikationsrunner registriert. Ausführbare, unabhängig geprüfte Referenzfixtures und die normative Engine sind noch nicht freigegeben."
            )
        }
    }
}
