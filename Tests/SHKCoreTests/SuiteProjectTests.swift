import Foundation
import Testing
@testable import SHKCore

@Test func radiatorCountHandlesRepresentableAndExtremeManufacturerOutputsWithoutTrapping() {
    var project = SuiteProject(name: "Anlage")
    var room = HeatRoom(); room.name = "Bad"
    project.heat.rooms = [room]
    let expected = Int(ceil(room.demandW / room.power(flow: project.heat.flowC, returning: project.heat.returnC)))
    #expect(project.checkedRadiatorCount(for: room) == expected)
    room.nominalW = 1e-20
    project.heat.rooms = [room]
    #expect(project.checkedRadiatorCount(for: room) == nil)
    room.nominalW = .leastNonzeroMagnitude
    project.heat.rooms = [room]
    #expect(project.checkedRadiatorCount(for: room) == nil)
    project.heat.flowC = .nan
    #expect(project.checkedRadiatorCount(for: room) == nil)
}

@Test func fillEntryRequiresBothActualMeterReadingsAndPreservesExplicitZero() {
    var inventory = VolumeProject()
    inventory.components = [VolumeComponent(kind: .buffer, name: "Puffer", unitVolumeLiters: 100)]
    var entry = SuiteFillDraft()
    entry.confirmedEmptySystem = true
    entry.meterEndL = 100
    #expect(entry.completed(in: inventory) == nil)
    entry.meterStartL = 0
    let reading = entry.completed(in: inventory)
    #expect(reading?.meterStartL == 0)
    #expect(reading?.netFillL == 100)
    #expect(reading?.componentCount == 1)
    entry.meterEndL = nil
    #expect(entry.completed(in: inventory) == nil)
    entry.meterEndL = .infinity
    #expect(entry.completed(in: inventory) == nil)
}

@Test func suiteTransfersHeatingDemandUsingSharedSystemTemperatures() throws {
    var project = SuiteProject(name: "Haus Lindenweg", customer: "M. Winter")
    var room = HeatRoom(); room.name = "Bad"; room.demandW = 1163
    project.heat.rooms = [room]
    project.heat.flowC = 45; project.heat.returnC = 35
    try project.transferHeatingFlow()
    #expect(abs(project.pipe.flowLPH - 100) < 0.000001)
    #expect(project.pipe.sections.isEmpty)
    #expect(project.customer == "M. Winter")
}

@Test func invalidHeatTransferPreservesPreviouslyEnteredPipeFlow() {
    var project = SuiteProject(name: "Anlage")
    project.pipe.flowLPH = 720
    #expect(throws: SuiteValidationError.self) { try project.transferHeatingFlow() }
    #expect(project.pipe.flowLPH == 720)
    var room = HeatRoom(); room.name = "Bad"; room.demandW = .nan
    project.heat.rooms = [room]
    #expect(throws: SuiteValidationError.self) { try project.transferHeatingFlow() }
    #expect(project.pipe.flowLPH == 720)
}

@Test func pipeInventorySynchronizationIsIdempotentAndPreservesManualComponents() throws {
    var project = SuiteProject(name: "Anlage")
    var section = PipeSection(); section.name = "Keller"; section.diameterMM = 20; section.lengthM = 10
    project.pipe.sections = [section]
    let tank = VolumeComponent(kind: .buffer, name: "Puffer", unitVolumeLiters: 100)
    project.volume.components = [tank]
    try project.synchronizePipeVolumes()
    let firstIDs = project.volume.components.map(\.id)
    try project.synchronizePipeVolumes()
    #expect(project.volume.components.count == 2)
    #expect(project.volume.components.map(\.id) == firstIDs)
    #expect(abs(project.volume.calculatedVolumeLiters - 103.1415926535898) < 0.0000001)
    #expect(project.volume.components.first(where: { $0.id == tank.id }) == tank)
    project.pipe.sections[0].lengthM = 20
    try project.synchronizePipeVolumes()
    #expect(abs(project.volume.calculatedVolumeLiters - 106.2831853071796) < 0.0000001)
    project.pipe.sections = []
    try project.synchronizePipeVolumes()
    #expect(project.volume.components == [tank])
}

