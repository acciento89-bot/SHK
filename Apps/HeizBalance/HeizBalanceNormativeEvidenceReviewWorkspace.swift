import Foundation
import SwiftUI

struct HeizBalanceNormativeEvidenceReviewWorkspace: View {
    @Environment(HeizBalanceNormativeEvidenceReviewStore.self) private var reviewStore

    let package: HeizBalanceNormativeEvidenceCandidatePackage

    @State private var draft: HeizBalanceNormativeEvidenceReviewRecord
    @State private var didLoadLatest = false
    @State private var saveMessage: String?

    init(package: HeizBalanceNormativeEvidenceCandidatePackage) {
        self.package = package
        _draft = State(initialValue: Self.blankReview(for: package))
    }

    private var assessment: HeizBalanceNormativeEvidenceReviewAssessment {
        HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
            package: package,
            review: draft
        )
    }

    private var history: [HeizBalanceNormativeEvidenceReviewStore.StoredReview] {
        reviewStore.reviews(for: package.identity)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Paket", value: package.identity.displayValue)
                LabeledContent("Einreicher", value: package.submitter)
                LabeledContent("Prüfer getrennt") {
                    statusLabel(
                        assessment.separationOfDutiesSatisfied,
                        success: "Ja",
                        failure: "Nein"
                    )
                }
                LabeledContent("Vorprüfung") {
                    statusLabel(
                        assessment.eligibleForQualificationReview,
                        success: "vollständig",
                        failure: "offen"
                    )
                }
                LabeledContent("Direkter Norm-Gate-Einfluss") {
                    Text("Keiner")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Review-Gate")
            } footer: {
                Text("Auch eine vollständig bestandene Vorprüfung qualifiziert nur für einen späteren, getrennten Qualifikationsschritt. Sie erzeugt keine normative Freigabe.")
            }

            Section("Prüfung") {
                TextField("Prüfer", text: $draft.reviewer)
                    .textInputAutocapitalization(.words)
                TextField("Prüfdatum YYYY-MM-DD", text: $draft.reviewedOn)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(
                    "Notiz",
                    text: Binding(
                        get: { draft.note ?? "" },
                        set: { draft.note = $0.isEmpty ? nil : $0 }
                    ),
                    axis: .vertical
                )
            }

            Section {
                ForEach(package.sources) { source in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(source.document + " · " + source.edition)
                            .font(.subheadline.weight(.semibold))

                        Toggle(
                            "Metadaten unabhängig geprüft",
                            isOn: sourceMetadataBinding(for: source.id)
                        )

                        Toggle(
                            "Rechte-Referenz geprüft",
                            isOn: sourceRightsBinding(for: source.id)
                        )

                        Text(source.id)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Quellen")
            } footer: {
                if assessment.missingSourceReviewIDs.isEmpty && assessment.incompleteSourceReviewIDs.isEmpty {
                    Text("Alle Quellenprüfungen für diese Vorprüfung sind vollständig.")
                } else {
                    Text("Offen/fehlt: " + combinedIDs(
                        assessment.missingSourceReviewIDs,
                        assessment.incompleteSourceReviewIDs
                    ))
                }
            }

            Section {
                if package.specifications.isEmpty {
                    Text("Keine Spezifikationskandidaten")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(package.specifications) { specification in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(specification.moduleID.displayName)
                                .font(.subheadline.weight(.semibold))

                            Toggle(
                                "Quellenpfad geprüft",
                                isOn: specificationTraceabilityBinding(for: specification.id)
                            )

                            TextField(
                                "Unabhängige technische Review-Referenz",
                                text: specificationReviewReferenceBinding(for: specification.id)
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Text(specification.id)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Spezifikationen")
            } footer: {
                if assessment.missingSpecificationReviewIDs.isEmpty && assessment.incompleteSpecificationReviewIDs.isEmpty {
                    Text("Alle Spezifikationsprüfungen für diese Vorprüfung sind vollständig.")
                } else {
                    Text("Offen/fehlt: " + combinedIDs(
                        assessment.missingSpecificationReviewIDs,
                        assessment.incompleteSpecificationReviewIDs
                    ))
                }
            }

            Section {
                if package.referenceCases.isEmpty {
                    Text("Keine Referenzfallkandidaten")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(package.referenceCases) { referenceCase in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(referenceCase.id)
                                .font(.subheadline.weight(.semibold))
                            Text(referenceCase.moduleIDs.map(\.displayName).joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Toggle(
                                "Quellenpfad geprüft",
                                isOn: referenceSourceBinding(for: referenceCase.id)
                            )
                            Toggle(
                                "Unabhängige Herkunft geprüft",
                                isOn: referenceOriginBinding(for: referenceCase.id)
                            )
                            Toggle(
                                "Erwartungswerte übertragen/geprüft",
                                isOn: referenceExpectationBinding(for: referenceCase.id)
                            )

                            TextField(
                                "Unabhängige Review-Referenz",
                                text: referenceReviewReferenceBinding(for: referenceCase.id)
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Referenzfälle")
            } footer: {
                if assessment.missingReferenceCaseReviewIDs.isEmpty && assessment.incompleteReferenceCaseReviewIDs.isEmpty {
                    Text("Alle Referenzfallprüfungen für diese Vorprüfung sind vollständig.")
                } else {
                    Text("Offen/fehlt: " + combinedIDs(
                        assessment.missingReferenceCaseReviewIDs,
                        assessment.incompleteReferenceCaseReviewIDs
                    ))
                }
            }

            if !assessment.structuralIssues.isEmpty {
                Section("Strukturblocker") {
                    ForEach(assessment.structuralIssues, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Button {
                    saveReviewSnapshot()
                } label: {
                    Label("Vorprüfung als Snapshot speichern", systemImage: "checklist.checked")
                }

                if let saveMessage {
                    Text(saveMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let persistenceError = reviewStore.persistenceError {
                    Label(persistenceError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Review-Snapshot")
            } footer: {
                Text("Gespeicherte Reviews sind Vorprüfungs-Snapshots. Änderungen erzeugen eine neue Review-ID; frühere Snapshots werden nicht überschrieben.")
            }

            Section {
                if history.isEmpty {
                    Text("Noch keine gespeicherten Vorprüfungen")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history) { stored in
                        let storedAssessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
                            package: package,
                            review: stored.review
                        )
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(stored.review.reviewer)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(storedAssessment.eligibleForQualificationReview ? "vollständig" : "offen")
                                    .font(.caption)
                                    .foregroundStyle(storedAssessment.eligibleForQualificationReview ? .green : .orange)
                            }
                            Text(stored.review.reviewedOn + " · " + stored.review.id)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                            Text("Norm-Gate-Einfluss: keiner")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Review-Verlauf")
            }
        }
        .navigationTitle("Evidenz-Vorprüfung")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadLatestOnce()
        }
    }

    @ViewBuilder
    private func statusLabel(_ value: Bool, success: String, failure: String) -> some View {
        if value {
            Label(success, systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Label(failure, systemImage: "xmark.circle.fill")
                .foregroundStyle(.orange)
        }
    }

    private func loadLatestOnce() {
        guard !didLoadLatest else { return }
        didLoadLatest = true

        guard let latest = reviewStore.latestReview(for: package.identity) else { return }
        var next = latest.review
        next.id = Self.makeReviewID()
        next.reviewedOn = Self.todayString()
        draft = next
    }

    private func saveReviewSnapshot() {
        do {
            let stored = try reviewStore.appendReview(draft, for: package)
            let storedAssessment = HeizBalanceNormativeEvidenceReviewEvaluator.evaluate(
                package: package,
                review: stored.review
            )
            saveMessage = storedAssessment.eligibleForQualificationReview
                ? "Vorprüfung gespeichert · bereit für spätere Qualifikationsprüfung · kein Norm-Gate-Einfluss"
                : "Vorprüfung gespeichert · weiterhin offen · kein Norm-Gate-Einfluss"
            draft.id = Self.makeReviewID()
        } catch {
            saveMessage = "Speichern fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    private func sourceMetadataBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: {
                draft.sourceReviews.first(where: { $0.sourceID == id })?.metadataChecked ?? false
            },
            set: { value in
                guard let index = draft.sourceReviews.firstIndex(where: { $0.sourceID == id }) else { return }
                draft.sourceReviews[index].metadataChecked = value
            }
        )
    }

    private func sourceRightsBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: {
                draft.sourceReviews.first(where: { $0.sourceID == id })?.rightsReferenceChecked ?? false
            },
            set: { value in
                guard let index = draft.sourceReviews.firstIndex(where: { $0.sourceID == id }) else { return }
                draft.sourceReviews[index].rightsReferenceChecked = value
            }
        )
    }

    private func specificationTraceabilityBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: {
                draft.specificationReviews.first(where: { $0.specificationID == id })?.sourceTraceabilityChecked ?? false
            },
            set: { value in
                guard let index = draft.specificationReviews.firstIndex(where: { $0.specificationID == id }) else { return }
                draft.specificationReviews[index].sourceTraceabilityChecked = value
            }
        )
    }

    private func specificationReviewReferenceBinding(for id: String) -> Binding<String> {
        Binding(
            get: {
                draft.specificationReviews.first(where: { $0.specificationID == id })?.independentTechnicalReviewReference ?? ""
            },
            set: { value in
                guard let index = draft.specificationReviews.firstIndex(where: { $0.specificationID == id }) else { return }
                draft.specificationReviews[index].independentTechnicalReviewReference = value.isEmpty ? nil : value
            }
        )
    }

    private func referenceSourceBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: {
                draft.referenceCaseReviews.first(where: { $0.referenceCaseID == id })?.sourceTraceabilityChecked ?? false
            },
            set: { value in
                guard let index = draft.referenceCaseReviews.firstIndex(where: { $0.referenceCaseID == id }) else { return }
                draft.referenceCaseReviews[index].sourceTraceabilityChecked = value
            }
        )
    }

    private func referenceOriginBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: {
                draft.referenceCaseReviews.first(where: { $0.referenceCaseID == id })?.independentOriginChecked ?? false
            },
            set: { value in
                guard let index = draft.referenceCaseReviews.firstIndex(where: { $0.referenceCaseID == id }) else { return }
                draft.referenceCaseReviews[index].independentOriginChecked = value
            }
        )
    }

    private func referenceExpectationBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: {
                draft.referenceCaseReviews.first(where: { $0.referenceCaseID == id })?.expectationTranscriptionChecked ?? false
            },
            set: { value in
                guard let index = draft.referenceCaseReviews.firstIndex(where: { $0.referenceCaseID == id }) else { return }
                draft.referenceCaseReviews[index].expectationTranscriptionChecked = value
            }
        )
    }

    private func referenceReviewReferenceBinding(for id: String) -> Binding<String> {
        Binding(
            get: {
                draft.referenceCaseReviews.first(where: { $0.referenceCaseID == id })?.independentReviewReference ?? ""
            },
            set: { value in
                guard let index = draft.referenceCaseReviews.firstIndex(where: { $0.referenceCaseID == id }) else { return }
                draft.referenceCaseReviews[index].independentReviewReference = value.isEmpty ? nil : value
            }
        )
    }

    private func combinedIDs(_ first: [String], _ second: [String]) -> String {
        Array(Set(first + second)).sorted().joined(separator: ", ")
    }

    private static func blankReview(
        for package: HeizBalanceNormativeEvidenceCandidatePackage
    ) -> HeizBalanceNormativeEvidenceReviewRecord {
        .init(
            schema: HeizBalanceNormativeEvidenceReviewRecord.schemaVersion,
            id: makeReviewID(),
            packageIdentity: package.identity,
            reviewer: "",
            reviewedOn: todayString(),
            sourceReviews: package.sources.map {
                .init(
                    sourceID: $0.id,
                    metadataChecked: false,
                    rightsReferenceChecked: false,
                    note: nil
                )
            },
            specificationReviews: package.specifications.map {
                .init(
                    specificationID: $0.id,
                    sourceTraceabilityChecked: false,
                    independentTechnicalReviewReference: nil,
                    note: nil
                )
            },
            referenceCaseReviews: package.referenceCases.map {
                .init(
                    referenceCaseID: $0.id,
                    sourceTraceabilityChecked: false,
                    independentOriginChecked: false,
                    expectationTranscriptionChecked: false,
                    independentReviewReference: nil,
                    note: nil
                )
            },
            note: nil
        )
    }

    private static func makeReviewID() -> String {
        "review-" + UUID().uuidString.lowercased()
    }

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
