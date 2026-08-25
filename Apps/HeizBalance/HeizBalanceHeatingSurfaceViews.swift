import SwiftUI

extension HeizBalanceHeatingSurface {
    func technicalPreview(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double
    ) -> HeizBalanceHeatingSurfacePreviewCalculator.Result? {
        guard let nominalPowerDeltaT50W,
              let exponent,
              let flowTemperatureC,
              let returnTemperatureC else {
            return nil
        }

        return HeizBalanceHeatingSurfacePreviewCalculator.calculate(
            .init(
                nominalPowerDeltaT50W: nominalPowerDeltaT50W,
                exponent: exponent,
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                roomTemperatureC: roomTemperatureC
            )
        )
    }

    func hydronicPreparation(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double
    ) -> HeizBalanceHydronicPreparationCalculator.Result? {
        guard let assignedRequiredPowerW,
              let flowTemperatureC,
              let returnTemperatureC,
              let preview = technicalPreview(
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                roomTemperatureC: roomTemperatureC
              ) else {
            return nil
        }

        return HeizBalanceHydronicPreparationCalculator.calculate(
            .init(
                requiredPowerW: assignedRequiredPowerW,
                availablePowerW: preview.availablePowerW,
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC
            )
        )
    }

    func pipeCircuitPreparation(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double,
        densityKGPerM3: Double?,
        kinematicViscosityMM2S: Double?
    ) -> HeizBalanceHydronicCircuitCalculator.Result? {
        guard let hydronic = hydronicPreparation(
                flowTemperatureC: flowTemperatureC,
                returnTemperatureC: returnTemperatureC,
                roomTemperatureC: roomTemperatureC
              ),
              let densityKGPerM3,
              let kinematicViscosityMM2S,
              densityKGPerM3 > 0,
              kinematicViscosityMM2S > 0 else {
            return nil
        }

        let sections = pipeSections ?? []
        guard !sections.isEmpty else { return nil }

        var inputs: [HeizBalanceHydronicCircuitCalculator.PipeSectionInput] = []
        for section in sections {
            guard let innerDiameterMM = section.innerDiameterMM,
                  let lengthM = section.lengthM,
                  let roughnessMM = section.roughnessMM else {
                return nil
            }

            let sectionVolumeFlowLPH: Double
            switch section.effectiveRole {
            case .heatingSurfaceBranch:
                sectionVolumeFlowLPH = hydronic.targetVolumeFlowLPH
            case .sharedDistribution:
                guard let explicitFlow = section.explicitDesignVolumeFlowLPH,
                      explicitFlow > 0 else {
                    return nil
                }
                sectionVolumeFlowLPH = explicitFlow
            }

            inputs.append(
                .init(
                    id: section.id.uuidString,
                    name: section.name,
                    volumeFlowLPH: sectionVolumeFlowLPH,
                    innerDiameterMM: innerDiameterMM,
                    lengthM: lengthM,
                    roughnessMM: roughnessMM,
                    zetaTotal: section.zetaTotal
                )
            )
        }

        return HeizBalanceHydronicCircuitCalculator.calculate(
            .init(
                targetVolumeFlowLPH: hydronic.targetVolumeFlowLPH,
                densityKGPerM3: densityKGPerM3,
                kinematicViscosityM2S: kinematicViscosityMM2S * 1e-6,
                sections: inputs
            )
        )
    }

    func circuitPressureLossSummary(
        flowTemperatureC: Double?,
        returnTemperatureC: Double?,
        roomTemperatureC: Double,
        densityKGPerM3: Double?,
        kinematicViscosityMM2S: Double?
    ) -> HeizBalanceCircuitPressureLossSummaryCalculator.Result? {
        guard let pipeCircuit = pipeCircuitPreparation(
            flowTemperatureC: flowTemperatureC,
            returnTemperatureC: returnTemperatureC,
            roomTemperatureC: roomTemperatureC,
            densityKGPerM3: densityKGPerM3,
            kinematicViscosityMM2S: kinematicViscosityMM2S
        ) else {
            return nil
        }

        let components = (hydraulicLossComponents ?? []).map {
            HeizBalanceCircuitPressureLossSummaryCalculator.ComponentInput(
                id: $0.id.uuidString,
                pressureLossKPa: $0.pressureLossKPa
            )
        }

        return HeizBalanceCircuitPressureLossSummaryCalculator.calculate(
            .init(
                partialPipePressureLossKPa: pipeCircuit.partialPressureLossKPa,
                completePipePressureLossKPa: pipeCircuit.completePressureLossKPa,
                components: components,
                componentAssessmentComplete: isHydraulicComponentAssessmentComplete
            )
        )
    }
}

