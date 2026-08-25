import Foundation

enum HeizBalanceInputSource: String, Codable, CaseIterable, Identifiable {
    case plan
    case manufacturer
    case expertValue
    case measured
    case estimated

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plan: "Plan / Baubeschreibung"
        case .manufacturer: "Herstellerangabe"
        case .expertValue: "Fachlich ermittelter Wert"
        case .measured: "Messung / Nachweis"
        case .estimated: "Geschätzt"
        }
    }
}

struct HeizBalanceProject: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var customerName: String
    var street: String
    var postalCode: String
    var city: String
    var buildingYear: String
    var designOutdoorTemperatureC: Double?
    var designOutdoorTemperatureSource: HeizBalanceInputSource?
    var designFlowTemperatureC: Double?
    var designReturnTemperatureC: Double?
    var systemTemperatureSource: HeizBalanceInputSource?
    var retrofitTargetFlowTemperatureC: Double?
    var retrofitTargetReturnTemperatureC: Double?
    var retrofitTargetTemperatureSource: HeizBalanceInputSource?
    var hydraulicFluidDensityKGPerM3: Double?
    var hydraulicKinematicViscosityMM2S: Double?
    var hydraulicFluidSource: HeizBalanceInputSource?
    var notes: String
    var floors: [HeizBalanceFloor]
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Neues Projekt",
        customerName: String = "",
        street: String = "",
        postalCode: String = "",
        city: String = "",
        buildingYear: String = "",
        designOutdoorTemperatureC: Double? = nil,
        designOutdoorTemperatureSource: HeizBalanceInputSource? = nil,
        designFlowTemperatureC: Double? = nil,
        designReturnTemperatureC: Double? = nil,
        systemTemperatureSource: HeizBalanceInputSource? = nil,
        retrofitTargetFlowTemperatureC: Double? = nil,
        retrofitTargetReturnTemperatureC: Double? = nil,
        retrofitTargetTemperatureSource: HeizBalanceInputSource? = nil,
        hydraulicFluidDensityKGPerM3: Double? = nil,
        hydraulicKinematicViscosityMM2S: Double? = nil,
        hydraulicFluidSource: HeizBalanceInputSource? = nil,
        notes: String = "",
        floors: [HeizBalanceFloor] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.customerName = customerName
        self.street = street
        self.postalCode = postalCode
        self.city = city
        self.buildingYear = buildingYear
        self.designOutdoorTemperatureC = designOutdoorTemperatureC
        self.designOutdoorTemperatureSource = designOutdoorTemperatureSource
        self.designFlowTemperatureC = designFlowTemperatureC
        self.designReturnTemperatureC = designReturnTemperatureC
        self.systemTemperatureSource = systemTemperatureSource
        self.retrofitTargetFlowTemperatureC = retrofitTargetFlowTemperatureC
        self.retrofitTargetReturnTemperatureC = retrofitTargetReturnTemperatureC
        self.retrofitTargetTemperatureSource = retrofitTargetTemperatureSource
        self.hydraulicFluidDensityKGPerM3 = hydraulicFluidDensityKGPerM3
        self.hydraulicKinematicViscosityMM2S = hydraulicKinematicViscosityMM2S
        self.hydraulicFluidSource = hydraulicFluidSource
        self.notes = notes
        self.floors = floors
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var roomCount: Int {
        floors.reduce(0) { $0 + $1.rooms.count }
    }

    var displayAddress: String {
        let location = [postalCode, city]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
        return [street, location]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: ", ")
    }
}

struct HeizBalanceFloor: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var rooms: [HeizBalanceRoom]

    init(id: UUID = UUID(), name: String = "Erdgeschoss", rooms: [HeizBalanceRoom] = []) {
        self.id = id
        self.name = name
        self.rooms = rooms
    }
}

