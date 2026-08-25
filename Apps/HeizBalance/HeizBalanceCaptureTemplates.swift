import Foundation

enum HeizBalanceRoomQuickTemplate: String, CaseIterable, Identifiable {
    case livingRoom
    case bedroom
    case bathroom
    case kitchen
    case hallway
    case office

    var id: String { rawValue }

    var title: String {
        switch self {
        case .livingRoom: "Wohnzimmer"
        case .bedroom: "Schlafzimmer"
        case .bathroom: "Bad"
        case .kitchen: "Küche"
        case .hallway: "Flur"
        case .office: "Arbeitszimmer"
        }
    }

    var systemImage: String {
        switch self {
        case .livingRoom: "sofa"
        case .bedroom: "bed.double"
        case .bathroom: "shower"
        case .kitchen: "fork.knife"
        case .hallway: "door.left.hand.open"
        case .office: "desktopcomputer"
        }
    }

    func makeRoom() -> HeizBalanceRoom {
        HeizBalanceRoom(
            name: title,
            targetTemperature: 20
        )
    }
}

enum HeizBalanceComponentSetTemplate: String, CaseIterable, Identifiable {
    case exteriorRoomBasic
    case topFloorBasic
    case basementCeilingBasic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .exteriorRoomBasic: "Außenraum-Basis"
        case .topFloorBasic: "Dachraum-Basis"
        case .basementCeilingBasic: "Raum über unbeheiztem Bereich"
        }
    }

    var detail: String {
        switch self {
        case .exteriorRoomBasic:
            "Außenwand, Fenster, Boden und Decke"
        case .topFloorBasic:
            "Außenwand, Fenster, Dach und Boden"
        case .basementCeilingBasic:
            "Außenwand, Fenster und Boden zu anderem Temperaturbereich"
        }
    }

    func makeComponents() -> [HeizBalanceComponent] {
        componentKinds.map { HeizBalanceComponent(kind: $0) }
    }

    private var componentKinds: [HeizBalanceComponent.Kind] {
        switch self {
        case .exteriorRoomBasic:
            [.exteriorWall, .window, .floor, .ceiling]
        case .topFloorBasic:
            [.exteriorWall, .window, .roof, .floor]
        case .basementCeilingBasic:
            [.exteriorWall, .window, .floor]
        }
    }
}

extension HeizBalanceFloor {
    func duplicatedForCapture(suggestedName: String? = nil) -> HeizBalanceFloor {
        HeizBalanceFloor(
            name: suggestedName ?? name + " Kopie",
            rooms: rooms.map { $0.duplicatedForCapture() }
        )
    }
}

extension HeizBalanceRoom {
    func duplicatedForCapture(suggestedName: String? = nil) -> HeizBalanceRoom {
        HeizBalanceRoom(
            name: suggestedName ?? name + " Kopie",
            roomNumber: "",
            length: length,
            width: width,
            height: height,
            targetTemperature: targetTemperature,
            airChangeRatePerHour: airChangeRatePerHour,
            airChangeSource: airChangeSource,
            components: components.map { $0.duplicatedForCapture() },
            heatingSurfaces: heatingSurfaceItems.map { $0.duplicatedPhysicalSurfaceForCapture() }
        )
    }
}

extension HeizBalanceComponent {
    func duplicatedForCapture() -> HeizBalanceComponent {
        HeizBalanceComponent(
            kind: kind,
            name: name,
            area: area,
            uValue: uValue,
            uValueSource: uValueSource,
            thermalBoundary: effectiveThermalBoundary,
            customBoundaryTemperatureC: customBoundaryTemperatureC,
            note: note
        )
    }
}

extension HeizBalanceHeatingSurface {
    func duplicatedPhysicalSurfaceForCapture() -> HeizBalanceHeatingSurface {
        HeizBalanceHeatingSurface(
            kind: kind,
            name: name,
            manufacturer: manufacturer,
            model: model,
            nominalPowerDeltaT50W: nominalPowerDeltaT50W,
            exponent: exponent,
            powerSource: powerSource,
            assignedRequiredPowerW: nil,
            pipeSections: nil,
            hydraulicLossComponents: nil,
            hydraulicComponentAssessmentComplete: nil,
            replacementSelection: nil,
            note: note
        )
    }
}