struct HeizBalanceHeatingSurfaceEditor: View {
    @Binding var surface: HeizBalanceHeatingSurface
    let designFlowTemperatureC: Double?
    let designReturnTemperatureC: Double?
    let roomTemperatureC: Double
    let hydraulicFluidDensityKGPerM3: Double?
    let hydraulicKinematicViscosityMM2S: Double?

    private var preview: HeizBalanceHeatingSurfacePreviewCalculator.Result? {
        surface.technicalPreview(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC
        )
    }

    private var hydronicPreparation: HeizBalanceHydronicPreparationCalculator.Result? {
        surface.hydronicPreparation(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC
        )
    }

    private var pipeCircuit: HeizBalanceHydronicCircuitCalculator.Result? {
        surface.pipeCircuitPreparation(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC,
            densityKGPerM3: hydraulicFluidDensityKGPerM3,
            kinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
        )
    }

    private var circuitPressureLoss: HeizBalanceCircuitPressureLossSummaryCalculator.Result? {
        surface.circuitPressureLossSummary(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: roomTemperatureC,
            densityKGPerM3: hydraulicFluidDensityKGPerM3,
            kinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
        )
    }

    private var pipeSectionsBinding: Binding<[HeizBalancePipeSection]> {
        Binding(
            get: { surface.pipeSections ?? [] },
            set: { surface.pipeSections = $0 }
        )
    }

    private var lossComponentsBinding: Binding<[HeizBalanceHydraulicLossComponent]> {
        Binding(
            get: { surface.hydraulicLossComponents ?? [] },
            set: { surface.hydraulicLossComponents = $0 }
        )
    }

    private var componentAssessmentBinding: Binding<Bool> {
        Binding(
            get: { surface.isHydraulicComponentAssessmentComplete },
            set: { surface.hydraulicComponentAssessmentComplete = $0 }
        )
    }

    private var componentValuesComplete: Bool {
        lossComponentsBinding.wrappedValue.allSatisfy { component in
            guard let loss = component.pressureLossKPa else { return false }
            return loss.isFinite && loss >= 0
        }
    }

    private var missingPreviewInputs: [String] {
        var items: [String] = []
        if surface.nominalPowerDeltaT50W == nil { items.append("Nennleistung ΔT50 fehlt") }
        if surface.exponent == nil { items.append("Heizkörperexponent n fehlt") }
        if designFlowTemperatureC == nil { items.append("Projekt-Vorlauftemperatur fehlt") }
        if designReturnTemperatureC == nil { items.append("Projekt-Rücklauftemperatur fehlt") }
        return items
    }

    private var missingCircuitInputs: [String] {
        var items: [String] = []
        if hydronicPreparation == nil { items.append("Gültiger Ziel-Volumenstrom fehlt") }
        if hydraulicFluidDensityKGPerM3 == nil { items.append("Fluiddichte im Projekt fehlt") }
        if hydraulicKinematicViscosityMM2S == nil { items.append("Kinematische Viskosität im Projekt fehlt") }
        if pipeSectionsBinding.wrappedValue.isEmpty { items.append("Noch kein Rohrabschnitt erfasst") }

        for section in pipeSectionsBinding.wrappedValue {
            if section.innerDiameterMM == nil { items.append("\(section.name): Innendurchmesser fehlt") }
            if section.lengthM == nil { items.append("\(section.name): Länge fehlt") }
            if section.roughnessMM == nil { items.append("\(section.name): Rauheit fehlt") }
            if section.effectiveRole == .sharedDistribution,
               section.explicitDesignVolumeFlowLPH == nil {
                items.append("\(section.name): Volumenstrom der gemeinsamen Verteilung fehlt")
            }
        }
        return items
    }

