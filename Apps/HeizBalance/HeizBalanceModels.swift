import Foundation

struct HeizBalanceProject: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var customerName: String
    var street: String
    var postalCode: String
    var city: String
    var buildingYear: String
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
    var components: [HeizBalanceComponent]

    init(
        id: UUID = UUID(),
        name: String = "Raum",
        roomNumber: String = "",
        length: Double = 0,
        width: Double = 0,
        height: Double = 2.50,
        targetTemperature: Double = 20,
        components: [HeizBalanceComponent] = []
    ) {
        self.id = id
        self.name = name
        self.roomNumber = roomNumber
        self.length = length
        self.width = width
        self.height = height
        self.targetTemperature = targetTemperature
        self.components = components
    }

    var floorArea: Double {
        max(0, length) * max(0, width)
    }

    var volume: Double {
        floorArea * max(0, height)
    }
}

struct HeizBalanceComponent: Identifiable, Codable, Hashable {
    var id: UUID
    var kind: Kind
    var name: String
    var area: Double
    var uValue: Double?
    var note: String

    init(
        id: UUID = UUID(),
        kind: Kind,
        name: String = "",
        area: Double = 0,
        uValue: Double? = nil,
        note: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.name = name.isEmpty ? kind.title : name
        self.area = area
        self.uValue = uValue
        self.note = note
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
