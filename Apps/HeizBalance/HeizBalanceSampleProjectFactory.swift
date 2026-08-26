import Foundation

enum HeizBalanceSampleProjectFactory {
    static func makeTechnicalDemoProject() -> HeizBalanceProject {
        let sharedFlowLPH = 155.0

        let livingSurface = makeRadiator(
            name: "HK Wohnzimmer",
            nominalPowerW: 2500,
            exponent: 1.3,
            assignedPowerW: 700,
            branchLengthM: 16,
            sharedFlowLPH: sharedFlowLPH
        )
        let bedroomSurface = makeRadiator(
            name: "HK Schlafzimmer",
            nominalPowerW: 1800,
            exponent: 1.3,
            assignedPowerW: 500,
            branchLengthM: 22,
            sharedFlowLPH: sharedFlowLPH
        )
        let bathroomSurface = makeRadiator(
            kind: .towelRadiator,
            name: "Badheizkörper",
            nominalPowerW: 2200,
            exponent: 1.3,
            assignedPowerW: 600,
            branchLengthM: 18,
            sharedFlowLPH: sharedFlowLPH
        )

        let living = HeizBalanceRoom(
            name: "Wohnzimmer",
            roomNumber: "EG-01",
            length: 5.0,
            width: 4.0,
            height: 2.50,
            targetTemperature: 20,
            airChangeRatePerHour: 0.5,
            airChangeSource: .expertValue,
            components: [
                outsideComponent(.exteriorWall, name: "Außenwand Süd", area: 15.0, uValue: 0.35),
                outsideComponent(.window, name: "Fenster Süd", area: 4.0, uValue: 1.20),
                adjacentComponent(.floor, name: "Boden gegen Keller", area: 20.0, uValue: 0.45, adjacentTemperatureC: 10),
                adjacentComponent(.ceiling, name: "Decke", area: 20.0, uValue: 0.25, adjacentTemperatureC: 15)
            ],
            heatingSurfaces: [livingSurface]
        )

        let bedroom = HeizBalanceRoom(
            name: "Schlafzimmer",
            roomNumber: "EG-02",
            length: 4.0,
            width: 3.5,
            height: 2.50,
            targetTemperature: 19,
            airChangeRatePerHour: 0.5,
            airChangeSource: .expertValue,
            components: [
                outsideComponent(.exteriorWall, name: "Außenwand Nord", area: 11.0, uValue: 0.40),
                outsideComponent(.window, name: "Fenster Nord", area: 2.5, uValue: 1.30),
                adjacentComponent(.floor, name: "Boden gegen Keller", area: 14.0, uValue: 0.45, adjacentTemperatureC: 10),
                adjacentComponent(.ceiling, name: "Decke", area: 14.0, uValue: 0.25, adjacentTemperatureC: 15)
            ],
            heatingSurfaces: [bedroomSurface]
        )

        let bathroom = HeizBalanceRoom(
            name: "Bad",
            roomNumber: "EG-03",
            length: 3.0,
            width: 2.4,
            height: 2.50,
            targetTemperature: 24,
            airChangeRatePerHour: 1.0,
            airChangeSource: .expertValue,
            components: [
                outsideComponent(.exteriorWall, name: "Außenwand Bad", area: 15.0, uValue: 0.40),
                outsideComponent(.window, name: "Badfenster", area: 2.0, uValue: 1.30),
                adjacentComponent(.floor, name: "Boden gegen Keller", area: 7.2, uValue: 0.45, adjacentTemperatureC: 10),
                adjacentComponent(.ceiling, name: "Decke", area: 7.2, uValue: 0.25, adjacentTemperatureC: 15)
            ],
            heatingSurfaces: [bathroomSurface]
        )

        return HeizBalanceProject(
            name: "Musterprojekt Niedertemperatur",
            customerName: "Technisches Demoobjekt",
            street: "Musterstraße 12",
            postalCode: "40210",
            city: "Düsseldorf",
            buildingYear: "1998",
            designOutdoorTemperatureC: -10,
            designOutdoorTemperatureSource: .expertValue,
            designFlowTemperatureC: 45,
            designReturnTemperatureC: 35,
            systemTemperatureSource: .expertValue,
            hydraulicFluidDensityKGPerM3: 992.2,
            hydraulicKinematicViscosityMM2S: 0.658,
            hydraulicFluidSource: .expertValue,
            notes: "Fiktives technisches Musterprojekt für Regression, UI- und PDF-Prüfung. Keine normative Referenzrechnung und keine Herstellerfreigabe.",
            floors: [
                HeizBalanceFloor(
                    name: "Erdgeschoss",
                    rooms: [living, bedroom, bathroom]
                )
            ]
        )
    }

