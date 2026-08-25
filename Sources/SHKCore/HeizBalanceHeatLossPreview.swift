import Foundation

/// Engineering preview for the basic heat-loss building blocks used by HeizBalance.
///
/// This calculator is deliberately not labelled as a DIN EN 12831 implementation.
/// It only evaluates explicitly supplied transmission surfaces and a simple air-change
/// heat loss so the app can validate captured project data before the normative engine
/// is introduced and reference-tested.
enum HeizBalanceHeatLossPreviewCalculator {
    /// Approximate volumetric heat capacity of air in Wh/(m³·K).
    static let airHeatCapacityWhPerM3K = 0.34

    struct SurfaceInput: Sendable, Equatable {
        var id: String
        var areaM2: Double
        var uValueWPerM2K: Double
        var boundaryTemperatureC: Double
    }

    struct RoomInput: Sendable, Equatable {
        var indoorTemperatureC: Double
        var ventilationAirTemperatureC: Double
        var roomVolumeM3: Double
        var airChangesPerHour: Double
        var surfaces: [SurfaceInput]
    }

    struct SurfaceResult: Sendable, Equatable {
        var id: String
        var temperatureDifferenceK: Double
        var heatLossW: Double
    }

    struct Result: Sendable, Equatable {
        var surfaceResults: [SurfaceResult]
        var transmissionHeatLossW: Double
        var ventilationHeatLossW: Double
        var totalHeatLossW: Double
    }

    static func calculate(_ input: RoomInput) -> Result {
        let surfaceResults = input.surfaces.map { surface in
            let area = max(0, surface.areaM2)
            let uValue = max(0, surface.uValueWPerM2K)
            let deltaT = max(0, input.indoorTemperatureC - surface.boundaryTemperatureC)
            return SurfaceResult(
                id: surface.id,
                temperatureDifferenceK: deltaT,
                heatLossW: area * uValue * deltaT
            )
        }

        let transmission = surfaceResults.reduce(0) { $0 + $1.heatLossW }
        let ventilationDeltaT = max(0, input.indoorTemperatureC - input.ventilationAirTemperatureC)
        let ventilation = airHeatCapacityWhPerM3K
            * max(0, input.roomVolumeM3)
            * max(0, input.airChangesPerHour)
            * ventilationDeltaT

        return Result(
            surfaceResults: surfaceResults,
            transmissionHeatLossW: transmission,
            ventilationHeatLossW: ventilation,
            totalHeatLossW: transmission + ventilation
        )
    }
}
