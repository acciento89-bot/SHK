import Testing
@testable import SHKCore

@Test func minimumFillPressureUsesStaticHeight() {
    let value = AnlagenCheckCalculator.minimumColdFillPressureBar(staticHeightM: 8, reserveBar: 0.3)
    #expect(value > 1.08 && value < 1.09)
}

@Test func healthySystemCheckIsOk() {
    let results = AnlagenCheckCalculator.evaluateExtended(
        flowC: 55,
        returnC: 45,
        coldPressureBar: 1.5,
        hotPressureBar: 1.9,
        allowedMinBar: 1.2,
        allowedMaxBar: 2.0,
        minimumSpreadK: 5,
        maximumSpreadK: 20,
        staticHeightM: 8,
        staticPressureReserveBar: 0.3,
        safetyValveBar: 3.0,
        requiredSafetyMarginBar: 0.5,
        maximumPressureRiseBar: 1.0
    )

    #expect(results.count == 5)
    #expect(results.allSatisfy { $0.severity == .ok })
    #expect(AnlagenCheckCalculator.overallSeverity(for: results) == .ok)
}

@Test func systemCheckDetectsPressureProblems() {
    let results = AnlagenCheckCalculator.evaluateExtended(
        flowC: 55,
        returnC: 45,
        coldPressureBar: 0.8,
        hotPressureBar: 2.8,
        allowedMinBar: 1.2,
        allowedMaxBar: 2.0,
        minimumSpreadK: 5,
        maximumSpreadK: 20,
        staticHeightM: 10,
        staticPressureReserveBar: 0.3,
        safetyValveBar: 3.0,
        requiredSafetyMarginBar: 0.5,
        maximumPressureRiseBar: 1.0
    )

    #expect(results.contains { $0.id == "coldPressureRange" && $0.severity == .warning })
    #expect(results.contains { $0.id == "staticPressure" && $0.severity == .warning })
    #expect(results.contains { $0.id == "pressureRise" && $0.severity == .notice })
    #expect(results.contains { $0.id == "safetyMargin" && $0.severity == .notice })
    #expect(AnlagenCheckCalculator.overallSeverity(for: results) == .warning)
}

@Test func reversedTemperatureSensorsAreFlagged() {
    let results = AnlagenCheckCalculator.evaluateExtended(
        flowC: 40,
        returnC: 50,
        coldPressureBar: 1.5,
        hotPressureBar: 1.8,
        allowedMinBar: 1.2,
        allowedMaxBar: 2.0,
        minimumSpreadK: 5,
        maximumSpreadK: 20,
        staticHeightM: 0,
        staticPressureReserveBar: 0.3,
        safetyValveBar: 3.0,
        requiredSafetyMarginBar: 0.5,
        maximumPressureRiseBar: 1.0
    )

    #expect(results.contains { $0.id == "temperatureSpread" && $0.severity == .warning })
}
