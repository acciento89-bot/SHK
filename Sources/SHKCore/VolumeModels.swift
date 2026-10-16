import Foundation

public enum ComponentKind: String, Codable, CaseIterable, Sendable {
    case pipe
    case floorHeating
    case wallHeating
    case ceilingHeating
    case radiator
    case buffer
    case heatGenerator
    case hydraulicSeparator
    case distributor
    case heatExchanger
    case other

    public var title: String {
        switch self {
        case .pipe: return "Rohrleitung"
        case .floorHeating: return "Fußbodenheizung"
        case .wallHeating: return "Wandheizung"
        case .ceilingHeating: return "Deckenheizung"
        case .radiator: return "Heizkörper"
        case .buffer: return "Puffer / Speicher"
        case .heatGenerator: return "Wärmeerzeuger"
        case .hydraulicSeparator: return "Hydraulische Weiche"
        case .distributor: return "Verteiler / Sammler"
        case .heatExchanger: return "Wärmetauscher"
        case .other: return "Sonstiges"
        }
    }
}

public struct VolumeComponent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var kind: ComponentKind
    public var name: String
    public var quantity: Double
    public var unitVolumeLiters: Double
    public var source: String?
    public var note: String?
    public var sourcePipeSectionID: UUID? = nil

    public init(
        id: UUID = UUID(),
        kind: ComponentKind,
        name: String,
        quantity: Double = 1,
        unitVolumeLiters: Double,
        source: String? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.quantity = max(0, quantity)
        self.unitVolumeLiters = max(0, unitVolumeLiters)
        self.source = source
        self.note = note
    }

    public var totalLiters: Double { quantity * unitVolumeLiters }
}

public struct VolumeProject: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date
    public var reservePercent: Double
    public var components: [VolumeComponent]
    public var fillChecks: [FillCheck]? = nil

    public init(
        id: UUID = UUID(),
        name: String = "Neue Anlage",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        reservePercent: Double = 5,
        components: [VolumeComponent] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reservePercent = max(0, reservePercent)
        self.components = components
    }

    public var calculatedVolumeLiters: Double {
        components.reduce(0) { $0 + $1.totalLiters }
    }

    public var reserveLiters: Double {
        calculatedVolumeLiters * reservePercent / 100
    }

    public var planningVolumeLiters: Double {
        calculatedVolumeLiters + reserveLiters
    }
}

public struct PipePreset: Identifiable, Hashable, Sendable {
    public let id: String
    public let group: String
    public let name: String
    public let innerDiameterMM: Double
    public let note: String

    public init(group: String, name: String, innerDiameterMM: Double, note: String = "") {
        self.group = group
        self.name = name
        self.innerDiameterMM = innerDiameterMM
        self.note = note
        self.id = "\(group)-\(name)-\(innerDiameterMM)"
    }

    public var litersPerMeter: Double {
        VolumeCalculator.pipeVolumeLiters(innerDiameterMM: innerDiameterMM, lengthMeters: 1)
    }
}

public struct RadiatorReference: Identifiable, Hashable, Sendable {
    public let type: String
    public let heightMM: Int
    public let litersPerMeter: Double
    public let dataset: String

    public var id: String { "\(dataset)-\(type)-\(heightMM)" }

    public init(type: String, heightMM: Int, litersPerMeter: Double, dataset: String) {
        self.type = type
        self.heightMM = heightMM
        self.litersPerMeter = litersPerMeter
        self.dataset = dataset
    }
}

public struct SectionRadiatorReference: Identifiable, Hashable, Sendable {
    public enum Material: String, CaseIterable, Sendable {
        case steel = "Stahl"
        case castIron = "Guss"
    }

    public let material: Material
    public let heightMM: Int
    public let centerDistanceMM: Int
    public let depthMM: Int
    public let litersPerSection: Double
    public let dataset: String

    public var id: String {
        "\(material.rawValue)-\(heightMM)-\(centerDistanceMM)-\(depthMM)-\(litersPerSection)"
    }

    public init(
        material: Material,
        heightMM: Int,
        centerDistanceMM: Int,
        depthMM: Int,
        litersPerSection: Double,
        dataset: String
    ) {
        self.material = material
        self.heightMM = heightMM
        self.centerDistanceMM = centerDistanceMM
        self.depthMM = depthMM
        self.litersPerSection = litersPerSection
        self.dataset = dataset
    }

    public var displayName: String {
        "H \(heightMM) · NA \(centerDistanceMM) · T \(depthMM) mm"
    }
}

/// One complete fill of an initially empty, isolated system. The inventory baseline is frozen.
public struct FillCheck: Identifiable, Codable, Equatable, Sendable {
    public var id = UUID()
    public var date = Date()
    public var meterStartL = 0.0
    public var meterEndL = 0.0
    public var drainedL = 0.0
    public var tolerancePercent = 10.0
    public var calculatedBaselineL = 0.0
    public var componentCount = 0
    public var note = ""
    public var confirmedEmptySystem = false
    public init() {}
    public var netFillL: Double { meterEndL - meterStartL - drainedL }
    public var deviationL: Double { netFillL - calculatedBaselineL }
    public var deviationPercent: Double? {
        calculatedBaselineL > 0 ? deviationL / calculatedBaselineL * 100 : nil
    }
    public var isValid: Bool {
        [meterStartL, meterEndL, drainedL, tolerancePercent, calculatedBaselineL].allSatisfy(\.isFinite) &&
        meterStartL >= 0 && meterEndL > meterStartL && drainedL >= 0 && netFillL > 0 &&
        calculatedBaselineL > 0 && tolerancePercent >= 0 && tolerancePercent <= 100 && confirmedEmptySystem
    }
    public var isWithinTolerance: Bool { deviationPercent.map { abs($0) <= tolerancePercent + 1e-9 } ?? false }
}

public extension VolumeProject {
    var undocumentedComponents: [VolumeComponent] {
        components.filter { ($0.source ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    func totalLiters(for kind: ComponentKind) -> Double {
        components.filter { $0.kind == kind }.reduce(0) { $0 + $1.totalLiters }
    }
}
