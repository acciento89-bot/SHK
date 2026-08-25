import Foundation

struct HeizBalanceTechnicalReportSnapshot: Codable, Hashable {
    static let schemaVersion = "technical-report-v1"

    var schema: String
    var generatedAt: Date
    var status: Status
    var project: ProjectData
    var floors: [FloorData]
    var hydraulicSystem: HydraulicSystemData?

    struct Status: Codable, Hashable {
        var technicalPreparationOnly: Bool
        var normativeHeatLoadReleased: Bool
        var procedureBReleased: Bool
        var notice: String
    }

    struct ProjectData: Codable, Hashable {
        var projectID: UUID
        var name: String
        var customerName: String
        var address: String
        var buildingYear: String
        var designOutdoorTemperatureC: Double?
        var designOutdoorTemperatureSource: String?
        var designFlowTemperatureC: Double?
        var designReturnTemperatureC: Double?
        var systemTemperatureSource: String?
        var hydraulicFluidDensityKGPerM3: Double?
        var hydraulicKinematicViscosityMM2S: Double?
        var hydraulicFluidSource: String?
        var notes: String
    }

    struct FloorData: Codable, Hashable {
        var id: UUID
        var name: String
        var rooms: [RoomData]
    }

    struct RoomData: Codable, Hashable {
        var id: UUID
        var name: String
        var roomNumber: String
        var lengthM: Double
        var widthM: Double
        var heightM: Double
        var floorAreaM2: Double
        var volumeM3: Double
        var targetTemperatureC: Double
        var airChangeRatePerHour: Double?
        var airChangeSource: String?
        var heatLoss: HeatLossData?
        var missingHeatLossInputs: [String]
        var components: [ThermalComponentData]
        var heatingSurfaces: [HeatingSurfaceData]
    }

    struct HeatLossData: Codable, Hashable {
        var transmissionHeatLossW: Double
        var ventilationHeatLossW: Double
        var totalHeatLossW: Double
    }

    struct ThermalComponentData: Codable, Hashable {
        var id: UUID
        var kind: String
        var name: String
        var areaM2: Double
        var uValueWPerM2K: Double?
        var uValueSource: String?
        var thermalBoundary: String
        var customBoundaryTemperatureC: Double?
        var note: String
    }

    struct HeatingSurfaceData: Codable, Hashable {
        var id: UUID
        var kind: String
        var name: String
        var manufacturer: String
        var model: String
        var nominalPowerDeltaT50W: Double?
        var exponent: Double?
        var powerSource: String?
        var assignedRequiredPowerW: Double?
        var availablePowerW: Double?
        var targetVolumeFlowLPH: Double?
        var capacitySufficient: Bool?
        var pipeSections: [PipeSectionData]
        var hydraulicComponents: [HydraulicComponentData]
        var circuit: CircuitData?
        var note: String
    }

    struct PipeSectionData: Codable, Hashable {
        var id: UUID
        var name: String
        var role: String
        var volumeFlowLPH: Double?
        var volumeFlowSource: String?
        var innerDiameterMM: Double?
        var lengthM: Double?
        var roughnessMM: Double?
        var zetaTotal: Double?
        var velocityMS: Double?
        var reynoldsNumber: Double?
        var pressureDropPaPerM: Double?
        var straightPressureLossKPa: Double?
        var localPressureLossKPa: Double?
        var note: String
    }

    struct HydraulicComponentData: Codable, Hashable {
        var id: UUID
        var kind: String
        var name: String
        var pressureLossKPa: Double?
        var source: String?
        var requiredKvM3H: Double?
        var valveProductData: ValveProductData?
        var note: String
    }

    struct ValveProductData: Codable, Hashable {
        var manufacturer: String
        var productName: String
        var dataSetVersion: String
        var sourceReference: String
        var points: [ValvePresetPointData]
        var comparison: ValveComparisonData?
        var datasetID: String?
        var productID: String?
        var articleNumber: String?
        var sourceURL: String?
        var usageBasis: String?
        var rightsNote: String?
    }

    struct ValvePresetPointData: Codable, Hashable {
        var setting: String
        var kvM3H: Double?
    }

