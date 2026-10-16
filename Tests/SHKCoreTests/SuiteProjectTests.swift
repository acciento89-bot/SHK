import Foundation
import Testing
@testable import SHKCore

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
    project.service.coldPressureBar = 1.4; project.service.hotPressureBar = 1.8
    let report = project.reportText(language: .english)
    #expect(report.contains("Cold fill pressure"))
    #expect(report.contains("Safety valve margin"))
    #expect(!report.contains("Kaltfülldruck"))
    #expect(!report.contains("Vorgabebereich"))
}
