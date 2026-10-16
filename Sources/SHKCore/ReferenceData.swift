import Foundation

public enum ReferenceData {
    /// Presets are geometry references. Exact manufacturer dimensions always take precedence.
    public static let pipePresets: [PipePreset] = [
        .init(group: "Kupfer", name: "12 × 1 mm", innerDiameterMM: 10, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "15 × 1 mm", innerDiameterMM: 13, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "18 × 1 mm", innerDiameterMM: 16, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "22 × 1 mm", innerDiameterMM: 20, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "28 × 1,5 mm", innerDiameterMM: 25, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "35 × 1,5 mm", innerDiameterMM: 32, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "42 × 1,5 mm", innerDiameterMM: 39, note: "Außen-Ø minus 2 × Wandstärke"),
        .init(group: "Kupfer", name: "54 × 2 mm", innerDiameterMM: 50, note: "Außen-Ø minus 2 × Wandstärke"),

        .init(group: "Mehrschichtverbund", name: "16 × 2 mm", innerDiameterMM: 12, note: "Typischer Dimensionspreset – Hersteller prüfen"),
        .init(group: "Mehrschichtverbund", name: "20 × 2 mm", innerDiameterMM: 16, note: "Typischer Dimensionspreset – Hersteller prüfen"),
        .init(group: "Mehrschichtverbund", name: "26 × 3 mm", innerDiameterMM: 20, note: "Typischer Dimensionspreset – Hersteller prüfen"),
        .init(group: "Mehrschichtverbund", name: "32 × 3 mm", innerDiameterMM: 26, note: "Typischer Dimensionspreset – Hersteller prüfen"),
        .init(group: "Mehrschichtverbund", name: "40 × 3,5 mm", innerDiameterMM: 33, note: "Typischer Dimensionspreset – Hersteller prüfen"),
        .init(group: "Mehrschichtverbund", name: "50 × 4 mm", innerDiameterMM: 42, note: "Typischer Dimensionspreset – Hersteller prüfen"),
        .init(group: "Mehrschichtverbund", name: "63 × 4,5 mm", innerDiameterMM: 54, note: "Typischer Dimensionspreset – Hersteller prüfen"),

        .init(group: "PE-X / FBH", name: "12 × 2 mm", innerDiameterMM: 8, note: "Hersteller prüfen"),
        .init(group: "PE-X / FBH", name: "14 × 2 mm", innerDiameterMM: 10, note: "Hersteller prüfen"),
        .init(group: "PE-X / FBH", name: "16 × 2 mm", innerDiameterMM: 12, note: "Hersteller prüfen"),
        .init(group: "PE-X / FBH", name: "17 × 2 mm", innerDiameterMM: 13, note: "Hersteller prüfen"),
        .init(group: "PE-X / FBH", name: "20 × 2 mm", innerDiameterMM: 16, note: "Hersteller prüfen"),

        .init(group: "Stahl Gewinderohr schwarz", name: "DN 10 · 3/8\"", innerDiameterMM: 12.6, note: "EN 10255 / DIN 2440 Referenz; tatsächlichen Innendurchmesser bei Altbestand prüfen"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 15 · 1/2\"", innerDiameterMM: 16.1, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 20 · 3/4\"", innerDiameterMM: 21.7, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 25 · 1\"", innerDiameterMM: 27.3, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 32 · 1 1/4\"", innerDiameterMM: 35.8, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 40 · 1 1/2\"", innerDiameterMM: 41.9, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 50 · 2\"", innerDiameterMM: 53.1, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 65 · 2 1/2\"", innerDiameterMM: 68.9, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 80 · 3\"", innerDiameterMM: 80.9, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 100 · 4\"", innerDiameterMM: 105.3, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 125 · 5\"", innerDiameterMM: 130.1, note: "EN 10255 / DIN 2440 Referenz"),
        .init(group: "Stahl Gewinderohr schwarz", name: "DN 150 · 6\"", innerDiameterMM: 155.5, note: "EN 10255 / DIN 2440 Referenz"),

        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 10 · 3/8\"", innerDiameterMM: 12.6, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 15 · 1/2\"", innerDiameterMM: 16.1, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 20 · 3/4\"", innerDiameterMM: 21.7, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 25 · 1\"", innerDiameterMM: 27.3, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 32 · 1 1/4\"", innerDiameterMM: 35.8, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 40 · 1 1/2\"", innerDiameterMM: 41.9, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 50 · 2\"", innerDiameterMM: 53.1, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 65 · 2 1/2\"", innerDiameterMM: 68.9, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 80 · 3\"", innerDiameterMM: 80.9, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),
        .init(group: "Stahl Gewinderohr verzinkt", name: "DN 100 · 4\"", innerDiameterMM: 105.3, note: "EN 10255 / DIN 2440 Geometrie; Zinkschicht nicht separat abgezogen"),

