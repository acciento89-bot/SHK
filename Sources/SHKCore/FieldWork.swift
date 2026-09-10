import Foundation

/// Named, local work records. IDs survive edits and exports.
public struct HeatRoom: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var demandW = 800.0
    public var nominalW = 1600.0
    public var exponent = 1.3
    public var roomC = 20.0
    public init() {}
    public func power(flow: Double, returning: Double) -> Double {
        RadiatorCalculator.correctedPowerW(nominalPowerDeltaT50W: nominalW, flowC: flow,
            returnC: returning, roomC: roomC, exponent: exponent)
    }
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        [demandW, nominalW, exponent, roomC].allSatisfy(\.isFinite) &&
        demandW > 0 && demandW <= 100_000_000 && nominalW > 0 && nominalW <= 100_000_000 && exponent > 0 && exponent <= 5 && roomC >= -20 && roomC <= 40
    }
}

public struct HeatSurvey: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var flowC = 45.0
    public var returnC = 35.0
    public var notes = ""
    public var rooms: [HeatRoom] = []
    public init() {}
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        flowC.isFinite && returnC.isFinite && flowC >= returnC && flowC <= 110 && returnC > 0 &&
        rooms.allSatisfy { $0.isValid && returnC > $0.roomC }
    }
    /// A surplus in one room cannot compensate for a deficit in another room.
    public var deficitW: Double {
        rooms.reduce(0) { $0 + max(0, $1.demandW - $1.power(flow: flowC, returning: returnC)) }
    }
    public var deficientRoomCount: Int {
        rooms.filter { $0.power(flow: flowC, returning: returnC) < $0.demandW }.count
    }
}

public struct PipeSection: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var diameterMM = 20.0
    public var lengthM = 10.0
    public var roughnessMM = 0.01
    public var zeta = 0.0
    public init() {}
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        [diameterMM, lengthM, roughnessMM, zeta].allSatisfy(\.isFinite) &&
        diameterMM >= 1 && diameterMM <= 2000 && lengthM > 0 && lengthM <= 10000 &&
        roughnessMM >= 0 && roughnessMM < diameterMM && zeta >= 0 && zeta <= 10000
    }
    public func result(flow: Double) -> ExtendedPipeHydraulics {
        PipeCalculator.calculateExtended(volumeFlowLPH: flow, innerDiameterMM: diameterMM,
            lengthM: lengthM, roughnessMM: roughnessMM, zetaTotal: zeta)
    }
}

public struct PipeRoute: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var flowLPH = 500.0
    public var notes = ""
    public var sections: [PipeSection] = []
    public init() {}
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        flowLPH.isFinite && flowLPH > 0 && flowLPH <= 1_000_000 && sections.allSatisfy(\.isValid)
    }
    public var totalLossKPa: Double {
        sections.reduce(0) { $0 + $1.result(flow: flowLPH).totalPressureLossIncludingLocalKPa }
    }
    public var totalVolumeL: Double {
        sections.reduce(0) { $0 + $1.result(flow: flowLPH).base.pipeVolumeL }
    }
    public var largestLossSection: PipeSection? {
        sections.max { $0.result(flow: flowLPH).totalPressureLossIncludingLocalKPa < $1.result(flow: flowLPH).totalPressureLossIncludingLocalKPa }
    }
}

public enum AirStream: String, Codable, CaseIterable, Sendable { case supply, extract }
public struct AirTerminal: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var stream = AirStream.supply
    public var targetM3H = 40.0
    /// nil means not measured, zero means an actual zero measurement.
    public var measuredM3H: Double? = nil
    public var note = ""
    public init() {}
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        targetM3H.isFinite && targetM3H > 0 && targetM3H <= 1_000_000 &&
        (measuredM3H.map { $0.isFinite && $0 >= 0 && $0 <= 1_000_000 } ?? true)
    }
    public var deviationPercent: Double? {
        guard let measuredM3H, targetM3H > 0 else { return nil }
        return (measuredM3H - targetM3H) / targetM3H * 100
    }
    public func meetsTolerance(_ percent: Double) -> Bool? {
        deviationPercent.map { abs($0) <= percent + 1e-9 }
    }
}

public struct AirCommission: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var tolerancePercent = 10.0
    public var notes = ""
    public var terminals: [AirTerminal] = []
    public init() {}
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        tolerancePercent.isFinite && tolerancePercent >= 0 && tolerancePercent <= 100 && terminals.allSatisfy(\.isValid)
    }
    public var missingCount: Int { terminals.filter { $0.measuredM3H == nil }.count }
    public var outsideCount: Int { terminals.filter { $0.meetsTolerance(tolerancePercent) == false }.count }
    public func target(_ stream: AirStream) -> Double {
        terminals.filter { $0.stream == stream }.reduce(0) { $0 + $1.targetM3H }
    }
    public func measured(_ stream: AirStream) -> Double? {
        let group = terminals.filter { $0.stream == stream }
        guard !group.isEmpty, group.allSatisfy({ $0.measuredM3H != nil }) else { return nil }
        return group.reduce(0) { $0 + ($1.measuredM3H ?? 0) }
    }
}

public struct ColdReading: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var date = Date()
    public var suctionC = 8.0
    public var evaporationC = 2.0
    public var condensationC = 40.0
    public var liquidC = 35.0
    public var note = ""
    public init() {}
    public var isValid: Bool {
        [suctionC, evaporationC, condensationC, liquidC].allSatisfy { $0.isFinite && $0 >= -150 && $0 <= 200 }
    }
    public var superheatK: Double { RefrigerationCalculator.superheat(suctionGasC: suctionC, evaporationC: evaporationC) }
    public var subcoolingK: Double { RefrigerationCalculator.subcooling(condensationC: condensationC, liquidLineC: liquidC) }
}

public struct ColdSession: Codable, Identifiable, Equatable, Sendable {
    public var id = UUID()
    public var name = ""
    public var refrigerant = ""
    public var notes = ""
    public var readings: [ColdReading] = []
    public init() {}
    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && readings.allSatisfy(\.isValid)
    }
    public var chronological: [ColdReading] { readings.sorted { $0.date < $1.date } }
    public var superheatChangeK: Double? {
        guard readings.count > 1, let first = chronological.first, let last = chronological.last else { return nil }
        return last.superheatK - first.superheatK
    }
}