    static func makeLargeNetworkStressProject() -> HeizBalanceProject {
        let rootID = UUID()
        var floors: [HeizBalanceFloor] = []
        var segments: [HeizBalanceHydraulicNetwork.Segment] = [
            .init(
                id: rootID,
                name: "Hauptstrang",
                pipeSections: [
                    stressSharedPipe(name: "Heizzentrale → Hauptverteiler", innerDiameterMM: 32, lengthM: 18, zetaTotal: 4)
                ],
                hydraulicLossComponents: [
                    HeizBalanceHydraulicLossComponent(
                        kind: .heatMeter,
                        name: "Wärmemengenzähler Hauptstrang",
                        pressureLossKPa: 2,
                        source: .expertValue,
                        note: "Fiktiver expliziter Δp für Großprojekt-Stresstest."
                    )
                ],
                hydraulicComponentAssessmentComplete: true,
                note: "Fiktiver Hauptstrang für UI-, Hydraulik- und PDF-Stresstest."
            )
        ]

        for floorIndex in 0..<5 {
            let floorSegmentID = UUID()
            let branchIDs = [UUID(), UUID()]
            var branchConsumerIDs = [[UUID](), [UUID]()]
            var rooms: [HeizBalanceRoom] = []

            for roomIndex in 0..<10 {
                let globalIndex = floorIndex * 10 + roomIndex
                let surfaceID = UUID()
                let branchIndex = roomIndex < 5 ? 0 : 1
                branchConsumerIDs[branchIndex].append(surfaceID)

                let assignedPowerW = 500.0 + Double(globalIndex % 6) * 50.0
                let targetTemperature = globalIndex % 10 == 9 ? 24.0 : 20.0
                let roomArea = 14.0 + Double(globalIndex % 5)
                let width = 3.5 + Double(globalIndex % 3) * 0.25
                let length = roomArea / width
                let surface = makeStressRadiator(
                    id: surfaceID,
                    index: globalIndex,
                    assignedPowerW: assignedPowerW,
                    branchLengthM: 8.0 + Double(globalIndex % 7)
                )

                rooms.append(
                    HeizBalanceRoom(
                        name: "Raum \(String(format: "%02d", globalIndex + 1))",
                        roomNumber: "E\(floorIndex + 1)-\(String(format: "%02d", roomIndex + 1))",
                        length: length,
                        width: width,
                        height: 2.50,
                        targetTemperature: targetTemperature,
                        airChangeRatePerHour: targetTemperature > 20 ? 0.8 : 0.5,
                        airChangeSource: .expertValue,
                        components: [
                            outsideComponent(
                                .exteriorWall,
                                name: "Außenwand",
                                area: 10.0 + Double(globalIndex % 6),
                                uValue: 0.35
                            ),
                            outsideComponent(
                                .window,
                                name: "Fenster",
                                area: 2.0 + Double(globalIndex % 3) * 0.5,
                                uValue: 1.20
                            ),
                            adjacentComponent(
                                .floor,
                                name: "Boden",
                                area: roomArea,
                                uValue: 0.45,
                                adjacentTemperatureC: 12
                            ),
                            adjacentComponent(
                                .ceiling,
                                name: "Decke",
                                area: roomArea,
                                uValue: 0.25,
                                adjacentTemperatureC: 16
                            )
                        ],
                        heatingSurfaces: [surface]
                    )
                )
            }

            floors.append(
                HeizBalanceFloor(
                    name: "Ebene \(floorIndex + 1)",
                    rooms: rooms
                )
            )

            segments.append(
                .init(
                    id: floorSegmentID,
                    name: "Steigstrang Ebene \(floorIndex + 1)",
                    parentSegmentID: rootID,
                    pipeSections: [
                        stressSharedPipe(
                            name: "Steigleitung Ebene \(floorIndex + 1)",
                            innerDiameterMM: 25,
                            lengthM: 12 + Double(floorIndex),
                            zetaTotal: 3
                        )
                    ],
                    hydraulicLossComponents: [
                        HeizBalanceHydraulicLossComponent(
                            kind: .balancingValve,
                            name: "Strangregulierventil Ebene \(floorIndex + 1)",
                            pressureLossKPa: 1.5,
                            source: .expertValue,
                            note: "Fiktiver expliziter Δp für Großprojekt-Stresstest."
                        )
                    ],
                    hydraulicComponentAssessmentComplete: true,
                    note: "Fiktiver Etagenstrang."
                )
            )

            for branchIndex in 0..<2 {
                segments.append(
                    .init(
                        id: branchIDs[branchIndex],
                        name: "Teilstrang \(floorIndex + 1).\(branchIndex + 1)",
                        parentSegmentID: floorSegmentID,
                        directConsumerSurfaceIDs: branchConsumerIDs[branchIndex],
                        pipeSections: [
                            stressSharedPipe(
                                name: "Etagenverteilung \(floorIndex + 1).\(branchIndex + 1)",
                                innerDiameterMM: 20,
                                lengthM: 9 + Double(branchIndex),
                                zetaTotal: 2
                            )
                        ],
                        hydraulicLossComponents: [
                            HeizBalanceHydraulicLossComponent(
                                kind: .distributor,
                                name: "Verteiler \(floorIndex + 1).\(branchIndex + 1)",
                                pressureLossKPa: 0.75,
                                source: .expertValue,
                                note: "Fiktiver expliziter Δp für Großprojekt-Stresstest."
                            )
                        ],
                        hydraulicComponentAssessmentComplete: true,
                        note: "Fiktiver Teilstrang mit fünf direkten Heizflächen."
                    )
                )
            }
        }

        return HeizBalanceProject(
            name: "Großprojekt Stress 50 Räume",
            customerName: "Fiktives Mehrzonenobjekt",
            street: "Lasttestweg 50",
            postalCode: "40210",
            city: "Düsseldorf",
            buildingYear: "2005",
            designOutdoorTemperatureC: -10,
            designOutdoorTemperatureSource: .expertValue,
            designFlowTemperatureC: 45,
            designReturnTemperatureC: 35,
            systemTemperatureSource: .expertValue,
            hydraulicFluidDensityKGPerM3: 992.2,
            hydraulicKinematicViscosityMM2S: 0.658,
            hydraulicFluidSource: .expertValue,
            hydraulicNetwork: HeizBalanceHydraulicNetwork(segments: segments),
            notes: "DEBUG-Großprojekt mit 50 Räumen, 50 Heizflächen und 16 Netzsegmenten für UI-Dichte, Navigation, Pfad-Hydraulik und PDF-Seitenumbrüche. Alle Werte sind fiktive Testdaten; keine normative Referenz und keine Herstellerfreigabe.",
            floors: floors
        )
    }