        .init(group: "Siederohr normalwandig", name: "17,2 × 1,8 mm", innerDiameterMM: 13.6, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "21,3 × 2,0 mm", innerDiameterMM: 17.3, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "26,9 × 2,3 mm", innerDiameterMM: 22.3, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "33,7 × 2,6 mm", innerDiameterMM: 28.5, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "42,4 × 2,6 mm", innerDiameterMM: 37.2, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "48,3 × 2,6 mm", innerDiameterMM: 43.1, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "60,3 × 2,9 mm", innerDiameterMM: 54.5, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "76,1 × 2,9 mm", innerDiameterMM: 70.3, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "88,9 × 3,2 mm", innerDiameterMM: 82.5, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "114,3 × 3,6 mm", innerDiameterMM: 107.1, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "139,7 × 4,0 mm", innerDiameterMM: 131.7, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "168,3 × 4,5 mm", innerDiameterMM: 159.3, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),
        .init(group: "Siederohr normalwandig", name: "219,1 × 6,3 mm", innerDiameterMM: 206.5, note: "DIN 2448/1629 bzw. EN 10220/10216 Referenz"),

        .init(group: "Edelstahl Press", name: "12 × 1,0 mm", innerDiameterMM: 10.0, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "15 × 1,0 mm", innerDiameterMM: 13.0, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "18 × 1,0 mm", innerDiameterMM: 16.0, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "22 × 1,2 mm", innerDiameterMM: 19.6, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "28 × 1,2 mm", innerDiameterMM: 25.6, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "35 × 1,5 mm", innerDiameterMM: 32.0, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "42 × 1,5 mm", innerDiameterMM: 39.0, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "54 × 1,5 mm", innerDiameterMM: 51.0, note: "Mapress/Sanpress Referenz – Hersteller prüfen"),
        .init(group: "Edelstahl Press", name: "76,1 × 2,0 mm", innerDiameterMM: 72.1, note: "Mapress Referenz – Hersteller prüfen"),

