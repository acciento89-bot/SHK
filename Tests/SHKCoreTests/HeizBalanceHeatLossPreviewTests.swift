import Testing
@testable import SHKCore

@Test func heizBalancePreviewCalculatesTransmissionAndVentilation() {
    let input = HeizBalanceHeatLossPreviewCalculator.RoomInput(
        indoorTemperatureC: 20,
        ventilationAirTemperatureC: -10,
        roomVolumeM3: 50,
        airChangesPerHour: 0.5,
        surfaces: [
            .init(id: "wall", areaM2: 10, uValueWPerM2K: 0.3, boundaryTemperatureC: -10)
        ]
    )

    let result = HeizBalanceHeatLossPreviewCalculator.calculate(input)

    #expect(abs(result.transmissionHeatLossW - 90) < 0.0001)
    #expect(abs(result.ventilationHeatLossW - 255) < 0.0001)
    #expect(abs(result.totalHeatLossW - 345) < 0.0001)
    #expect(result.surfaceResults.count == 1)
    #expect(abs(result.surfaceResults[0].temperatureDifferenceK - 30) < 0.0001)
}

@Test func heizBalancePreviewHandlesDifferentBoundaryTemperatures() {
    let input = HeizBalanceHeatLossPreviewCalculator.RoomInput(
        indoorTemperatureC: 20,
        ventilationAirTemperatureC: 0,
        roomVolumeM3: 0,
        airChangesPerHour: 0,
        surfaces: [
            .init(id: "outside", areaM2: 5, uValueWPerM2K: 1, boundaryTemperatureC: -5),
            .init(id: "unheated", areaM2: 5, uValueWPerM2K: 1, boundaryTemperatureC: 10)
        ]
    )

    let result = HeizBalanceHeatLossPreviewCalculator.calculate(input)

    #expect(abs(result.surfaceResults[0].heatLossW - 125) < 0.0001)
    #expect(abs(result.surfaceResults[1].heatLossW - 50) < 0.0001)
    #expect(abs(result.transmissionHeatLossW - 175) < 0.0001)
}

@Test func heizBalancePreviewClampsInvalidAndWarmerBoundaryInputs() {
    let input = HeizBalanceHeatLossPreviewCalculator.RoomInput(
        indoorTemperatureC: 20,
        ventilationAirTemperatureC: 25,
        roomVolumeM3: -10,
        airChangesPerHour: -1,
        surfaces: [
            .init(id: "invalid", areaM2: -4, uValueWPerM2K: -1, boundaryTemperatureC: 30)
        ]
    )

    let result = HeizBalanceHeatLossPreviewCalculator.calculate(input)

    #expect(result.transmissionHeatLossW == 0)
    #expect(result.ventilationHeatLossW == 0)
    #expect(result.totalHeatLossW == 0)
}