    struct ValveComparisonData: Codable, Hashable {
        var requiredKvM3H: Double
        var minimumKvM3H: Double
        var maximumKvM3H: Double
        var lowerSetting: String?
        var lowerKvM3H: Double?
        var upperSetting: String?
        var upperKvM3H: Double?
        var nearestSetting: String
        var nearestKvM3H: Double
        var relativeDeviation: Double
        var requiredKvInsideDataRange: Bool
        var exactMatch: Bool
        var automaticPresetReleased: Bool
    }

    struct CircuitData: Codable, Hashable {
        var knownPipePressureLossKPa: Double
        var knownComponentPressureLossKPa: Double
        var knownCircuitPressureLossKPa: Double
        var completeCircuitPressureLossKPa: Double?
        var pipeCoverageComplete: Bool
        var componentCoverageComplete: Bool
        var componentAssessmentComplete: Bool
        var missingComponentCount: Int
    }

    struct HydraulicSystemData: Codable, Hashable {
        var circuitCount: Int
        var knownFlowCircuitCount: Int
        var completePressureCircuitCount: Int
        var knownTotalVolumeFlowLPH: Double
        var designTotalVolumeFlowLPH: Double?
        var flowCoverageComplete: Bool
        var pressureCoverageComplete: Bool
        var unfavorableCircuitName: String?
        var designNetworkPressureLossKPa: Double?
        var designNetworkHeadMeters: Double?
        var pumpOperatingPointReady: Bool
        var pumpSelectionReleased: Bool
    }
}

extension HeizBalanceProject {
    func technicalReportSnapshot(generatedAt: Date = Date()) -> HeizBalanceTechnicalReportSnapshot {
        let floorData = floors.map { floor in
            HeizBalanceTechnicalReportSnapshot.FloorData(
                id: floor.id,
                name: floor.name,
                rooms: floor.rooms.map { room in
                    technicalReportRoom(room)
                }
            )
        }

        let hydraulicState = hydraulicSystemPreparationState()
        let hydraulicSystemData = hydraulicState.result.map { result in
            HeizBalanceTechnicalReportSnapshot.HydraulicSystemData(
                circuitCount: result.circuitCount,
                knownFlowCircuitCount: result.knownFlowCircuitCount,
                completePressureCircuitCount: result.completePressureCircuitCount,
                knownTotalVolumeFlowLPH: result.knownTotalVolumeFlowLPH,
                designTotalVolumeFlowLPH: result.designTotalVolumeFlowLPH,
                flowCoverageComplete: result.flowCoverageComplete,
                pressureCoverageComplete: result.pressureCoverageComplete,
                unfavorableCircuitName: result.designUnfavorableCircuit?.name,
                designNetworkPressureLossKPa: result.designNetworkPressureLossKPa,
                designNetworkHeadMeters: result.designNetworkHeadMeters,
                pumpOperatingPointReady: result.pumpOperatingPointReady,
                pumpSelectionReleased: false
            )
        }

        return HeizBalanceTechnicalReportSnapshot(
            schema: SelfReportSchema.version,
            generatedAt: generatedAt,
            status: .init(
                technicalPreparationOnly: true,
                normativeHeatLoadReleased: false,
                procedureBReleased: false,
                notice: "Technische Vorbereitung – keine freigegebene Norm-Heizlast, keine Verfahren-B-Bestätigung und keine automatische Hersteller-Voreinstellung."
            ),
            project: .init(
                projectID: id,
                name: name,
                customerName: customerName,
                address: displayAddress,
                buildingYear: buildingYear,
                designOutdoorTemperatureC: designOutdoorTemperatureC,
                designOutdoorTemperatureSource: designOutdoorTemperatureSource?.rawValue,
                designFlowTemperatureC: designFlowTemperatureC,
                designReturnTemperatureC: designReturnTemperatureC,
                systemTemperatureSource: systemTemperatureSource?.rawValue,
                hydraulicFluidDensityKGPerM3: hydraulicFluidDensityKGPerM3,
                hydraulicKinematicViscosityMM2S: hydraulicKinematicViscosityMM2S,
                hydraulicFluidSource: hydraulicFluidSource?.rawValue,
                notes: notes
            ),
            floors: floorData,
            hydraulicSystem: hydraulicSystemData
        )
    }

    private enum SelfReportSchema {
        static let version = HeizBalanceTechnicalReportSnapshot.schemaVersion
    }

