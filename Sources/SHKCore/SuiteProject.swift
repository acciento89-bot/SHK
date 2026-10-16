import Foundation

public enum SuiteValidationError: Error, Equatable, Sendable {
    case invalidSource, invalidProject, duplicateIdentity, unsupportedSchema(Int)
}

public enum SuiteLanguage: String, Codable, Sendable { case german, english }

public struct SuiteService: Codable, Equatable, Sendable {
    public var coldPressureBar: Double?
    public var hotPressureBar: Double?
    public var minimumPressureBar = 1.2
    public var maximumPressureBar = 2.0
    public var minimumSpreadK = 5.0
    public var maximumSpreadK = 20.0
    public var staticHeightM = 8.0
    public var staticReserveBar = 0.3
    public var safetyValveBar = 3.0
    public var safetyMarginBar = 0.5
    public var maximumPressureRiseBar = 1.0
    public var completedTasks: Set<String> = []
    public var notes = ""
    public init() {}

    public static let tasks = ["visual", "venting", "filter", "vessel", "safety", "pump"]
    public var isValid: Bool {
        let pressures = [coldPressureBar, hotPressureBar].compactMap { $0 }
        let settings = [minimumPressureBar, maximumPressureBar, staticReserveBar, safetyValveBar, safetyMarginBar, maximumPressureRiseBar]
        return (pressures + settings).allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 100 } &&
            staticHeightM.isFinite && (0...500).contains(staticHeightM) &&
            minimumSpreadK.isFinite && maximumSpreadK.isFinite && minimumSpreadK >= 0 &&
            minimumSpreadK <= maximumSpreadK && maximumSpreadK <= 110 &&
            minimumPressureBar <= maximumPressureBar && safetyValveBar > 0 &&
            completedTasks.isSubset(of: Set(Self.tasks))
    }

    public func checks(flowC: Double, returnC: Double) -> [SystemCheckResult] {
        guard isValid, let coldPressureBar, let hotPressureBar,
              flowC.isFinite, returnC.isFinite, flowC >= returnC else { return [] }
        return AnlagenCheckCalculator.evaluateExtended(flowC: flowC, returnC: returnC,
            coldPressureBar: coldPressureBar, hotPressureBar: hotPressureBar,
            allowedMinBar: minimumPressureBar, allowedMaxBar: maximumPressureBar,
            minimumSpreadK: minimumSpreadK, maximumSpreadK: maximumSpreadK,
            staticHeightM: staticHeightM, staticPressureReserveBar: staticReserveBar,
            safetyValveBar: safetyValveBar, requiredSafetyMarginBar: safetyMarginBar,
            maximumPressureRiseBar: maximumPressureRiseBar)
    }
}

/// One customer/system record owns all six disciplines and explicit transfers.
public struct SuiteProject: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name: String
    public var customer: String
    public var address = ""
    public var createdAt = Date()
    public var updatedAt = Date()
    public var notes = ""
    public var heat = HeatSurvey()
    public var pipe = PipeRoute()
    public var volume = VolumeProject()
    public var air = AirCommission()
    public var cold = ColdSession()
    public var service = SuiteService()

    public init(name: String = "", customer: String = "") {
        self.name = name; self.customer = customer
        heat.name = "Heating"; pipe.name = "Pipe route"
        volume.name = "Water volume"; air.name = "Ventilation"; cold.name = "Refrigeration"
    }

    public var isValid: Bool {
        let components = volume.components
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            heat.isValid && pipe.isValid && air.isValid && cold.isValid && service.isValid &&
            volume.reservePercent.isFinite && (0...100).contains(volume.reservePercent) &&
            components.allSatisfy {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                $0.quantity.isFinite && $0.quantity > 0 && $0.quantity <= 1_000_000 &&
                $0.unitVolumeLiters.isFinite && $0.unitVolumeLiters >= 0 && $0.unitVolumeLiters <= 1_000_000_000
            } &&
            unique(heat.rooms.map(\.id)) && unique(pipe.sections.map(\.id)) &&
            unique(components.map(\.id)) && unique(air.terminals.map(\.id)) && unique(cold.readings.map(\.id)) &&
            volume.calculatedVolumeLiters.isFinite
    }

    public var heatingDemandW: Double { heat.rooms.reduce(0) { $0 + $1.demandW } }
    public var heatingFlowLPH: Double? {
        guard heat.isValid, !heat.rooms.isEmpty, heat.flowC > heat.returnC,
              heatingDemandW.isFinite, heatingDemandW > 0 else { return nil }
        let value = RadiatorCalculator.volumeFlowLPH(powerW: heatingDemandW, waterDeltaTK: heat.flowC - heat.returnC)
        return value.isFinite && value > 0 && value <= 1_000_000 ? value : nil
    }

    public mutating func transferHeatingFlow() throws {
        guard let flow = heatingFlowLPH else { throw SuiteValidationError.invalidSource }
        pipe.flowLPH = flow
    }

    /// Replace only linked pipe entries. Manual components and stable IDs survive.
    public mutating func synchronizePipeVolumes() throws {
        guard pipe.isValid, unique(pipe.sections.map(\.id)) else { throw SuiteValidationError.invalidSource }
        var imported: [VolumeComponent] = []
        for section in pipe.sections {
            let liters = VolumeCalculator.pipeVolumeLiters(innerDiameterMM: section.diameterMM, lengthMeters: section.lengthM)
            guard liters.isFinite, liters > 0 else { throw SuiteValidationError.invalidSource }
            let previous = volume.components.first { $0.sourcePipeSectionID == section.id }
            var component = VolumeComponent(id: previous?.id ?? UUID(), kind: .pipe,
                name: section.name, unitVolumeLiters: liters,
                source: "SHK Werkstatt · pipe route · \(section.id.uuidString)",
                note: "di \(section.diameterMM) mm; L \(section.lengthM) m")
            component.sourcePipeSectionID = section.id
            imported.append(component)
        }
        volume.components = volume.components.filter { $0.sourcePipeSectionID == nil } + imported
        volume.updatedAt = Date()
    }

    private func unique(_ ids: [UUID]) -> Bool { Set(ids).count == ids.count }
}