@Test func invalidPipeSyncNeverChangesInventory() throws {
    var project = SuiteProject(name: "Anlage")
    project.volume.components = [VolumeComponent(kind: .buffer, name: "Puffer", unitVolumeLiters: 80)]
    let inventory = project.volume
    var section = PipeSection(); section.name = "Keller"; section.diameterMM = .nan
    project.pipe.sections = [section]
    #expect(throws: SuiteValidationError.self) { try project.synchronizePipeVolumes() }
    #expect(project.volume == inventory)
}

@Test func unifiedArchiveRoundTripsEveryModuleAndItsIdentities() throws {
    var project = SuiteProject(name: "Haus Lindenweg", customer: "M. Winter")
    var room = HeatRoom(); room.name = "Bad"; project.heat.rooms = [room]
    var pipe = PipeSection(); pipe.name = "Keller"; project.pipe.sections = [pipe]
    var air = AirTerminal(); air.name = "Büro"; air.measuredM3H = 0; project.air.terminals = [air]
    project.cold.refrigerant = "R32"; project.cold.readings = [ColdReading()]
    project.service.coldPressureBar = 1.4; project.service.hotPressureBar = 1.9
    project.service.completedTasks = ["visual", "filter"]
    project.notes = "Herstellerunterlagen beim Kunden"
    try project.synchronizePipeVolumes()
    let restored = try JSONDecoder().decode(SuiteProject.self, from: JSONEncoder().encode(project))
    #expect(restored == project)
    #expect(restored.air.terminals[0].measuredM3H == 0)
    #expect(restored.volume.components[0].sourcePipeSectionID == pipe.id)
}

@Test func missingPressureRemainsDifferentFromMeasuredZeroInTheReport() {
    var project = SuiteProject(name: "Anlage")
    let missing = project.reportText(language: .english)
    #expect(missing.contains("Not recorded"))
    project.service.coldPressureBar = 0
    let measured = project.reportText(language: .english)
    #expect(measured.contains("Cold pressure: 0"))
    #expect(measured != missing)
}

@Test func reportContainsSharedIdentityAndAllSixTechnicalSections() {
    let project = SuiteProject(name: "Haus Lindenweg", customer: "M. Winter")
    let german = project.reportText(language: .german)
    for text in ["Haus Lindenweg", "M. Winter", "Wärme", "Rohrnetz", "Wasserinhalt", "Lüftung", "Kälte", "Service", "°C", "Hersteller"] {
        #expect(german.contains(text))
    }
    let english = project.reportText(language: .english)
    for text in ["Heating", "Pipe route", "Water volume", "Ventilation", "Refrigeration", "Service"] {
        #expect(english.contains(text))
    }
}

@Test func unfinishedOrInvalidMeasurementsCannotBecomeSavedPlausibleProjects() {
    var project = SuiteProject(name: "  ")
    #expect(!project.isValid)
    project.name = "Anlage"; project.heat.flowC = .infinity
    #expect(!project.isValid)
    project.heat.flowC = 45; project.service.coldPressureBar = -1
    #expect(!project.isValid)
    project.service.coldPressureBar = nil
    #expect(project.isValid)
    var component = VolumeComponent(kind: .buffer, name: "Speicher", unitVolumeLiters: 20)
    component.quantity = -2; project.volume.components = [component]
    #expect(!project.isValid)
}

@Test func duplicateSourceSectionsDoNotDoubleCountOrMutateExistingInventory() {
    var project = SuiteProject(name: "Anlage")
    let tank = VolumeComponent(kind: .buffer, name: "Puffer", unitVolumeLiters: 80)
    project.volume.components = [tank]
    var section = PipeSection(); section.name = "Keller"
    project.pipe.sections = [section, section]
    #expect(throws: SuiteValidationError.self) { try project.synchronizePipeVolumes() }
    #expect(project.volume.components == [tank])
}