    private static func makeRadiator(
        kind: HeizBalanceHeatingSurface.Kind = .panelRadiator,
        name: String,
        nominalPowerW: Double,
        exponent: Double,
        assignedPowerW: Double,
        branchLengthM: Double,
        sharedFlowLPH: Double
    ) -> HeizBalanceHeatingSurface {
        HeizBalanceHeatingSurface(
            kind: kind,
            name: name,
            manufacturer: "Muster / nicht produktbezogen",
            model: "Technischer Testdatensatz",
            nominalPowerDeltaT50W: nominalPowerW,
            exponent: exponent,
            powerSource: .expertValue,
            assignedRequiredPowerW: assignedPowerW,
            pipeSections: [
                HeizBalancePipeSection(
                    name: "Gemeinsame Verteilung",
                    role: .sharedDistribution,
                    explicitDesignVolumeFlowLPH: sharedFlowLPH,
                    volumeFlowSource: .expertValue,
                    innerDiameterMM: 17.3,
                    lengthM: 8,
                    roughnessMM: 0.007,
                    zetaTotal: 4,
                    note: "Fiktiver gemeinsamer Verteilabschnitt des technischen Musterprojekts."
                ),
                HeizBalancePipeSection(
                    name: "Heizflächen-Anbindung",
                    role: .heatingSurfaceBranch,
                    innerDiameterMM: 13.2,
                    lengthM: branchLengthM,
                    roughnessMM: 0.007,
                    zetaTotal: 8,
                    note: "Fiktive Anbindung des technischen Musterprojekts."
                )
            ],
            hydraulicLossComponents: [
                HeizBalanceHydraulicLossComponent(
                    kind: .thermostaticValve,
                    name: "Thermostatventil",
                    pressureLossKPa: 12,
                    source: .expertValue,
                    note: "Fiktiver Δp für technischen End-to-End-Test; keine Herstellerkennlinie."
                ),
                HeizBalanceHydraulicLossComponent(
                    kind: .returnValve,
                    name: "Rücklaufverschraubung",
                    pressureLossKPa: 3,
                    source: .expertValue,
                    note: "Fiktiver Δp für technischen End-to-End-Test."
                ),
                HeizBalanceHydraulicLossComponent(
                    kind: .heatingSurface,
                    name: "Heizfläche",
                    pressureLossKPa: 1.5,
                    source: .expertValue,
                    note: "Fiktiver Δp für technischen End-to-End-Test."
                )
            ],
            hydraulicComponentAssessmentComplete: true,
            note: "Fiktive Heizfläche zur Prüfung der vollständigen technischen Rechenkette."
        )
    }

