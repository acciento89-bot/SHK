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

    private var legacySharedPipes: [SharedPipeEntry] {
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
                    Label("\(state.staleLinkedPipeCount) Legacy-Rohrverknüpfung(en) haben einen veralteten oder offenen Netz-Q.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Netzstatus")
            } footer: {
                Text("Ein Verbraucher wird genau einem tiefsten Netzsegment zugeordnet. Übergeordnete Segmente erhalten automatisch die Summe aller nachgelagerten Verbraucher. Gemeinsame Rohrgeometrie und zentrale Bauteilverluste werden direkt am Netzsegment erfasst.")
            }

            Section {
                LabeledContent("Pfadprofil", value: HeizBalanceHydraulicNetworkPathCalculator.profileVersion)
                LabeledContent("Rohr direkt am Netzsegment", value: "\(pathState.segmentOwnedPipeCount)")
                LabeledContent("Zentrale Bauteile", value: "\(pathState.segmentOwnedComponentCount)")
                LabeledContent("Legacy verknüpft", value: "\(pathState.centralLinkedPipeCount)")
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
                    Text("Noch keine gemeinsame Rohrgeometrie oder zentrale Bauteilverluste im Netzbaum erfasst. Öffne ein Netzsegment und erfasse dort die reale gemeinsame Strecke.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Zentrale Shared-Path-Hydraulik")
            } footer: {
                Text("Segment-eigene Rohrabschnitte und explizite zentrale Bauteilverluste werden genau einmal seriell in jedem betroffenen Verbraucherpfad berücksichtigt. Der Segment-Q stammt immer aus den nachgelagerten Verbrauchern.")
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
                Text("Netzbaum, Rohre & Bauteile")
            } footer: {
                Text("Beispiel: Hauptstrang → EG / OG → einzelne Heizflächen. Öffne ein Segment, um seine gemeinsamen Rohre und realen zentralen Armaturen direkt dort zu erfassen.")
            }

            if !legacySharedPipes.isEmpty {
                Section {
                    ForEach(legacySharedPipes) { pipe in
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
                                    Text("Netz-Q")
                                    Spacer()
                                    Text(calculated.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen")
                                        .foregroundStyle(calculated == nil ? Color.orange : Color.secondary)
                                }
                                .font(.caption)
                                Text("Altformat: Der Abschnitt liegt noch unter einer Heizfläche. Nach der Migration liegt dieselbe Geometrie direkt im Netzsegment.")
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

                    if !state.linkedPipes.isEmpty {
                        Button {
                            migrateLegacyLinkedPipes()
                        } label: {
                            Label("Verknüpfte Alt-Rohre in Netzsegmente verschieben", systemImage: "arrow.right.doc.on.clipboard")
                        }
                    }
                } header: {
                    Text("Legacy-Rohrabschnitte")
                } footer: {
                    Text("Migration erhält Bezeichnung, Innendurchmesser, Länge, Rauheit, ζ und Notiz. Der gespeicherte Alt-Q entfällt absichtlich, weil der Segment-Q ab dann immer live aus den zugeordneten Verbrauchern berechnet wird. Unverknüpfte Alt-Rohre werden nicht automatisch verschoben.")
                }
            }

            if !state.linkedPipes.isEmpty {
                Section {
                    Button {
                        synchronize(messagePrefix: nil)
                    } label: {
                        Label("Legacy-Netz-Q erneut synchronisieren", systemImage: "arrow.triangle.branch")
                    }
                    .disabled(state.result == nil)

                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Legacy-Synchronisierung")
                } footer: {
                    Text("Nur alte verknüpfte Heizflächen-Rohre speichern noch einen Q-Wert. Neue segment-eigene Rohrabschnitte verwenden ausschließlich den aktuell berechneten Segment-Q und benötigen keine Synchronisierung.")
                }
            } else if let message {
                Section {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                Text("Rohr \((segment.pipeSections ?? []).count)")
                Text("Bauteil \((segment.hydraulicLossComponents ?? []).count)")
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
                synchronize(messagePrefix: "Legacy-Rohrverknüpfung aktualisiert.")
            }
        )
    }

    private func synchronize(messagePrefix: String?) {
        let count = project.applyHydraulicNetworkFlows()
        let tail = count == 0
            ? "Keine zusätzlichen vollständigen Legacy-Netz-Q zu übernehmen."
            : "\(count) Legacy-Rohrabschnitt(e) aktualisiert."
        message = [messagePrefix, tail].compactMap { $0 }.joined(separator: " ")
    }

    private func migrateLegacyLinkedPipes() {
        let count = project.migrateLinkedSharedPipesIntoNetworkSegments()
        if count == 0 {
            message = "Keine verknüpften Alt-Rohre zu migrieren."
        } else {
            message = "\(count) Alt-Rohrabschnitt(e) ohne Datenverlust in die zugehörigen Netzsegmente verschoben."
        }
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
                _ = project.normalizeHydraulicNetworkReferences()
                _ = project.applyHydraulicNetworkFlows()
            }
        )
    }

    private var segmentPipeSectionsBinding: Binding<[HeizBalancePipeSection]>? {
        guard let segmentBinding else { return nil }
        return Binding(
            get: { segmentBinding.wrappedValue.pipeSections ?? [] },
            set: { newValue in
                var segment = segmentBinding.wrappedValue
                segment.pipeSections = newValue
                segmentBinding.wrappedValue = segment
            }
        )
    }

    private var segmentComponentsBinding: Binding<[HeizBalanceHydraulicLossComponent]>? {
        guard let segmentBinding else { return nil }
        return Binding(
            get: { segmentBinding.wrappedValue.hydraulicLossComponents ?? [] },
            set: { newValue in
                var segment = segmentBinding.wrappedValue
                if newValue.isEmpty {
                    segment.hydraulicLossComponents = nil
                    segment.hydraulicComponentAssessmentComplete = nil
                } else {
                    segment.hydraulicLossComponents = newValue
                    segment.hydraulicComponentAssessmentComplete = false
                }
                segmentBinding.wrappedValue = segment
            }
        )
    }

    private var componentAssessmentBinding: Binding<Bool>? {
        guard let segmentBinding else { return nil }
        return Binding(
            get: { segmentBinding.wrappedValue.hydraulicComponentAssessmentComplete == true },
            set: { newValue in
                var segment = segmentBinding.wrappedValue
                segment.hydraulicComponentAssessmentComplete = newValue
                segmentBinding.wrappedValue = segment
            }
        )
    }

    private var consumers: [HeizBalanceHydraulicNetworkConsumerEntry] {
        project.hydraulicNetworkState().consumers
    }

    private var segmentFlowLPH: Double? {
        project.hydraulicNetworkState().designFlow(segmentID: segmentID)
    }

    private var segmentPathResult: HeizBalanceHydraulicNetworkPathCalculator.SegmentResult? {
        project.hydraulicNetworkPathState().result?.segment(id: segmentID.uuidString)
    }

    private var componentValuesComplete: Bool {
        let components = segmentComponentsBinding?.wrappedValue ?? []
        return components.allSatisfy { component in
            guard let loss = component.pressureLossKPa else { return false }
            return loss.isFinite && loss >= 0
        }
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
                    if let flow = segmentFlowLPH {
                        LabeledContent("Automatischer Segment-Q") {
                            Text(flow.formatted(.number.precision(.fractionLength(0...1))) + " l/h")
                                .fontWeight(.semibold)
                        }
                    } else {
                        LabeledContent("Automatischer Segment-Q", value: "offen")
                    }

                    if let path = segmentPathResult {
                        LabeledContent("Bekannter Rohr-Δp") {
                            Text(path.knownPipePressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                        }
                        LabeledContent("Bekannter Bauteil-Δp") {
                            Text(path.knownComponentPressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                        }
                        if let complete = path.completePressureLossKPa {
                            LabeledContent("Segment-Δp") {
                                Text(complete.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                                    .fontWeight(.semibold)
                            }
                        } else if path.knownPressureLossKPa > 0 {
                            LabeledContent("Bekannter Δp-Zwischenstand") {
                                Text(path.knownPressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    if let pipeSectionsBinding = segmentPipeSectionsBinding {
                        if pipeSectionsBinding.wrappedValue.isEmpty {
                            Text("Noch keine gemeinsame Rohrgeometrie in diesem Segment.")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(pipeSectionsBinding) { $pipe in
                            NavigationLink {
                                HeizBalanceHydraulicNetworkSegmentPipeEditor(
                                    section: $pipe,
                                    segmentName: segmentBinding.wrappedValue.name,
                                    segmentVolumeFlowLPH: segmentFlowLPH
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pipe.name)
                                    HStack(spacing: 8) {
                                        Text(pipe.innerDiameterMM.map { "ID " + $0.formatted(.number.precision(.fractionLength(0...1))) + " mm" } ?? "ID offen")
                                        Text(pipe.lengthM.map { $0.formatted(.number.precision(.fractionLength(0...2))) + " m" } ?? "Länge offen")
                                        Text(pipe.zetaTotal.map { "ζ " + $0.formatted(.number.precision(.fractionLength(0...2))) } ?? "ζ offen")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            var items = pipeSectionsBinding.wrappedValue
                            items.remove(atOffsets: offsets)
                            pipeSectionsBinding.wrappedValue = items
                        }

                        Button {
                            var items = pipeSectionsBinding.wrappedValue
                            items.append(
                                HeizBalancePipeSection(
                                    name: "Rohrabschnitt \(items.count + 1)",
                                    role: .sharedDistribution
                                )
                            )
                            pipeSectionsBinding.wrappedValue = items
                        } label: {
                            Label("Gemeinsamen Rohrabschnitt hinzufügen", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Gemeinsame Rohrabschnitte")
                } footer: {
                    Text("Diese Geometrie gehört physisch zu diesem Netzsegment und wird genau einmal mit dessen automatisch summiertem Q berechnet. Es gibt hier bewusst kein manuelles Q-Feld. ζ leer bedeutet: Einzelwiderstände noch nicht vollständig erfasst.")
                }

                Section {
                    if let componentsBinding = segmentComponentsBinding {
                        if componentsBinding.wrappedValue.isEmpty {
                            Text("Keine zentralen Bauteilverluste erfasst.")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(componentsBinding) { $component in
                            NavigationLink {
                                HeizBalanceHydraulicNetworkSegmentComponentEditor(
                                    component: $component,
                                    segmentName: segmentBinding.wrappedValue.name,
                                    segmentVolumeFlowLPH: segmentFlowLPH
                                )
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(component.name)
                                    HStack(spacing: 8) {
                                        Text(component.kind.title)
                                        Text(component.pressureLossKPa.map { $0.formatted(.number.precision(.fractionLength(0...3))) + " kPa" } ?? "Δp offen")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(component.pressureLossKPa == nil ? Color.orange : Color.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            var items = componentsBinding.wrappedValue
                            items.remove(atOffsets: offsets)
                            componentsBinding.wrappedValue = items
                        }

                        Menu {
                            ForEach(HeizBalanceHydraulicLossComponent.Kind.networkCases) { kind in
                                Button(kind.title) {
                                    var items = componentsBinding.wrappedValue
                                    items.append(HeizBalanceHydraulicLossComponent(kind: kind))
                                    componentsBinding.wrappedValue = items
                                }
                            }
                        } label: {
                            Label("Zentrales Bauteil hinzufügen", systemImage: "plus.circle")
                        }

                        if !componentsBinding.wrappedValue.isEmpty,
                           let componentAssessmentBinding {
                            Toggle("Zentrale Bauteilaufnahme vollständig", isOn: componentAssessmentBinding)
                                .disabled(!componentValuesComplete)
                        }
                    }
                } header: {
                    Text("Zentrale Armaturen & Bauteile")
                } footer: {
                    Text("Erfasst werden nur explizite Druckverluste des realen gemeinsamen Pfads, z. B. Strangregulierventil, Differenzdruckregler, Wärmemengenzähler, Filter oder Verteiler. Δp muss zum vorgesehenen Segment-Q passen. Keine pauschalen Herstellerwerte oder automatisch erfundenen Kennlinien.")
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

private struct HeizBalanceHydraulicNetworkSegmentPipeEditor: View {
    @Binding var section: HeizBalancePipeSection
    let segmentName: String
    let segmentVolumeFlowLPH: Double?

    var body: some View {
        Form {
            Section("Netzsegment") {
                LabeledContent("Segment", value: segmentName)
                LabeledContent("Automatischer Q") {
                    Text(segmentVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen")
                        .foregroundStyle(segmentVolumeFlowLPH == nil ? Color.orange : Color.primary)
                }
            }

            Section {
                TextField("Bezeichnung", text: $section.name)
                OptionalDecimalField(title: "Innendurchmesser", value: $section.innerDiameterMM, unit: "mm")
                OptionalDecimalField(title: "Hydraulische Länge", value: $section.lengthM, unit: "m")
                OptionalDecimalField(title: "Absolute Rauheit", value: $section.roughnessMM, unit: "mm")
                OptionalDecimalField(title: "ζ-Summe Einzelwiderstände", value: $section.zetaTotal, unit: "")
            } header: {
                Text("Physische Rohrgeometrie")
            } footer: {
                Text("Q wird nicht gespeichert oder manuell eingegeben. HeizBalance verwendet bei jeder Berechnung den aktuellen Summen-Q dieses Netzsegments. Innendurchmesser statt DN, keine versteckte DN→ID-Annahme.")
            }

            Section("Notiz") {
                TextField("Rohrwerkstoff / Formstücke / Quelle", text: $section.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(section.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            section.role = .sharedDistribution
            section.explicitDesignVolumeFlowLPH = nil
            section.volumeFlowSource = nil
            section.networkSegmentID = nil
        }
    }
}

private struct HeizBalanceHydraulicNetworkSegmentComponentEditor: View {
    @Binding var component: HeizBalanceHydraulicLossComponent
    let segmentName: String
    let segmentVolumeFlowLPH: Double?

    var body: some View {
        Form {
            Section("Netzsegment") {
                LabeledContent("Segment", value: segmentName)
                LabeledContent("Automatischer Q") {
                    Text(segmentVolumeFlowLPH.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " l/h" } ?? "offen")
                        .foregroundStyle(segmentVolumeFlowLPH == nil ? Color.orange : Color.primary)
                }
            }

            Section("Bauteil") {
                Picker("Art", selection: $component.kind) {
                    ForEach(HeizBalanceHydraulicLossComponent.Kind.networkCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                TextField("Bezeichnung", text: $component.name)
            }

            Section {
                OptionalDecimalField(title: "Druckverlust", value: $component.pressureLossKPa, unit: "kPa")
                InputSourcePicker(title: "Quelle Δp", selection: $component.source)
            } header: {
                Text("Hydraulischer Kennwert")
            } footer: {
                Text("Der dokumentierte Δp muss zum aktuellen Segment-Q bzw. zum realen Hersteller-/Messpunkt passen. HeizBalance erzeugt hier keine pauschale Kennlinie und keine automatische Ventilfreigabe.")
            }

            Section("Notiz") {
                TextField("Hersteller / Typ / Datenblatt / Messpunkt", text: $component.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(component.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: component.kind) { _, newKind in
            if component.name.isEmpty || HeizBalanceHydraulicLossComponent.Kind.networkCases.map(\.title).contains(component.name) {
                component.name = newKind.title
            }
            component.valveProductData = nil
        }
        .onAppear {
            if !HeizBalanceHydraulicLossComponent.Kind.networkCases.contains(component.kind) {
                component.kind = .other
                component.name = component.name.isEmpty ? HeizBalanceHydraulicLossComponent.Kind.other.title : component.name
                component.valveProductData = nil
            }
        }
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
