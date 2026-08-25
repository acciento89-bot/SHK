import SwiftUI

struct HeizBalanceHydraulicNetworkView: View {
    @Binding var project: HeizBalanceProject
    @State private var message: String?

    private var state: HeizBalanceHydraulicNetworkProjectState {
        project.hydraulicNetworkState()
    }

    private var pathState: HeizBalanceHydraulicNetworkPathProjectState {
        project.hydraulicNetworkPathState()
    }

    private var segments: [HeizBalanceHydraulicNetwork.Segment] {
        project.hydraulicNetwork?.segments ?? []
    }

    private var sharedPipes: [SharedPipeEntry] {
        var rows: [SharedPipeEntry] = []
        for floor in project.floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    for pipe in surface.pipeSections ?? [] where pipe.effectiveRole == .sharedDistribution {
                        rows.append(
                            .init(
                                id: pipe.id,
                                floorName: floor.name,
                                roomName: room.name,
                                surfaceName: surface.name,
                                pipeName: pipe.name,
                                segmentID: pipe.networkSegmentID,
                                storedFlowLPH: pipe.explicitDesignVolumeFlowLPH
                            )
                        )
                    }
                }
            }
        }
        return rows
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Rechenprofil", value: HeizBalanceHydraulicNetworkCalculator.profileVersion)
                LabeledContent("Verbraucher", value: "\(state.consumers.count)")
                LabeledContent("Netzsegmente", value: "\(segments.count)")

                if let result = state.result {
                    LabeledContent("Zugeordnet", value: "\(result.assignedConsumerCount) / \(result.consumerCount)")
                    if let total = result.designTotalConsumerFlowLPH {
                        LabeledContent("Verbraucher-Gesamt-Q") {
                            Text(total.formatted(.number.precision(.fractionLength(0...1))) + " l/h")
                        }
                    } else {
                        LabeledContent("Bekannter Q-Zwischenstand") {
                            Text(result.knownTotalConsumerFlowLPH.formatted(.number.precision(.fractionLength(0...1))) + " l/h")
                        }
                    }
                    if !result.allConsumersAssigned {
                        Label("Nicht alle Heizflächen sind einem Netzsegment zugeordnet.", systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if !segments.isEmpty {
                    Label("Netzbaum ungültig: Zyklus, doppelte Verbraucherzuordnung oder verwaiste Referenz prüfen.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if state.hasStaleLinkedPipes {
                    Label("\(state.staleLinkedPipeCount) verknüpfte Rohrabschnitt(e) haben einen veralteten oder noch offenen Netzbaum-Q.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if !state.linkedPipes.isEmpty {
                    Label("Alle verknüpften Rohrabschnitte entsprechen dem aktuellen Netzbaum-Q.", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Netzstatus")
            } footer: {
                Text("Ein Verbraucher wird genau einem tiefsten Netzsegment zugeordnet. Übergeordnete Segmente erhalten automatisch die Summe aller nachgelagerten Verbraucher und Teilstränge. Unvollständige Verbraucher-Q blockieren den vollständigen Segment-Q.")
            }

            Section {
                LabeledContent("Pfadprofil", value: HeizBalanceHydraulicNetworkPathCalculator.profileVersion)
                LabeledContent("Zentral verknüpfte Shared-Rohre", value: "\(pathState.centralLinkedPipeCount)")
                LabeledContent("Legacy/manuell", value: "\(pathState.unlinkedLegacySharedPipeCount)")

                if pathState.centralPipeModeActive {
                    if pathState.result != nil {
                        Label("Zentraler Pfadmodus aktiv", systemImage: "point.3.connected.trianglepath.dotted")
                            .foregroundStyle(.green)
                    } else {
                        Label("Zentraler Pfadmodus aktiv, aber noch unvollständig", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }

                    NavigationLink {
                        HeizBalanceHydraulicNetworkPathView(project: project)
                    } label: {
                        Label("Netzpfade & Druckverluste", systemImage: "arrow.triangle.branch")
                    }
                } else {
                    Text("Noch kein gemeinsamer Rohrabschnitt ist zentral mit einem Netzsegment verknüpft. Bis dahin gilt die bisherige Legacy-/Manuellogik.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Zentrale Shared-Edge-Hydraulik")
            } footer: {
                Text("Sobald mindestens ein gemeinsamer Rohrabschnitt einem Netzsegment zugeordnet ist, werden alle verknüpften Shared-Rohre je Segment genau einmal gerechnet. Verbraucherpfade erhalten automatisch die Verluste ihrer übergeordneten Netzsegmente plus terminale Heizflächen-Anbindung.")
            }

            Section {
                if segments.isEmpty {
                    Text("Noch keine Netzsegmente angelegt.")
                        .foregroundStyle(.secondary)
                }

                ForEach(segments) { segment in
                    NavigationLink {
                        HeizBalanceHydraulicNetworkSegmentEditor(project: $project, segmentID: segment.id)
                    } label: {
                        segmentRow(segment)
                    }
                }
                .onDelete(perform: deleteSegments)

                Button {
                    addSegment()
                } label: {
                    Label("Netzsegment hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Netzbaum")
            } footer: {
                Text("Beispiel: Hauptstrang → EG / OG → einzelne Heizflächen. Ein zentral verknüpfter gemeinsamer Rohrabschnitt gilt als physischer Netz-Edge und wird nicht mehr pro Verbraucher dupliziert.")
            }

            Section {
                if sharedPipes.isEmpty {
                    Text("Noch keine Rohrabschnitte mit Rolle „Gemeinsame Verteilung“ vorhanden.")
                        .foregroundStyle(.secondary)
                }

                ForEach(sharedPipes) { pipe in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(pipe.roomName + " · " + pipe.surfaceName)
                            .font(.subheadline.weight(.semibold))
                        Text(pipe.floorName + " · " + pipe.pipeName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("Netzsegment", selection: networkSegmentBinding(pipeID: pipe.id)) {
                            Text("Legacy / manueller Q").tag(UUID?.none)
                            ForEach(segments) { segment in
                                Text(segment.name).tag(Optional(segment.id))
                            }
                        }

                        if let segmentID = networkSegmentBinding(pipeID: pipe.id).wrappedValue {
                            let calculated = state.designFlow(segmentID: segmentID)
                            HStack {
                                Text("Zentraler Netz-Q")
                                Spacer()
                                Text(calculated.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen")
                                    .foregroundStyle(calculated == nil ? Color.orange : Color.secondary)
                            }
                            .font(.caption)
                            Text("Dieser Abschnitt wird als zentraler Edge des gewählten Netzsegments genau einmal gerechnet.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else if let flow = pipe.storedFlowLPH {
                            Text("Legacy/manuell: " + flow.formatted(.number.precision(.fractionLength(0...1))) + " l/h")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
            } header: {
                Text("Gemeinsame Rohrabschnitte")
            } footer: {
                Text("Verknüpfte Abschnitte werden zentral gezählt. Nicht verknüpfte gemeinsame Rohre bleiben aus Kompatibilitätsgründen erhalten, werden im zentralen Pfadmodus aber nicht zusätzlich in Verbraucherpfade eingerechnet.")
            }

            Section {
                Button {
                    synchronize(messagePrefix: nil)
                } label: {
                    Label("Netz-Q erneut synchronisieren", systemImage: "arrow.triangle.branch")
                }
                .disabled(state.result == nil || state.linkedPipes.isEmpty)

                if let message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Synchronisieren")
            } footer: {
                Text("Der aktuelle zentrale Pfad-Rechenkern verwendet direkt den berechneten Netz-Q. Die gespeicherten Abschnitts-Q werden zusätzlich synchronisiert, damit ältere Ansichten und gespeicherte Projekte nachvollziehbar bleiben.")
            }
        }
        .navigationTitle("Hydraulischer Netzbaum")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let normalized = project.normalizeHydraulicNetworkReferences()
            let updated = project.applyHydraulicNetworkFlows()
            if normalized + updated > 0 {
                message = "Netzreferenzen bereinigt / aktualisiert: \(normalized + updated) Änderung(en)."
            }
        }
    }

    @ViewBuilder
    private func segmentRow(_ segment: HeizBalanceHydraulicNetwork.Segment) -> some View {
        let flow = state.designFlow(segmentID: segment.id)
        let core = state.result?.segment(id: segment.id.uuidString)
        VStack(alignment: .leading, spacing: 3) {
            Text(segment.name)
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 10) {
                Text("direkt \(segment.directConsumerSurfaceIDs.count)")
                Text("nachgelagert \(core?.downstreamConsumerIDs.count ?? 0)")
                Text(flow.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "Q offen")
            }
            .font(.caption)
            .foregroundStyle(flow == nil ? Color.orange : Color.secondary)
        }
    }

    private func addSegment() {
        if project.hydraulicNetwork == nil {
            project.hydraulicNetwork = HeizBalanceHydraulicNetwork()
        }
        let number = (project.hydraulicNetwork?.segments.count ?? 0) + 1
        project.hydraulicNetwork?.segments.append(.init(name: "Netzsegment \(number)"))
    }

    private func deleteSegments(at offsets: IndexSet) {
        guard var network = project.hydraulicNetwork else { return }
        let ids = Set(offsets.compactMap { index in
            network.segments.indices.contains(index) ? network.segments[index].id : nil
        })
        network.segments.removeAll { ids.contains($0.id) }
        for index in network.segments.indices where network.segments[index].parentSegmentID.map(ids.contains) == true {
            network.segments[index].parentSegmentID = nil
        }
        project.hydraulicNetwork = network
        _ = project.normalizeHydraulicNetworkReferences()
        synchronize(messagePrefix: "Segment entfernt.")
    }

    private func networkSegmentBinding(pipeID: UUID) -> Binding<UUID?> {
        Binding(
            get: { project.networkSegmentID(pipeID: pipeID) },
            set: {
                project.setNetworkSegmentID($0, pipeID: pipeID)
                synchronize(messagePrefix: "Rohrverknüpfung aktualisiert.")
            }
        )
    }

    private func synchronize(messagePrefix: String?) {
        let count = project.applyHydraulicNetworkFlows()
        let tail = count == 0
            ? "Keine zusätzlichen vollständigen Netz-Q zu übernehmen."
            : "\(count) Rohrabschnitt(e) aktualisiert."
        message = [messagePrefix, tail].compactMap { $0 }.joined(separator: " ")
    }

    private struct SharedPipeEntry: Identifiable {
        var id: UUID
        var floorName: String
        var roomName: String
        var surfaceName: String
        var pipeName: String
        var segmentID: UUID?
        var storedFlowLPH: Double?
    }
}

private struct HeizBalanceHydraulicNetworkSegmentEditor: View {
    @Binding var project: HeizBalanceProject
    let segmentID: UUID

    private var segmentBinding: Binding<HeizBalanceHydraulicNetwork.Segment>? {
        guard let index = project.hydraulicNetwork?.segments.firstIndex(where: { $0.id == segmentID }) else { return nil }
        return Binding(
            get: { project.hydraulicNetwork!.segments[index] },
            set: {
                project.hydraulicNetwork!.segments[index] = $0
                _ = project.applyHydraulicNetworkFlows()
            }
        )
    }

    private var consumers: [HeizBalanceHydraulicNetworkConsumerEntry] {
        project.hydraulicNetworkState().consumers
    }

    var body: some View {
        Form {
            if let segmentBinding {
                Section("Segment") {
                    TextField("Bezeichnung", text: segmentBinding.name)
                    Picker("Übergeordnet", selection: segmentBinding.parentSegmentID) {
                        Text("Wurzel / kein Elternsegment").tag(UUID?.none)
                        ForEach(parentCandidates) { candidate in
                            Text(candidate.name).tag(Optional(candidate.id))
                        }
                    }
                    TextField("Notiz", text: segmentBinding.note, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    ForEach(consumers) { consumer in
                        Toggle(isOn: consumerBinding(consumer.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(consumer.displayName)
                                Text(consumer.floorName + " · Q " + (consumer.targetVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Direkte Verbraucher")
                } footer: {
                    Text("Beim Aktivieren wird die Heizfläche aus einem eventuell anderen direkten Segment entfernt und diesem Segment zugeordnet. Übergeordnete Segmente summieren diesen Verbraucher automatisch über die Baumstruktur mit.")
                }
            } else {
                Text("Segment nicht mehr vorhanden.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(segmentBinding?.wrappedValue.name ?? "Netzsegment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var parentCandidates: [HeizBalanceHydraulicNetwork.Segment] {
        let blocked = descendants(of: segmentID).union([segmentID])
        return (project.hydraulicNetwork?.segments ?? []).filter { !blocked.contains($0.id) }
    }

    private func descendants(of id: UUID) -> Set<UUID> {
        let segments = project.hydraulicNetwork?.segments ?? []
        var result = Set<UUID>()
        var frontier = [id]
        while let current = frontier.popLast() {
            let children = segments.filter { $0.parentSegmentID == current }.map(\.id)
            for child in children where result.insert(child).inserted {
                frontier.append(child)
            }
        }
        return result
    }

    private func consumerBinding(_ consumerID: UUID) -> Binding<Bool> {
        Binding(
            get: {
                project.hydraulicNetwork?.segments.first(where: { $0.id == segmentID })?.directConsumerSurfaceIDs.contains(consumerID) == true
            },
            set: { enabled in
                guard var network = project.hydraulicNetwork else { return }
                for index in network.segments.indices {
                    network.segments[index].directConsumerSurfaceIDs.removeAll { $0 == consumerID }
                }
                if enabled,
                   let index = network.segments.firstIndex(where: { $0.id == segmentID }) {
                    network.segments[index].directConsumerSurfaceIDs.append(consumerID)
                }
                project.hydraulicNetwork = network
                _ = project.applyHydraulicNetworkFlows()
            }
        )
    }
}

private extension HeizBalanceProject {
    func networkSegmentID(pipeID: UUID) -> UUID? {
        for floor in floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    if let pipe = (surface.pipeSections ?? []).first(where: { $0.id == pipeID }) {
                        return pipe.networkSegmentID
                    }
                }
            }
        }
        return nil
    }

    mutating func setNetworkSegmentID(_ segmentID: UUID?, pipeID: UUID) {
        for floorIndex in floors.indices {
            for roomIndex in floors[floorIndex].rooms.indices {
                var surfaces = floors[floorIndex].rooms[roomIndex].heatingSurfaces ?? []
                for surfaceIndex in surfaces.indices {
                    var pipes = surfaces[surfaceIndex].pipeSections ?? []
                    if let pipeIndex = pipes.firstIndex(where: { $0.id == pipeID }) {
                        pipes[pipeIndex].networkSegmentID = segmentID
                        if segmentID != nil {
                            pipes[pipeIndex].volumeFlowSource = nil
                        }
                        surfaces[surfaceIndex].pipeSections = pipes
                        floors[floorIndex].rooms[roomIndex].heatingSurfaces = surfaces
                        return
                    }
                }
            }
        }
    }
}
