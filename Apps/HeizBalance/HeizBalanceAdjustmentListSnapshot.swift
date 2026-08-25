import Foundation

struct HeizBalanceAdjustmentListSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-adjustment-list-v1"

    var schema: String
    var generatedAt: Date
    var projectID: UUID
    var projectName: String
    var customerName: String
    var address: String
    var technicalPreparationOnly: Bool
    var notice: String
    var summary: Summary
    var rows: [Row]
    var pump: PumpEntry?

    struct Summary: Codable, Hashable {
        var circuitCount: Int
        var flowReadyCount: Int
        var pressureReadyCount: Int
        var currentThermostatSettingCount: Int
        var currentReturnSettingCount: Int
        var staleValveSettingCount: Int
        var valveWithoutHeldSettingCount: Int
    }

    struct Row: Identifiable, Codable, Hashable {
        var id: UUID { surfaceID }
        var floorName: String
        var roomName: String
        var surfaceID: UUID
        var surfaceName: String
        var targetVolumeFlowLPH: Double?
        var completeCircuitPressureLossKPa: Double?
        var thermostatSettings: [ValveEntry]
        var returnSettings: [ValveEntry]
        var missingNotes: [String]
    }

    struct ValveEntry: Identifiable, Codable, Hashable {
        var id: UUID { componentID }
        var componentID: UUID
        var componentName: String
        var manufacturer: String?
        var productName: String?
        var requiredKvM3H: Double?
        var heldSetting: String?
        var heldKvM3H: Double?
        var selectionCurrent: Bool?
        var note: String
    }

    struct PumpEntry: Codable, Hashable {
        var displayName: String
        var curveLabel: String
        var operatingPointVolumeFlowM3H: Double
        var requiredHeadM: Double
        var availableHeadM: Double
        var headReserveM: Double
        var selectionCurrent: Bool
    }

    static func make(
        project: HeizBalanceProject,
        valveSelections: [HeizBalanceValveSettingSelection],
        pumpSelection: HeizBalancePumpSelection?,
        generatedAt: Date = Date()
    ) -> Self {
        let selectionByComponent = Dictionary(
            uniqueKeysWithValues: valveSelections
                .filter { $0.projectID == project.id }
                .map { ($0.componentID, $0) }
        )
        let networkState = project.hydraulicNetworkState()
        let staleNetworkSurfaceIDs = Set(networkState.linkedPipes.filter { !$0.isCurrent }.map(\.surfaceID))

        var rows: [Row] = []
        var flowReady = 0
        var pressureReady = 0
        var currentThermostats = 0
        var currentReturns = 0
        var staleSelections = 0
        var valvesWithoutSelection = 0

        for floor in project.floors {
            for room in floor.rooms {
                for surface in room.heatingSurfaces ?? [] {
                    let hydronic = surface.hydronicPreparation(
                        flowTemperatureC: project.designFlowTemperatureC,
                        returnTemperatureC: project.designReturnTemperatureC,
                        roomTemperatureC: room.targetTemperature
                    )
                    let rawCircuit = surface.circuitPressureLossSummary(
                        flowTemperatureC: project.designFlowTemperatureC,
                        returnTemperatureC: project.designReturnTemperatureC,
                        roomTemperatureC: room.targetTemperature,
                        densityKGPerM3: project.hydraulicFluidDensityKGPerM3,
                        kinematicViscosityMM2S: project.hydraulicKinematicViscosityMM2S
                    )
                    let networkCurrent = !staleNetworkSurfaceIDs.contains(surface.id)
                    let completeCircuitPressureLossKPa = networkCurrent ? rawCircuit?.completeCircuitPressureLossKPa : nil

                    if hydronic != nil { flowReady += 1 }
                    if completeCircuitPressureLossKPa != nil { pressureReady += 1 }

                    var thermostats: [ValveEntry] = []
                    var returns: [ValveEntry] = []

                    for component in surface.hydraulicLossComponents ?? [] where component.supportsValveProductData {
                        let requiredKv = requiredKv(
                            component: component,
                            targetFlowLPH: hydronic?.targetVolumeFlowLPH,
                            densityKGPerM3: project.hydraulicFluidDensityKGPerM3
                        )
                        let held = selectionByComponent[component.id]
                        let current = held.map {
                            $0.matchesCurrent(
                                component: component,
                                requiredKvM3H: requiredKv,
                                targetVolumeFlowLPH: hydronic?.targetVolumeFlowLPH,
                                densityKGPerM3: project.hydraulicFluidDensityKGPerM3
                            )
                        }

                        if held == nil {
                            valvesWithoutSelection += 1
                        } else if current == false {
                            staleSelections += 1
                        } else if current == true {
                            if component.kind == .thermostaticValve { currentThermostats += 1 }
                            if component.kind == .returnValve { currentReturns += 1 }
                        }

                        let entry = ValveEntry(
                            componentID: component.id,
                            componentName: component.name,
                            manufacturer: component.valveProductData?.manufacturer.nilIfEmpty,
                            productName: component.valveProductData?.productName.nilIfEmpty,
                            requiredKvM3H: requiredKv,
                            heldSetting: held?.selectedSetting,
                            heldKvM3H: held?.selectedKvM3H,
                            selectionCurrent: current,
                            note: component.note
                        )
                        if component.kind == .thermostaticValve {
                            thermostats.append(entry)
                        } else if component.kind == .returnValve {
                            returns.append(entry)
                        }
                    }

                    var missing: [String] = []
                    if hydronic == nil { missing.append("Ziel-Volumenstrom fehlt") }
                    if !networkCurrent { missing.append("Netzbaum-Q neu synchronisieren") }
                    if completeCircuitPressureLossKPa == nil { missing.append("vollständiger Kreis-Δp fehlt") }
                    if thermostats.isEmpty { missing.append("Thermostatventil nicht erfasst") }
                    if !thermostats.isEmpty && thermostats.contains(where: { $0.heldSetting == nil }) {
                        missing.append("Thermostateinstellung nicht festgehalten")
                    }
                    if !returns.isEmpty && returns.contains(where: { $0.heldSetting == nil }) {
                        missing.append("Rücklaufeinstellung nicht festgehalten")
                    }
                    if (thermostats + returns).contains(where: { $0.selectionCurrent == false }) {
                        missing.append("Ventileinstellung neu bewerten")
                    }

                    rows.append(
                        Row(
                            floorName: floor.name,
                            roomName: room.name,
                            surfaceID: surface.id,
                            surfaceName: surface.name,
                            targetVolumeFlowLPH: hydronic?.targetVolumeFlowLPH,
                            completeCircuitPressureLossKPa: completeCircuitPressureLossKPa,
                            thermostatSettings: thermostats,
                            returnSettings: returns,
                            missingNotes: missing
                        )
                    )
                }
            }
        }

        let pumpEntry: PumpEntry? = pumpSelection.map { selection in
            let system = project.hydraulicSystemPreparationState().result
            let current: Bool
            if let flow = system?.designTotalVolumeFlowLPH,
               let head = system?.designNetworkHeadMeters,
               system?.pumpOperatingPointReady == true {
                current = selection.matchesOperatingPoint(
                    volumeFlowM3H: flow / 1_000,
                    requiredHeadM: head
                )
            } else {
                current = false
            }
            return PumpEntry(
                displayName: selection.displayName,
                curveLabel: selection.curveLabel,
                operatingPointVolumeFlowM3H: selection.operatingPointVolumeFlowM3H,
                requiredHeadM: selection.requiredHeadM,
                availableHeadM: selection.availableHeadM,
                headReserveM: selection.headReserveM,
                selectionCurrent: current
            )
        }

        return Self(
            schema: Self.schemaVersion,
            generatedAt: generatedAt,
            projectID: project.id,
            projectName: project.name,
            customerName: project.customerName,
            address: project.displayAddress,
            technicalPreparationOnly: true,
            notice: "Technische Baustellen-Einstellliste – keine Verfahren-B-, GEG-/BEG- oder Herstellerfreigabe. Enthalten sind ausschließlich explizit erfasste Berechnungswerte und ausdrücklich festgehaltene Einstellungen. Netzbaum-verknüpfte Rohrabschnitte werden bei veraltetem Summenstrom als unvollständig markiert.",
            summary: .init(
                circuitCount: rows.count,
                flowReadyCount: flowReady,
                pressureReadyCount: pressureReady,
                currentThermostatSettingCount: currentThermostats,
                currentReturnSettingCount: currentReturns,
                staleValveSettingCount: staleSelections,
                valveWithoutHeldSettingCount: valvesWithoutSelection
            ),
            rows: rows,
            pump: pumpEntry
        )
    }

    private static func requiredKv(
        component: HeizBalanceHydraulicLossComponent,
        targetFlowLPH: Double?,
        densityKGPerM3: Double?
    ) -> Double? {
        guard component.supportsValveProductData,
              let targetFlowLPH,
              let pressureLoss = component.pressureLossKPa,
              let densityKGPerM3 else { return nil }
        return HeizBalanceValveSizingPreparationCalculator.calculate(
            .init(
                targetVolumeFlowLPH: targetFlowLPH,
                valvePressureDropKPa: pressureLoss,
                densityKGPerM3: densityKGPerM3
            )
        )?.requiredKvM3H
    }
}

private extension String {
    var nilIfEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
