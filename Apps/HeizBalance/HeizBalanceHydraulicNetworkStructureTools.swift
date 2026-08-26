import SwiftUI

struct HeizBalanceHydraulicNetworkStructureToolsView: View {
    @Binding var project: HeizBalanceProject

    private var segments: [HeizBalanceHydraulicNetwork.Segment] {
        project.hydraulicNetwork?.segments ?? []
    }

    private var segmentNameByID: [UUID: String] {
        Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0.name) })
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Netzsegmente", value: "\(segments.count)")
                Text("Verschieben ändert nur die Elternbeziehung des gewählten Teilbaums. Duplizieren erzeugt dagegen eine reine Strukturkopie mit neuen IDs und ohne übernommene Verbraucher-, Rohr- oder Δp-Entscheidungen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sichere Strukturänderungen")
            } footer: {
                Text("Damit keine fertige hydraulische Entscheidung versehentlich auf einen anderen Strang übertragen wird, werden bei einer Kopie direkte Verbraucher, gemeinsame Rohrgeometrie, zentrale Bauteile, deren Δp-Werte und die Vollständigkeitsbestätigung zurückgesetzt.")
            }

            Section {
                if segments.isEmpty {
                    Text("Noch keine Netzsegmente vorhanden.")
                        .foregroundStyle(.secondary)
                }

                ForEach(segments) { segment in
                    NavigationLink {
                        HeizBalanceHydraulicNetworkStructureSegmentView(
                            project: $project,
                            segmentID: segment.id
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(segment.name)
                                .font(.subheadline.weight(.semibold))

                            HStack(spacing: 10) {
                                Text(parentLabel(for: segment))
                                Text("direkt \(segment.directConsumerSurfaceIDs.count)")
                                Text("Kinder \(childCount(of: segment.id))")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            } header: {
                Text("Segmente / Teilbäume")
            } footer: {
                Text("Öffne ein Segment, um seinen kompletten Teilbaum sicher an eine andere Stelle zu verschieben oder als leere Strukturvorlage zu duplizieren.")
            }
        }
        .navigationTitle("Netzbaum-Struktur")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func parentLabel(for segment: HeizBalanceHydraulicNetwork.Segment) -> String {
        guard let parentID = segment.parentSegmentID else { return "Wurzel" }
        return "unter " + (segmentNameByID[parentID] ?? "unbekannt")
    }

    private func childCount(of segmentID: UUID) -> Int {
        segments.filter { $0.parentSegmentID == segmentID }.count
    }
}

private struct HeizBalanceHydraulicNetworkStructureSegmentView: View {
    @Binding var project: HeizBalanceProject
    let segmentID: UUID

    @State private var message: String?
    @State private var showingDuplicateConfirmation = false

    private var segments: [HeizBalanceHydraulicNetwork.Segment] {
        project.hydraulicNetwork?.segments ?? []
    }

    private var segment: HeizBalanceHydraulicNetwork.Segment? {
        segments.first { $0.id == segmentID }
    }

    private var descriptors: [HeizBalanceHydraulicNetworkTreeEditing.Segment] {
        segments.map {
            .init(
                id: $0.id.uuidString,
                parentSegmentID: $0.parentSegmentID?.uuidString
            )
        }
    }

    private var subtreeIDs: Set<UUID> {
        guard let ids = HeizBalanceHydraulicNetworkTreeEditing.subtreeIDs(
            rootID: segmentID.uuidString,
            segments: descriptors
        ) else {
            return []
        }
        return Set(ids.compactMap(UUID.init(uuidString:)))
    }

    private var validParentSegments: [HeizBalanceHydraulicNetwork.Segment] {
        guard let validIDs = HeizBalanceHydraulicNetworkTreeEditing.validParentIDs(
            rootID: segmentID.uuidString,
            segments: descriptors
        ) else {
            return []
        }
        let idSet = Set(validIDs)
        return segments
            .filter { idSet.contains($0.id.uuidString) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var descendantCount: Int {
        max(0, subtreeIDs.count - 1)
    }

    private var subtreeConsumerCount: Int {
        segments
            .filter { subtreeIDs.contains($0.id) }
            .reduce(0) { $0 + $1.directConsumerSurfaceIDs.count }
    }

    private var subtreePipeCount: Int {
        segments
            .filter { subtreeIDs.contains($0.id) }
            .reduce(0) { $0 + ($1.pipeSections ?? []).count }
    }

    private var subtreeComponentCount: Int {
        segments
            .filter { subtreeIDs.contains($0.id) }
            .reduce(0) { $0 + ($1.hydraulicLossComponents ?? []).count }
    }

    var body: some View {
        Form {
            if let segment {
                Section {
                    LabeledContent("Segment", value: segment.name)
                    LabeledContent("Untersegmente", value: "\(descendantCount)")
                    LabeledContent("Direkte Verbraucher im Teilbaum", value: "\(subtreeConsumerCount)")
                    LabeledContent("Gemeinsame Rohre im Teilbaum", value: "\(subtreePipeCount)")
                    LabeledContent("Zentrale Bauteile im Teilbaum", value: "\(subtreeComponentCount)")
                } header: {
                    Text("Teilbaum")
                }

                Section {
                    Picker("Elternsegment", selection: parentBinding) {
                        Text("Kein Elternsegment / Wurzel").tag(UUID?.none)
                        ForEach(validParentSegments) { candidate in
                            Text(candidate.name).tag(Optional(candidate.id))
                        }
                    }

                    Text("Beim Verschieben bleiben IDs, direkte Verbraucher, Rohrgeometrie, zentrale Bauteile und dokumentierte Δp-Werte unverändert. Nur die Elternbeziehung dieses Teilbaum-Wurzelsegments wird geändert.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Teilbaum verschieben")
                } footer: {
                    Text("Das eigene Segment und alle seine Nachfolger werden als Ziel automatisch ausgeschlossen. Dadurch kann kein Zyklus entstehen.")
                }

                Section {
                    Button {
                        showingDuplicateConfirmation = true
                    } label: {
                        Label("Teilbaumstruktur duplizieren", systemImage: "plus.square.on.square")
                    }

                    Text("Die Kopie erhält für jedes Segment eine neue ID. Namen und Hierarchie werden übernommen; direkte Verbraucher, gemeinsame Rohrabschnitte, zentrale Armaturen/Bauteile, Δp-Werte, Vollständigkeitsbestätigungen und projektspezifische Notizen werden nicht kopiert.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Sichere Strukturkopie")
                } footer: {
                    Text("Nach dem Kopieren muss der neue Teilbaum fachlich neu aufgenommen und mit den realen Verbrauchern verknüpft werden.")
                }

                if let message {
                    Section("Status") {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Segment nicht mehr vorhanden",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .navigationTitle(segment?.name ?? "Netzsegment")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Teilbaumstruktur duplizieren?",
            isPresented: $showingDuplicateConfirmation,
            titleVisibility: .visible
        ) {
            Button("Struktur sicher duplizieren") {
                duplicateSubtree()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Es werden neue Segment-IDs erzeugt. Verbraucher, Rohre, zentrale Bauteile, Δp-Werte und Vollständigkeitsentscheidungen bleiben absichtlich leer.")
        }
    }

    private var parentBinding: Binding<UUID?> {
        Binding(
            get: { segment?.parentSegmentID },
            set: { newParentID in
                guard project.moveHydraulicNetworkSubtree(
                    rootSegmentID: segmentID,
                    toParentID: newParentID
                ) else {
                    message = "Verschieben abgelehnt: Ziel würde den Netzbaum ungültig machen."
                    return
                }
                let parentName = newParentID
                    .flatMap { id in project.hydraulicNetwork?.segments.first(where: { $0.id == id })?.name }
                    ?? "Wurzel"
                message = "Teilbaum sicher unter „\(parentName)“ verschoben."
            }
        )
    }

    private func duplicateSubtree() {
        guard let newRootID = project.duplicateHydraulicNetworkSubtreeStructure(
            rootSegmentID: segmentID
        ),
        let newRootName = project.hydraulicNetwork?.segments.first(where: { $0.id == newRootID })?.name else {
            message = "Teilbaum konnte nicht dupliziert werden. Netzstruktur prüfen."
            return
        }

        message = "„\(newRootName)“ wurde als sichere leere Strukturkopie angelegt."
    }
}

extension HeizBalanceProject {
    @discardableResult
    mutating func moveHydraulicNetworkSubtree(
        rootSegmentID: UUID,
        toParentID parentID: UUID?
    ) -> Bool {
        guard var network = hydraulicNetwork else { return false }
        let descriptors = network.segments.map {
            HeizBalanceHydraulicNetworkTreeEditing.Segment(
                id: $0.id.uuidString,
                parentSegmentID: $0.parentSegmentID?.uuidString
            )
        }

        guard HeizBalanceHydraulicNetworkTreeEditing.canMove(
            rootID: rootSegmentID.uuidString,
            toParentID: parentID?.uuidString,
            segments: descriptors
        ),
        let index = network.segments.firstIndex(where: { $0.id == rootSegmentID }) else {
            return false
        }

        network.segments[index].parentSegmentID = parentID
        hydraulicNetwork = network
        _ = normalizeHydraulicNetworkReferences()
        _ = applyHydraulicNetworkFlows()
        return true
    }

    @discardableResult
    mutating func duplicateHydraulicNetworkSubtreeStructure(
        rootSegmentID: UUID
    ) -> UUID? {
        guard var network = hydraulicNetwork else { return nil }
        let descriptors = network.segments.map {
            HeizBalanceHydraulicNetworkTreeEditing.Segment(
                id: $0.id.uuidString,
                parentSegmentID: $0.parentSegmentID?.uuidString
            )
        }
        guard let subtreeStringIDs = HeizBalanceHydraulicNetworkTreeEditing.subtreeIDs(
            rootID: rootSegmentID.uuidString,
            segments: descriptors
        ) else {
            return nil
        }

        let subtreeIDs = Set(subtreeStringIDs.compactMap(UUID.init(uuidString:)))
        let sourceSegments = network.segments.filter { subtreeIDs.contains($0.id) }
        guard sourceSegments.contains(where: { $0.id == rootSegmentID }) else { return nil }

        let newIDByOldID = Dictionary(
            uniqueKeysWithValues: sourceSegments.map { ($0.id, UUID()) }
        )
        guard let newRootID = newIDByOldID[rootSegmentID] else { return nil }

        var existingNames = Set(network.segments.map(\.name))
        var copies: [HeizBalanceHydraulicNetwork.Segment] = []
        copies.reserveCapacity(sourceSegments.count)

        for source in sourceSegments {
            guard let newID = newIDByOldID[source.id] else { return nil }
            var copy = source
            copy.id = newID
            copy.name = uniqueHydraulicSegmentCopyName(
                sourceName: source.name,
                existingNames: &existingNames
            )

            if source.id == rootSegmentID {
                copy.parentSegmentID = source.parentSegmentID
            } else if let oldParentID = source.parentSegmentID {
                guard let mappedParentID = newIDByOldID[oldParentID] else { return nil }
                copy.parentSegmentID = mappedParentID
            } else {
                copy.parentSegmentID = nil
            }

            // A duplicated network branch is only a topology/capture template.
            // Project-specific hydraulic decisions must be recorded again.
            copy.directConsumerSurfaceIDs = []
            copy.pipeSections = nil
            copy.hydraulicLossComponents = nil
            copy.hydraulicComponentAssessmentComplete = nil
            copy.note = ""
            copies.append(copy)
        }

        network.segments.append(contentsOf: copies)
        hydraulicNetwork = network
        _ = normalizeHydraulicNetworkReferences()
        _ = applyHydraulicNetworkFlows()
        return newRootID
    }

    private func uniqueHydraulicSegmentCopyName(
        sourceName: String,
        existingNames: inout Set<String>
    ) -> String {
        let trimmed = sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Netzsegment" : trimmed
        var candidate = base + " Kopie"
        var number = 2

        while existingNames.contains(candidate) {
            candidate = base + " Kopie \(number)"
            number += 1
        }
        existingNames.insert(candidate)
        return candidate
    }
}