struct HeizBalanceRoom: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var roomNumber: String
    var length: Double
    var width: Double
    var height: Double
    var targetTemperature: Double
    var airChangeRatePerHour: Double?
    var airChangeSource: HeizBalanceInputSource?
    var components: [HeizBalanceComponent]
    var heatingSurfaces: [HeizBalanceHeatingSurface]?

    init(
        id: UUID = UUID(),
        name: String = "Raum",
        roomNumber: String = "",
        length: Double = 0,
        width: Double = 0,
        height: Double = 2.50,
        targetTemperature: Double = 20,
        airChangeRatePerHour: Double? = nil,
        airChangeSource: HeizBalanceInputSource? = nil,
        components: [HeizBalanceComponent] = [],
        heatingSurfaces: [HeizBalanceHeatingSurface]? = nil
    ) {
        self.id = id
        self.name = name
        self.roomNumber = roomNumber
        self.length = length
        self.width = width
        self.height = height
        self.targetTemperature = targetTemperature
        self.airChangeRatePerHour = airChangeRatePerHour
        self.airChangeSource = airChangeSource
        self.components = components
        self.heatingSurfaces = heatingSurfaces
    }

    var floorArea: Double {
        HeizBalanceGeometry.floorArea(lengthM: length, widthM: width)
    }

    var volume: Double {
        HeizBalanceGeometry.roomVolume(lengthM: length, widthM: width, heightM: height)
    }

    var heatingSurfaceItems: [HeizBalanceHeatingSurface] {
        get { heatingSurfaces ?? [] }
        set { heatingSurfaces = newValue }
    }
}

struct HeizBalanceHeatingSurface: Identifiable, Codable, Hashable {
    var id: UUID
    var kind: Kind
    var name: String
    var manufacturer: String
    var model: String
    var nominalPowerDeltaT50W: Double?
    var exponent: Double?
    var powerSource: HeizBalanceInputSource?
    var assignedRequiredPowerW: Double?
    var pipeSections: [HeizBalancePipeSection]?
    var hydraulicLossComponents: [HeizBalanceHydraulicLossComponent]?
    var hydraulicComponentAssessmentComplete: Bool?
    var note: String

    init(
        id: UUID = UUID(),
        kind: Kind = .panelRadiator,
        name: String = "",
        manufacturer: String = "",
        model: String = "",
        nominalPowerDeltaT50W: Double? = nil,
        exponent: Double? = nil,
        powerSource: HeizBalanceInputSource? = nil,
        assignedRequiredPowerW: Double? = nil,
        pipeSections: [HeizBalancePipeSection]? = nil,
        hydraulicLossComponents: [HeizBalanceHydraulicLossComponent]? = nil,
        hydraulicComponentAssessmentComplete: Bool? = nil,
        note: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.name = name.isEmpty ? kind.title : name
        self.manufacturer = manufacturer
        self.model = model
        self.nominalPowerDeltaT50W = nominalPowerDeltaT50W
        self.exponent = exponent
        self.powerSource = powerSource
        self.assignedRequiredPowerW = assignedRequiredPowerW
        self.pipeSections = pipeSections
        self.hydraulicLossComponents = hydraulicLossComponents
        self.hydraulicComponentAssessmentComplete = hydraulicComponentAssessmentComplete
        self.note = note
    }

    var pipeSectionItems: [HeizBalancePipeSection] {
        get { pipeSections ?? [] }
        set { pipeSections = newValue }
    }

    var hydraulicLossComponentItems: [HeizBalanceHydraulicLossComponent] {
        get { hydraulicLossComponents ?? [] }
        set { hydraulicLossComponents = newValue }
    }

    var isHydraulicComponentAssessmentComplete: Bool {
        hydraulicComponentAssessmentComplete == true
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case panelRadiator
        case sectionalRadiator
        case towelRadiator
        case convector
        case other

        var id: String { rawValue }

        var title: String {
            switch self {
            case .panelRadiator: "Plattenheizkörper"
            case .sectionalRadiator: "Gliederheizkörper"
            case .towelRadiator: "Badheizkörper"
            case .convector: "Konvektor"
            case .other: "Andere Heizfläche"
            }
        }

        var systemImage: String { "radiator" }
    }
}

struct HeizBalancePipeSection: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var role: Role?
    var explicitDesignVolumeFlowLPH: Double?
    var volumeFlowSource: HeizBalanceInputSource?
    var innerDiameterMM: Double?
    var lengthM: Double?
    var roughnessMM: Double?
    var zetaTotal: Double?
    var note: String

    init(
        id: UUID = UUID(),
        name: String = "Rohrabschnitt",
        role: Role? = nil,
        explicitDesignVolumeFlowLPH: Double? = nil,
        volumeFlowSource: HeizBalanceInputSource? = nil,
        innerDiameterMM: Double? = nil,
        lengthM: Double? = nil,
        roughnessMM: Double? = nil,
        zetaTotal: Double? = nil,
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.explicitDesignVolumeFlowLPH = explicitDesignVolumeFlowLPH
        self.volumeFlowSource = volumeFlowSource
        self.innerDiameterMM = innerDiameterMM
        self.lengthM = lengthM
        self.roughnessMM = roughnessMM
        self.zetaTotal = zetaTotal
        self.note = note
    }

    var effectiveRole: Role {
        role ?? .heatingSurfaceBranch
    }

    enum Role: String, Codable, CaseIterable, Identifiable {
        case heatingSurfaceBranch
        case sharedDistribution

        var id: String { rawValue }

        var title: String {
            switch self {
            case .heatingSurfaceBranch: "Heizflächen-Anbindung"
            case .sharedDistribution: "Gemeinsame Verteilung"
            }
        }
    }
}