    private func valveSizing(for component: HeizBalanceHydraulicLossComponent) -> HeizBalanceValveSizingPreparationCalculator.Result? {
        guard component.kind == .thermostaticValve || component.kind == .returnValve,
              let targetFlow = hydronicPreparation?.targetVolumeFlowLPH,
              let pressureLoss = component.pressureLossKPa,
              let density = hydraulicFluidDensityKGPerM3 else {
            return nil
        }

        return HeizBalanceValveSizingPreparationCalculator.calculate(
            .init(
                targetVolumeFlowLPH: targetFlow,
                valvePressureDropKPa: pressureLoss,
                densityKGPerM3: density
            )
        )
    }

    var body: some View {
        Form {
            Section("Heizfläche") {
                Picker("Art", selection: $surface.kind) {
                    ForEach(HeizBalanceHeatingSurface.Kind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                TextField("Bezeichnung", text: $surface.name)
                TextField("Hersteller", text: $surface.manufacturer)
                TextField("Modell / Typ", text: $surface.model)
            }

            Section {
                OptionalDecimalField(
                    title: "Nennleistung ΔT50",
                    value: $surface.nominalPowerDeltaT50W,
                    unit: "W"
                )
                OptionalDecimalField(
                    title: "Exponent n",
                    value: $surface.exponent,
                    unit: ""
                )
                InputSourcePicker(title: "Quelle Leistung", selection: $surface.powerSource)
            } header: {
                Text("Leistungsdaten")
            } footer: {
                Text("Nennleistung und Exponent werden als dokumentierte Hersteller- oder Projektwerte erfasst. HeizBalance hinterlegt hier keine erfundenen Typen- oder Leistungstabellen.")
            }

            Section {
                OptionalDecimalField(
                    title: "Zugeordnete erforderliche Leistung",
                    value: $surface.assignedRequiredPowerW,
                    unit: "W"
                )
            } header: {
                Text("Leistungszuordnung")
            } footer: {
                Text("Dieser Wert ist die Leistung, die diese konkrete Heizfläche im späteren Abgleich bereitstellen soll. Er wird bewusst getrennt von der maximal verfügbaren Heizflächenleistung gespeichert.")
            }

            Section {
                if let flow = designFlowTemperatureC, let returnTemperature = designReturnTemperatureC {
                    LabeledContent("Systemtemperaturen") {
                        Text("\(flow.formatted(.number.precision(.fractionLength(0...1)))) / \(returnTemperature.formatted(.number.precision(.fractionLength(0...1)))) °C")
                    }
                }
                LabeledContent("Raumtemperatur") {
                    Text(roomTemperatureC.formatted(.number.precision(.fractionLength(0...1))) + " °C")
                }

                if let preview {
                    LabeledContent("Verfügbare Leistung") {
                        Text(preview.availablePowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                            .fontWeight(.semibold)
                    }
                    LabeledContent("Wasserspreizung") {
                        Text(preview.waterTemperatureDifferenceK.formatted(.number.precision(.fractionLength(0...1))) + " K")
                    }
                    LabeledContent("Volumenstrom bei verfügbarer Leistung") {
                        Text(preview.volumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                    }
                } else if missingPreviewInputs.isEmpty {
                    Label("Temperatur- oder Leistungsdaten ergeben keine gültige technische Vorberechnung.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    ForEach(missingPreviewInputs, id: \.self) { item in
                        Label(item, systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Technische Heizflächen-Vorbereitung")
            } footer: {
                Text("Die verfügbare Leistung beschreibt die Heizfläche bei den eingegebenen Systemtemperaturen. Sie ist nicht automatisch die für den hydraulischen Abgleich benötigte Leistung.")
            }

            Section {
                if let hydronicPreparation {
                    LabeledContent("Erforderliche Leistung") {
                        Text(hydronicPreparation.requiredPowerW.formatted(.number.precision(.fractionLength(0))) + " W")
                    }
                    LabeledContent("Leistungsreserve") {
                        if hydronicPreparation.capacitySufficient {
                            Text(hydronicPreparation.capacityMarginW.formatted(.number.precision(.fractionLength(0))) + " W")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(hydronicPreparation.capacityMarginW.formatted(.number.precision(.fractionLength(0))) + " W")
                                .foregroundStyle(.orange)
                        }
                    }
                    LabeledContent("Deckung") {
                        Text((hydronicPreparation.capacityRatio * 100).formatted(.number.precision(.fractionLength(0))) + " %")
                    }
                    LabeledContent("Ziel-Volumenstrom technisch") {
                        Text(hydronicPreparation.targetVolumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                            .fontWeight(.semibold)
                    }

                    if hydronicPreparation.capacitySufficient {
                        Label("Heizflächenleistung deckt die zugeordnete Leistung in dieser Vorberechnung.", systemImage: "checkmark.circle")
                            .font(.caption)
                    } else {
                        Label("Heizflächenleistung reicht für die zugeordnete Leistung bei diesen Temperaturen nicht aus.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } else if surface.assignedRequiredPowerW == nil {
                    Label("Noch keine erforderliche Leistung dieser Heizfläche zugeordnet.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Für den Ziel-Volumenstrom fehlen gültige Heizflächen- oder Systemdaten.", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Hydraulische Vorbereitung")
            } footer: {
                Text("Der Ziel-Volumenstrom wird aus der zugeordneten erforderlichen Leistung und der Wasserspreizung berechnet. Er ist noch keine freigegebene Ventilvoreinstellung oder Verfahren-B-Dokumentation.")
            }

            Section {
                if pipeSectionsBinding.wrappedValue.isEmpty {
                    Text("Noch keine Rohrabschnitte erfasst")
                        .foregroundStyle(.secondary)
                }

                ForEach(pipeSectionsBinding) { $section in
                    NavigationLink {
                        HeizBalancePipeSectionEditor(section: $section)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(section.name)
                            Text(section.effectiveRole.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 10) {
                                if let diameter = section.innerDiameterMM {
                                    Text("ID \(diameter.formatted(.number.precision(.fractionLength(0...2)))) mm")
                                }
                                if let length = section.lengthM {
                                    Text("\(length.formatted(.number.precision(.fractionLength(0...2)))) m")
                                }
                                if section.effectiveRole == .sharedDistribution,
                                   let flow = section.explicitDesignVolumeFlowLPH {
                                    Text("Q \(flow.formatted(.number.precision(.fractionLength(0)))) l/h")
                                }
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
                    items.append(HeizBalancePipeSection(name: "Rohrabschnitt \(items.count + 1)"))
                    pipeSectionsBinding.wrappedValue = items
                } label: {
                    Label("Rohrabschnitt hinzufügen", systemImage: "plus.circle")
                }
            } header: {
                Text("Rohrweg")
            } footer: {
                Text("Heizflächen-Anbindungen werden mit dem Ziel-Volumenstrom dieser Heizfläche gerechnet. Gemeinsame Verteilrohre benötigen ihren eigenen summierten Abschnitts-Volumenstrom.")
            }

            Section {
                if let pipeCircuit {
                    LabeledContent("Ziel-Volumenstrom Heizfläche") {
                        Text(pipeCircuit.targetVolumeFlowLPH.formatted(.number.precision(.fractionLength(0))) + " l/h")
                    }
                    LabeledContent("Rohrreibung") {
                        Text(pipeCircuit.straightPipePressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                    }
                    LabeledContent("Bekannte Einzelwiderstände") {
                        Text(pipeCircuit.knownLocalPressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                    }

                    if let complete = pipeCircuit.completePressureLossKPa,
                       let head = pipeCircuit.completeHeadMeters {
                        LabeledContent("Rohrkreis Δp") {
                            Text(complete.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                                .fontWeight(.semibold)
                        }
                        LabeledContent("Äquivalente Förderhöhe") {
                            Text(head.formatted(.number.precision(.fractionLength(0...2))) + " m")
                        }
                    } else {
                        LabeledContent("Teilsumme bekannte Verluste") {
                            Text(pipeCircuit.partialPressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                                .fontWeight(.semibold)
                        }
                        Label("Mindestens einem Rohrabschnitt fehlt die ζ-Summe. Deshalb wird kein vollständiger Rohrkreis-Druckverlust ausgegeben.", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    ForEach(pipeCircuit.sections, id: \.id) { section in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.name)
                                .font(.caption.weight(.semibold))
                            Text(
                                "Q \(section.volumeFlowLPH.formatted(.number.precision(.fractionLength(0)))) l/h · v \(section.velocityMS.formatted(.number.precision(.fractionLength(2)))) m/s · \(section.pressureDropPaPerM.formatted(.number.precision(.fractionLength(0)))) Pa/m · Re \(section.reynoldsNumber.formatted(.number.precision(.fractionLength(0))))"
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ForEach(missingCircuitInputs, id: \.self) { item in
                        Label(item, systemImage: "circle.dashed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Rohrnetz-Vorbereitung")
            } footer: {
                Text("Jeder Rohrabschnitt wird mit seinem tatsächlich vorgesehenen Abschnitts-Volumenstrom berechnet. Gemeinsame Leitungen werden dadurch nicht fälschlich nur mit dem Einzel-Heizflächenstrom angesetzt.")
            }

            Section {
                if lossComponentsBinding.wrappedValue.isEmpty {
                    Text("Noch keine separaten Bauteilverluste erfasst")
                        .foregroundStyle(.secondary)
                }

                ForEach(lossComponentsBinding) { $component in
                    NavigationLink {
                        HeizBalanceHydraulicLossComponentEditor(component: $component)
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(component.name)
                                Text(component.kind.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let sizing = valveSizing(for: component) {
                                    Text("erforderlicher kv ≈ \(sizing.requiredKvM3H.formatted(.number.precision(.fractionLength(3)))) m³/h")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let loss = component.pressureLossKPa {
                                Text(loss.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    var items = lossComponentsBinding.wrappedValue
                    items.remove(atOffsets: offsets)
                    lossComponentsBinding.wrappedValue = items
                    surface.hydraulicComponentAssessmentComplete = false
                }

                Menu {
                    ForEach(HeizBalanceHydraulicLossComponent.Kind.allCases) { kind in
                        Button(kind.title) {
                            var items = lossComponentsBinding.wrappedValue
                            items.append(HeizBalanceHydraulicLossComponent(kind: kind))
                            lossComponentsBinding.wrappedValue = items
                            surface.hydraulicComponentAssessmentComplete = false
                        }
                    }
                } label: {
                    Label("Bauteilverlust hinzufügen", systemImage: "plus.circle")
                }

                Toggle("Bauteilaufnahme vollständig", isOn: componentAssessmentBinding)
                    .disabled(!componentValuesComplete)
            } header: {
                Text("Weitere Druckverluste")
            } footer: {
                Text("Ventile, Rücklaufverschraubungen, Heizflächen, Verteiler und andere Bauteile werden nur mit explizitem Δp und dokumentierter Quelle erfasst. Bei Ventilen wird daraus ein technischer kv-Rechenwert angezeigt; eine konkrete Voreinstellung erfordert weiterhin die Kennlinie des tatsächlichen Ventils.")
            }

            Section {
                if let circuitPressureLoss {
                    LabeledContent("Bekannter Rohrverlust") {
                        Text(circuitPressureLoss.knownPipePressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                    }
                    LabeledContent("Bekannte Bauteilverluste") {
                        Text(circuitPressureLoss.knownComponentPressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                    }
                    LabeledContent("Bekannte Kreissumme") {
                        Text(circuitPressureLoss.knownCircuitPressureLossKPa.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                            .fontWeight(.semibold)
                    }

                    if let complete = circuitPressureLoss.completeCircuitPressureLossKPa {
                        LabeledContent("Vollständiger Kreis Δp") {
                            Text(complete.formatted(.number.precision(.fractionLength(0...3))) + " kPa")
                                .fontWeight(.bold)
                        }
                        Label("Rohr- und Bauteilaufnahme dieses Kreises sind als vollständig erfasst.", systemImage: "checkmark.circle")
                            .font(.caption)
                    } else {
                        if !circuitPressureLoss.pipeCoverageComplete {
                            Label("Rohrweg noch unvollständig: mindestens eine ζ-Summe fehlt.", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if circuitPressureLoss.missingComponentCount > 0 {
                            Label("\(circuitPressureLoss.missingComponentCount) Bauteilverlust(e) ohne Δp-Wert.", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if !circuitPressureLoss.componentCoverageComplete && circuitPressureLoss.missingComponentCount == 0 {
                            Label("Bauteilaufnahme noch nicht als vollständig bestätigt.", systemImage: "circle.dashed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Label("Für die Kreiszusammenfassung fehlen noch gültige Rohrnetz-Daten.", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Hydraulischer Kreis")
            } footer: {
                Text("Nur ein vollständig erfasster Kreis darf später für ungünstigsten Kreis, Ventilauslegung und Pumpenanforderung verwendet werden. Die aktuelle Ausgabe ist weiterhin technische Vorbereitung, kein Verfahren-B-Nachweis.")
            }

            Section("Notiz") {
                TextField("Quelle / Typenschild / Besonderheit", text: $surface.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(surface.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: surface.kind) { _, newKind in
            if surface.name.isEmpty || HeizBalanceHeatingSurface.Kind.allCases.map(\.title).contains(surface.name) {
                surface.name = newKind.title
            }
        }
    }
}

struct HeizBalancePipeSectionEditor: View {
    @Binding var section: HeizBalancePipeSection

    private var roleBinding: Binding<HeizBalancePipeSection.Role> {
        Binding(
            get: { section.effectiveRole },
            set: { newRole in
                section.role = newRole
                if newRole == .heatingSurfaceBranch {
                    section.explicitDesignVolumeFlowLPH = nil
                    section.volumeFlowSource = nil
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("Rohrabschnitt") {
                TextField("Bezeichnung", text: $section.name)
                Picker("Rolle", selection: roleBinding) {
                    ForEach(HeizBalancePipeSection.Role.allCases) { role in
                        Text(role.title).tag(role)
                    }
                }

                if section.effectiveRole == .sharedDistribution {
                    OptionalDecimalField(
                        title: "Abschnitts-Volumenstrom",
                        value: $section.explicitDesignVolumeFlowLPH,
                        unit: "l/h"
                    )
                    InputSourcePicker(title: "Quelle Volumenstrom", selection: $section.volumeFlowSource)
                }

                OptionalDecimalField(title: "Innendurchmesser", value: $section.innerDiameterMM, unit: "mm")
                OptionalDecimalField(title: "Hydraulische Länge", value: $section.lengthM, unit: "m")
                OptionalDecimalField(title: "Absolute Rauheit", value: $section.roughnessMM, unit: "mm")
                OptionalDecimalField(title: "ζ-Summe Einzelwiderstände", value: $section.zetaTotal, unit: "")
            }

            Section("Notiz") {
                TextField("Rohrwerkstoff / Formstücke / Quelle", text: $section.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(section.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Text(section.effectiveRole == .heatingSurfaceBranch
                 ? "Anbindung: gerechnet wird mit dem Ziel-Volumenstrom dieser Heizfläche. ζ leer bedeutet: Einzelwiderstände noch nicht vollständig erfasst."
                 : "Gemeinsame Verteilung: hier muss der tatsächliche summierte Abschnitts-Volumenstrom erfasst werden. ζ leer bedeutet: Einzelwiderstände noch nicht vollständig erfasst.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
        }
    }
}

struct HeizBalanceHydraulicLossComponentEditor: View {
    @Binding var component: HeizBalanceHydraulicLossComponent

    var body: some View {
        Form {
            Section("Bauteil") {
                Picker("Art", selection: $component.kind) {
                    ForEach(HeizBalanceHydraulicLossComponent.Kind.allCases) { kind in
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
                Text("Der Druckverlust muss zum vorgesehenen Ziel-Volumenstrom dieses Kreises passen. HeizBalance erzeugt hier keine Herstellerkennlinie und keine pauschale Ventilvoreinstellung.")
            }

            Section("Notiz") {
                TextField("Hersteller / Typ / Datenblatt / Besonderheit", text: $component.note, axis: .vertical)
                    .lineLimit(2...6)
            }
        }
        .navigationTitle(component.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: component.kind) { _, newKind in
            if component.name.isEmpty || HeizBalanceHydraulicLossComponent.Kind.allCases.map(\.title).contains(component.name) {
                component.name = newKind.title
            }
        }
    }
}