        .init(group: "PP-R SDR 6", name: "20 × 3,4 mm", innerDiameterMM: 13.2, note: "DIN 8077/8078 / EN ISO 15874 Referenz – Hersteller prüfen"),
        .init(group: "PP-R SDR 6", name: "25 × 4,2 mm", innerDiameterMM: 16.6, note: "DIN 8077/8078 / EN ISO 15874 Referenz – Hersteller prüfen"),
        .init(group: "PP-R SDR 6", name: "32 × 5,4 mm", innerDiameterMM: 21.2, note: "DIN 8077/8078 / EN ISO 15874 Referenz – Hersteller prüfen"),
        .init(group: "PP-R SDR 6", name: "40 × 6,7 mm", innerDiameterMM: 26.6, note: "DIN 8077/8078 / EN ISO 15874 Referenz – Hersteller prüfen"),
        .init(group: "PP-R SDR 6", name: "50 × 8,3 mm", innerDiameterMM: 33.4, note: "DIN 8077/8078 / EN ISO 15874 Referenz – Hersteller prüfen"),
        .init(group: "PP-R SDR 6", name: "63 × 10,5 mm", innerDiameterMM: 42.0, note: "DIN 8077/8078 / EN ISO 15874 Referenz – Hersteller prüfen")
    ]

    public static let radiatorDatasetName = "Purmo Plan Compact Referenztabelle (Wasserinhalt je lfd. m)"

    /// Manufacturer-specific reference values from Purmo Plan Compact technical documentation.
    /// These are not universal values for all panel radiators.
    public static let radiatorReferences: [RadiatorReference] = [
        .init(type: "10", heightMM: 500, litersPerMeter: 2.7, dataset: radiatorDatasetName),
        .init(type: "10", heightMM: 550, litersPerMeter: 3.0, dataset: radiatorDatasetName),
        .init(type: "10", heightMM: 600, litersPerMeter: 3.2, dataset: radiatorDatasetName),
        .init(type: "10", heightMM: 900, litersPerMeter: 4.5, dataset: radiatorDatasetName),
        .init(type: "11", heightMM: 300, litersPerMeter: 1.6, dataset: radiatorDatasetName),
        .init(type: "11", heightMM: 400, litersPerMeter: 2.2, dataset: radiatorDatasetName),
        .init(type: "11", heightMM: 500, litersPerMeter: 2.7, dataset: radiatorDatasetName),
        .init(type: "11", heightMM: 550, litersPerMeter: 2.9, dataset: radiatorDatasetName),
        .init(type: "11", heightMM: 600, litersPerMeter: 3.2, dataset: radiatorDatasetName),
        .init(type: "11", heightMM: 900, litersPerMeter: 4.5, dataset: radiatorDatasetName),
        .init(type: "21S", heightMM: 500, litersPerMeter: 5.4, dataset: radiatorDatasetName),
        .init(type: "21S", heightMM: 550, litersPerMeter: 6.1, dataset: radiatorDatasetName),
        .init(type: "21S", heightMM: 600, litersPerMeter: 6.5, dataset: radiatorDatasetName),
        .init(type: "21S", heightMM: 900, litersPerMeter: 9.0, dataset: radiatorDatasetName),
        .init(type: "21S", heightMM: 950, litersPerMeter: 9.1, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 300, litersPerMeter: 3.4, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 400, litersPerMeter: 4.5, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 500, litersPerMeter: 5.5, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 550, litersPerMeter: 6.1, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 600, litersPerMeter: 6.6, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 900, litersPerMeter: 9.0, dataset: radiatorDatasetName),
        .init(type: "22", heightMM: 950, litersPerMeter: 9.3, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 300, litersPerMeter: 5.1, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 400, litersPerMeter: 6.7, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 500, litersPerMeter: 8.2, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 550, litersPerMeter: 9.0, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 600, litersPerMeter: 9.8, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 900, litersPerMeter: 13.3, dataset: radiatorDatasetName),
        .init(type: "33", heightMM: 950, litersPerMeter: 14.0, dataset: radiatorDatasetName)
    ]

    public static let steelSectionDataset = "DIN-Stahlradiator Referenzwerte (DIN 4703 / EN 442)"
    public static let castIronSectionDataset = "DIN-Gussradiator Bestandsreferenz (DIN 4703 / DIN 4720)"

    /// Section radiator references are intended for common legacy radiators. Exact manufacturer data wins.
    public static let sectionRadiatorReferences: [SectionRadiatorReference] = [
        .init(material: .steel, heightMM: 300, centerDistanceMM: 200, depthMM: 250, litersPerSection: 1.075, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 450, centerDistanceMM: 350, depthMM: 160, litersPerSection: 0.923, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 450, centerDistanceMM: 350, depthMM: 220, litersPerSection: 1.250, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 600, centerDistanceMM: 500, depthMM: 110, litersPerSection: 0.833, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 600, centerDistanceMM: 500, depthMM: 160, litersPerSection: 1.158, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 600, centerDistanceMM: 500, depthMM: 220, litersPerSection: 1.508, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 1000, centerDistanceMM: 900, depthMM: 110, litersPerSection: 1.208, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 1000, centerDistanceMM: 900, depthMM: 160, litersPerSection: 1.742, dataset: steelSectionDataset),
        .init(material: .steel, heightMM: 1000, centerDistanceMM: 900, depthMM: 220, litersPerSection: 2.300, dataset: steelSectionDataset),

        .init(material: .castIron, heightMM: 280, centerDistanceMM: 200, depthMM: 250, litersPerSection: 0.9, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 430, centerDistanceMM: 350, depthMM: 70, litersPerSection: 0.4, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 430, centerDistanceMM: 350, depthMM: 110, litersPerSection: 0.6, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 430, centerDistanceMM: 350, depthMM: 160, litersPerSection: 0.8, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 430, centerDistanceMM: 350, depthMM: 220, litersPerSection: 1.1, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 580, centerDistanceMM: 500, depthMM: 70, litersPerSection: 0.5, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 580, centerDistanceMM: 500, depthMM: 110, litersPerSection: 0.8, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 580, centerDistanceMM: 500, depthMM: 160, litersPerSection: 1.1, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 580, centerDistanceMM: 500, depthMM: 220, litersPerSection: 1.3, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 680, centerDistanceMM: 600, depthMM: 160, litersPerSection: 1.2, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 980, centerDistanceMM: 900, depthMM: 70, litersPerSection: 0.8, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 980, centerDistanceMM: 900, depthMM: 160, litersPerSection: 1.5, dataset: castIronSectionDataset),
        .init(material: .castIron, heightMM: 980, centerDistanceMM: 900, depthMM: 220, litersPerSection: 1.9, dataset: castIronSectionDataset)
    ]

    public static func radiatorReference(type: String, heightMM: Int) -> RadiatorReference? {
        radiatorReferences.first { $0.type == type && $0.heightMM == heightMM }
    }

    public static func sectionRadiators(material: SectionRadiatorReference.Material) -> [SectionRadiatorReference] {
        sectionRadiatorReferences.filter { $0.material == material }
    }
}