@Test func invalidProjectReportNeverPresentsNumericResultsAsValid() {
    var project = SuiteProject(name: "Anlage")
    project.heat.flowC = .nan
    let report = project.reportText(language: .english)
    #expect(report.contains("No calculation result"))
    #expect(!report.contains("NaN"))
    #expect(!report.contains("Calculated water volume:"))
}

@Test func englishServiceReportLocalizesTheActualCheckStatusAndCriteria() {
    var project = SuiteProject(name: "Site")
    project.service.measuredFlowC = 45; project.service.measuredReturnC = 35
    project.service.coldPressureBar = 1.4; project.service.hotPressureBar = 1.8
    let report = project.reportText(language: .english)
    #expect(report.contains("Cold fill pressure"))
    #expect(report.contains("Safety valve margin"))
    #expect(!report.contains("Kaltfülldruck"))
    #expect(!report.contains("Vorgabebereich"))
}

@Test func serviceCannotTreatUnmeasuredDesignTemperaturesAsAnActualInspection() {
    var project = SuiteProject(name: "Anlage")
    project.service.coldPressureBar = 1.4; project.service.hotPressureBar = 1.8
    let report = project.reportText(language: .english)
    #expect(!report.contains("Temperature difference: Measured"))
    #expect(report.contains("Incomplete check"))
}

@Test func anomalousActualTemperaturesCanBeSavedAndAreFlaggedRatherThanClipped() throws {
    var project = SuiteProject(name: "Sensorprüfung")
    project.service.measuredFlowC = 40; project.service.measuredReturnC = 45
    project.service.coldPressureBar = 1.4; project.service.hotPressureBar = 1.8
    #expect(project.isValid)
    let checks = project.service.recordedChecks(language: .english)
    #expect(checks.first(where: { $0.id == "temperatureSpread" })?.severity == .warning)
    let report = project.reportText(language: .english)
    #expect(report.contains("Measured -5 K"))
    let decoded = try JSONDecoder().decode(SuiteProject.self, from: JSONEncoder().encode(project))
    #expect(decoded.service.measuredReturnC == 45)
}

@Test func emptyInventoryIsMissingRatherThanMeasuredZero() {
    let report = SuiteProject(name: "Neu").reportText(language: .english)
    #expect(!report.contains("Calculated water volume: 0"))
}

@Test func fillEvidenceAndIndividualReadingNotesSurviveFullReport() throws {
    var project = SuiteProject(name: "Füllprüfung")
    var section = PipeSection(); section.name = "Kellerleitung"
    project.pipe.sections = [section]
    try project.synchronizePipeVolumes()
    #expect(!project.volume.components[0].source!.contains(section.id.uuidString))
    var check = FillCheck()
    check.confirmedEmptySystem = true; check.meterStartL = 1200; check.meterEndL = 1220
    check.drainedL = 2; check.calculatedBaselineL = 18; check.componentCount = 1
    check.note = "WMZ-17, vor Befüllung entleert"
    project.volume.fillChecks = [check]
    var terminal = AirTerminal(); terminal.name = "Büro"; terminal.note = "Haube A17"
    project.air.terminals = [terminal]
    var reading = ColdReading(); reading.note = "Kontaktfühler B23"
    project.cold.readings = [reading]
    let text = project.reportText(language: .english)
    for evidence in ["1,200", "1,220", "WMZ-17", "Haube A17", "Kontaktfühler B23", "Fill verification"] { #expect(text.contains(evidence)) }
    check.meterEndL = 1100; project.volume.fillChecks = [check]
    #expect(!project.isValid)
    check.meterEndL = 1220; project.volume.fillChecks = [check, check]
    #expect(!project.isValid)
}
