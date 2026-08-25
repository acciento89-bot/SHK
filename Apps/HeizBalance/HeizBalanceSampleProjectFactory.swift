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