    private static func makeStressRadiator(
        id: UUID,
        index: Int,
        assignedPowerW: Double,
        branchLengthM: Double
    ) -> HeizBalanceHeatingSurface {
        HeizBalanceHeatingSurface(
            id: id,
            kind: index % 10 == 9 ? .towelRadiator : .panelRadiator,
            name: "HK \(String(format: "%02d", index + 1))",
            manufacturer: "Muster / nicht produktbezogen",
            model: "Großprojekt-Testdatensatz",
            nominalPowerDeltaT50W: 1_800 + Double(index % 8) * 125,
            exponent: 1.3,
            powerSource: .expertValue,
            assignedRequiredPowerW: assignedPowerW,
            pipeSections: [
                HeizBalancePipeSection(
                    name: "Heizflächen-Anbindung",
                    role: .heatingSurfaceBranch,
                    innerDiameterMM: 13.2,
                    lengthM: branchLengthM,
                    roughnessMM: 0.007,
                    zetaTotal: 8,
                    note: "Fiktive terminale Anbindung für Großprojekt-Stresstest."
                )
            ],
            hydraulicLossComponents: [
                HeizBalanceHydraulicLossComponent(
                    kind: .thermostaticValve,
                    name: "Thermostatventil",
                    pressureLossKPa: 12,
                    source: .expertValue,
                    note: "Fiktiver expliziter Δp für Großprojekt-Stresstest."
                ),
                HeizBalanceHydraulicLossComponent(
                    kind: .returnValve,
                    name: "Rücklaufverschraubung",
                    pressureLossKPa: 3,
                    source: .expertValue,
                    note: "Fiktiver expliziter Δp für Großprojekt-Stresstest."
                )
            ],
            hydraulicComponentAssessmentComplete: true,
            note: "Fiktive Heizfläche für 50-Raum-Stresstest."
        )
    }

    private static func stressSharedPipe(
        name: String,
        innerDiameterMM: Double,
        lengthM: Double,
        zetaTotal: Double
    ) -> HeizBalancePipeSection {
        HeizBalancePipeSection(
            name: name,
            role: .sharedDistribution,
            innerDiameterMM: innerDiameterMM,
            lengthM: lengthM,
            roughnessMM: 0.007,
            zetaTotal: zetaTotal,
            note: "Fiktive segment-eigene Rohrgeometrie für Großprojekt-Stresstest."
        )
    }

    private static func outsideComponent(
        _ kind: HeizBalanceComponent.Kind,
        name: String,
        area: Double,
        uValue: Double
    ) -> HeizBalanceComponent {
        HeizBalanceComponent(
            kind: kind,
            name: name,
            area: area,
            uValue: uValue,
            uValueSource: .expertValue,
            thermalBoundary: .outsideAir,
            note: "Fiktiver technischer Musterwert."
        )
    }

    private static func adjacentComponent(
        _ kind: HeizBalanceComponent.Kind,
        name: String,
        area: Double,
        uValue: Double,
        adjacentTemperatureC: Double
    ) -> HeizBalanceComponent {
        HeizBalanceComponent(
            kind: kind,
            name: name,
            area: area,
            uValue: uValue,
            uValueSource: .expertValue,
            thermalBoundary: .customTemperature,
            customBoundaryTemperatureC: adjacentTemperatureC,
            note: "Fiktiver technischer Musterwert."
        )
    }
}