struct HeizBalanceHydraulicLossComponent: Identifiable, Codable, Hashable {
    var id: UUID
    var kind: Kind
    var name: String
    var pressureLossKPa: Double?
    var source: HeizBalanceInputSource?
    var valveProductData: HeizBalanceValveProductData?
    var note: String

    init(
        id: UUID = UUID(),
        kind: Kind = .thermostaticValve,
        name: String = "",
        pressureLossKPa: Double? = nil,
        source: HeizBalanceInputSource? = nil,
        valveProductData: HeizBalanceValveProductData? = nil,
        note: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.name = name.isEmpty ? kind.title : name
        self.pressureLossKPa = pressureLossKPa
        self.source = source
        self.valveProductData = valveProductData
        self.note = note
    }

    var supportsValveProductData: Bool {
        kind == .thermostaticValve || kind == .returnValve
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case thermostaticValve
        case returnValve
        case heatingSurface
        case distributor
        case fitting
        case other

        var id: String { rawValue }

        var title: String {
            switch self {
            case .thermostaticValve: "Thermostatventil"
            case .returnValve: "Rücklaufverschraubung"
            case .heatingSurface: "Heizfläche"
            case .distributor: "Verteiler / Sammler"
            case .fitting: "Armatur / Bauteil"
            case .other: "Sonstiger Verlust"
            }
        }
    }
}

struct HeizBalanceComponent: Identifiable, Codable, Hashable {
    var id: UUID
    var kind: Kind
    var name: String
    var area: Double
    var uValue: Double?
    var uValueSource: HeizBalanceInputSource?
    var thermalBoundary: ThermalBoundary?
    var customBoundaryTemperatureC: Double?
    var note: String

    init(
        id: UUID = UUID(),
        kind: Kind,
        name: String = "",
        area: Double = 0,
        uValue: Double? = nil,
        uValueSource: HeizBalanceInputSource? = nil,
        thermalBoundary: ThermalBoundary? = nil,
        customBoundaryTemperatureC: Double? = nil,
        note: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.name = name.isEmpty ? kind.title : name
        self.area = area
        self.uValue = uValue
        self.uValueSource = uValueSource
        self.thermalBoundary = thermalBoundary ?? kind.defaultThermalBoundary
        self.customBoundaryTemperatureC = customBoundaryTemperatureC
        self.note = note
    }

    var effectiveThermalBoundary: ThermalBoundary {
        thermalBoundary ?? kind.defaultThermalBoundary
    }

    enum ThermalBoundary: String, Codable, CaseIterable, Identifiable {
        case outsideAir
        case customTemperature

        var id: String { rawValue }

        var title: String {
            switch self {
            case .outsideAir: "Außenluft"
            case .customTemperature: "Andere Temperatur"
            }
        }
    }

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case exteriorWall
        case window
        case exteriorDoor
        case roof
        case ceiling
        case floor
        case interiorBoundary

        var id: String { rawValue }

        var title: String {
            switch self {
            case .exteriorWall: "Außenwand"
            case .window: "Fenster"
            case .exteriorDoor: "Außentür"
            case .roof: "Dach"
            case .ceiling: "Decke"
            case .floor: "Boden"
            case .interiorBoundary: "Bauteil zu unbeheiztem Bereich"
            }
        }

        var defaultThermalBoundary: ThermalBoundary {
            switch self {
            case .exteriorWall, .window, .exteriorDoor, .roof:
                .outsideAir
            case .ceiling, .floor, .interiorBoundary:
                .customTemperature
            }
        }

        var systemImage: String {
            switch self {
            case .exteriorWall: "rectangle.split.3x1"
            case .window: "window.vertical.closed"
            case .exteriorDoor: "door.left.hand.closed"
            case .roof: "house.lodge"
            case .ceiling: "rectangle.topthird.inset.filled"
            case .floor: "rectangle.bottomthird.inset.filled"
            case .interiorBoundary: "square.split.2x1"
            }
        }
    }
}