    private func technicalReportRoom(_ room: HeizBalanceRoom) -> HeizBalanceTechnicalReportSnapshot.RoomData {
        let preview = room.heatLossPreview(designOutdoorTemperatureC: designOutdoorTemperatureC)

        return .init(
            id: room.id,
            name: room.name,
            roomNumber: room.roomNumber,
            lengthM: room.length,
            widthM: room.width,
            heightM: room.height,
            floorAreaM2: room.floorArea,
            volumeM3: room.volume,
            targetTemperatureC: room.targetTemperature,
            airChangeRatePerHour: room.airChangeRatePerHour,
            airChangeSource: room.airChangeSource?.rawValue,
            heatLoss: preview.result.map {
                .init(
                    transmissionHeatLossW: $0.transmissionHeatLossW,
                    ventilationHeatLossW: $0.ventilationHeatLossW,
                    totalHeatLossW: $0.totalHeatLossW
                )
            },
            missingHeatLossInputs: preview.missingInputs,
            components: room.components.map { component in
                .init(
                    id: component.id,
                    kind: component.kind.rawValue,
                    name: component.name,
                    areaM2: component.area,
                    uValueWPerM2K: component.uValue,
                    uValueSource: component.uValueSource?.rawValue,
                    thermalBoundary: component.effectiveThermalBoundary.rawValue,
                    customBoundaryTemperatureC: component.customBoundaryTemperatureC,
                    note: component.note
                )
            },
            heatingSurfaces: (room.heatingSurfaces ?? []).map { surface in
                technicalReportHeatingSurface(surface, room: room)
            }
        )
    }

    private func technicalReportHeatingSurface(
        _ surface: HeizBalanceHeatingSurface,
        room: HeizBalanceRoom
    ) -> HeizBalanceTechnicalReportSnapshot.HeatingSurfaceData {
        let technical = surface.technicalPreview(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: room.targetTemperature
        )
        let hydronic = surface.hydronicPreparation(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: room.targetTemperature
        )
        let pipeCircuit = surface.pipeCircuitPreparation(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: room.targetTemperature,
            densityKGPerM3: hydraulicFluidDensityKGPerM3,
            kinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
        )
        let circuit = surface.circuitPressureLossSummary(
            flowTemperatureC: designFlowTemperatureC,
            returnTemperatureC: designReturnTemperatureC,
            roomTemperatureC: room.targetTemperature,
            densityKGPerM3: hydraulicFluidDensityKGPerM3,
            kinematicViscosityMM2S: hydraulicKinematicViscosityMM2S
        )

        let sectionResults = Dictionary(uniqueKeysWithValues: (pipeCircuit?.sections ?? []).map { ($0.id, $0) })

        return .init(
            id: surface.id,
            kind: surface.kind.rawValue,
            name: surface.name,
            manufacturer: surface.manufacturer,
            model: surface.model,
            nominalPowerDeltaT50W: surface.nominalPowerDeltaT50W,
            exponent: surface.exponent,
            powerSource: surface.powerSource?.rawValue,
            assignedRequiredPowerW: surface.assignedRequiredPowerW,
            availablePowerW: technical?.availablePowerW,
            targetVolumeFlowLPH: hydronic?.targetVolumeFlowLPH,
            capacitySufficient: hydronic?.capacitySufficient,
            pipeSections: (surface.pipeSections ?? []).map { section in
                let result = sectionResults[section.id.uuidString]
                let usedFlow: Double?
                switch section.effectiveRole {
                case .heatingSurfaceBranch:
                    usedFlow = hydronic?.targetVolumeFlowLPH
                case .sharedDistribution:
                    usedFlow = section.explicitDesignVolumeFlowLPH
                }

                return .init(
                    id: section.id,
                    name: section.name,
                    role: section.effectiveRole.rawValue,
                    volumeFlowLPH: result?.volumeFlowLPH ?? usedFlow,
                    volumeFlowSource: section.volumeFlowSource?.rawValue,
                    innerDiameterMM: section.innerDiameterMM,
                    lengthM: section.lengthM,
                    roughnessMM: section.roughnessMM,
                    zetaTotal: section.zetaTotal,
                    velocityMS: result?.velocityMS,
                    reynoldsNumber: result?.reynoldsNumber,
                    pressureDropPaPerM: result?.pressureDropPaPerM,
                    straightPressureLossKPa: result?.straightPressureLossKPa,
                    localPressureLossKPa: result?.localPressureLossKPa,
                    note: section.note
                )
            },
            hydraulicComponents: (surface.hydraulicLossComponents ?? []).map { component in
                technicalReportHydraulicComponent(component, hydronic: hydronic)
            },
            circuit: circuit.map {
                .init(
                    knownPipePressureLossKPa: $0.knownPipePressureLossKPa,
                    knownComponentPressureLossKPa: $0.knownComponentPressureLossKPa,
                    knownCircuitPressureLossKPa: $0.knownCircuitPressureLossKPa,
                    completeCircuitPressureLossKPa: $0.completeCircuitPressureLossKPa,
                    pipeCoverageComplete: $0.pipeCoverageComplete,
                    componentCoverageComplete: $0.componentCoverageComplete,
                    componentAssessmentComplete: surface.isHydraulicComponentAssessmentComplete,
                    missingComponentCount: $0.missingComponentCount
                )
            },
            note: surface.note
        )
    }

