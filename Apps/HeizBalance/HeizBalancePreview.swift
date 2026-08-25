import Foundation

struct HeizBalanceRoomPreviewState {
    var result: HeizBalanceHeatLossPreviewCalculator.Result?
    var missingInputs: [String]

    var isReady: Bool {
        result != nil && missingInputs.isEmpty
    }
}

extension HeizBalanceRoom {
    func heatLossPreview(designOutdoorTemperatureC: Double?) -> HeizBalanceRoomPreviewState {
        var missingInputs: [String] = []

        guard let designOutdoorTemperatureC else {
            return HeizBalanceRoomPreviewState(
                result: nil,
                missingInputs: ["Auslegungs-Außentemperatur im Projekt fehlt."]
            )
        }

        guard volume > 0 else {
            return HeizBalanceRoomPreviewState(
                result: nil,
                missingInputs: ["Raumabmessungen sind unvollständig."]
            )
        }

        guard let airChangeRatePerHour, airChangeRatePerHour >= 0 else {
            missingInputs.append("Luftwechsel des Raums fehlt.")
            return HeizBalanceRoomPreviewState(result: nil, missingInputs: missingInputs)
        }

        guard !components.isEmpty else {
            return HeizBalanceRoomPreviewState(
                result: nil,
                missingInputs: ["Es wurden noch keine wärmeübertragenden Bauteile erfasst."]
            )
        }

        var surfaces: [HeizBalanceHeatLossPreviewCalculator.SurfaceInput] = []

        for component in components {
            guard component.area > 0 else {
                missingInputs.append("\(component.name): Fläche fehlt.")
                continue
            }

            guard let uValue = component.uValue, uValue >= 0 else {
                missingInputs.append("\(component.name): U-Wert fehlt.")
                continue
            }

            let boundaryTemperatureC: Double
            switch component.effectiveThermalBoundary {
            case .outsideAir:
                boundaryTemperatureC = designOutdoorTemperatureC
            case .customTemperature:
                guard let customTemperature = component.customBoundaryTemperatureC else {
                    missingInputs.append("\(component.name): Temperatur der angrenzenden Seite fehlt.")
                    continue
                }
                boundaryTemperatureC = customTemperature
            }

            surfaces.append(
                .init(
                    id: component.id.uuidString,
                    areaM2: component.area,
                    uValueWPerM2K: uValue,
                    boundaryTemperatureC: boundaryTemperatureC
                )
            )
        }

        guard missingInputs.isEmpty else {
            return HeizBalanceRoomPreviewState(result: nil, missingInputs: missingInputs)
        }

        let result = HeizBalanceHeatLossPreviewCalculator.calculate(
            .init(
                indoorTemperatureC: targetTemperature,
                ventilationAirTemperatureC: designOutdoorTemperatureC,
                roomVolumeM3: volume,
                airChangesPerHour: airChangeRatePerHour,
                surfaces: surfaces
            )
        )

        return HeizBalanceRoomPreviewState(result: result, missingInputs: [])
    }
}