    private func technicalReportHydraulicComponent(
        _ component: HeizBalanceHydraulicLossComponent,
        hydronic: HeizBalanceHydronicPreparationCalculator.Result?
    ) -> HeizBalanceTechnicalReportSnapshot.HydraulicComponentData {
        let requiredKv: Double?
        if component.supportsValveProductData,
           let targetFlow = hydronic?.targetVolumeFlowLPH,
           let pressureLoss = component.pressureLossKPa,
           let density = hydraulicFluidDensityKGPerM3 {
            requiredKv = HeizBalanceValveSizingPreparationCalculator.calculate(
                .init(
                    targetVolumeFlowLPH: targetFlow,
                    valvePressureDropKPa: pressureLoss,
                    densityKGPerM3: density
                )
            )?.requiredKvM3H
        } else {
            requiredKv = nil
        }

        let valveData = component.valveProductData.map { data -> HeizBalanceTechnicalReportSnapshot.ValveProductData in
            let validPoints: [HeizBalanceValvePresetComparisonCalculator.SettingPoint]? = {
                var values: [HeizBalanceValvePresetComparisonCalculator.SettingPoint] = []
                for point in data.presetPoints {
                    guard let kv = point.kvM3H else { return nil }
                    values.append(.init(setting: point.setting, kvM3H: kv))
                }
                return values
            }()

            let comparison: HeizBalanceValvePresetComparisonCalculator.Result?
            if let requiredKv, let validPoints, !validPoints.isEmpty {
                comparison = HeizBalanceValvePresetComparisonCalculator.calculate(
                    .init(requiredKvM3H: requiredKv, points: validPoints)
                )
            } else {
                comparison = nil
            }

            return .init(
                manufacturer: data.manufacturer,
                productName: data.productName,
                dataSetVersion: data.dataSetVersion,
                sourceReference: data.sourceReference,
                points: data.presetPoints.map {
                    .init(setting: $0.setting, kvM3H: $0.kvM3H)
                },
                comparison: comparison.map {
                    .init(
                        requiredKvM3H: $0.requiredKvM3H,
                        minimumKvM3H: $0.minimumKvM3H,
                        maximumKvM3H: $0.maximumKvM3H,
                        lowerSetting: $0.lowerPoint?.setting,
                        lowerKvM3H: $0.lowerPoint?.kvM3H,
                        upperSetting: $0.upperPoint?.setting,
                        upperKvM3H: $0.upperPoint?.kvM3H,
                        nearestSetting: $0.nearestPoint.setting,
                        nearestKvM3H: $0.nearestPoint.kvM3H,
                        relativeDeviation: $0.relativeDeviation,
                        requiredKvInsideDataRange: $0.requiredKvInsideDataRange,
                        exactMatch: $0.exactMatch,
                        automaticPresetReleased: false
                    )
                },
                datasetID: data.datasetID,
                productID: data.productID,
                articleNumber: data.articleNumber,
                sourceURL: data.sourceURL,
                usageBasis: data.usageBasis,
                rightsNote: data.rightsNote
            )
        }

        return .init(
            id: component.id,
            kind: component.kind.rawValue,
            name: component.name,
            pressureLossKPa: component.pressureLossKPa,
            source: component.source?.rawValue,
            requiredKvM3H: requiredKv,
            valveProductData: valveData,
            note: component.note
        )
    }
}
