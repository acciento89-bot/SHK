import Foundation

public enum VolumeCalculator {
    /// Cylinder volume using true inner diameter. Result is litres.
    /// Formula: π/4 × d² × L, with d in mm and L in m.
    public static func pipeVolumeLiters(innerDiameterMM: Double, lengthMeters: Double) -> Double {
        guard innerDiameterMM > 0, lengthMeters > 0 else { return 0 }
        let areaMM2 = Double.pi * pow(innerDiameterMM, 2) / 4
        return areaMM2 * lengthMeters / 1000
    }

    public static func radiatorVolumeLiters(
        litersPerMeter: Double,
        lengthMM: Double,
        quantity: Double = 1
    ) -> Double {
        guard litersPerMeter > 0, lengthMM > 0, quantity > 0 else { return 0 }
        return litersPerMeter * (lengthMM / 1000) * quantity
    }

    public static func sectionRadiatorVolumeLiters(
        litersPerSection: Double,
        sections: Double,
        quantity: Double = 1
    ) -> Double {
        guard litersPerSection > 0, sections > 0, quantity > 0 else { return 0 }
        return litersPerSection * sections * quantity
    }

    public static func componentForPipe(
        preset: PipePreset,
        lengthMeters: Double,
        circuits: Double = 1,
        kind: ComponentKind = .pipe,
        customName: String? = nil
    ) -> VolumeComponent {
        let unit = pipeVolumeLiters(innerDiameterMM: preset.innerDiameterMM, lengthMeters: lengthMeters)
        return VolumeComponent(
            kind: kind,
            name: customName ?? "\(preset.group) \(preset.name)",
            quantity: circuits,
            unitVolumeLiters: unit,
            source: "Geometrisch aus Innendurchmesser \(format(preset.innerDiameterMM)) mm",
            note: preset.note.isEmpty ? nil : preset.note
        )
    }

    public static func componentForRadiator(
        reference: RadiatorReference,
        lengthMM: Double,
        quantity: Double
    ) -> VolumeComponent {
        let each = radiatorVolumeLiters(litersPerMeter: reference.litersPerMeter, lengthMM: lengthMM)
        return VolumeComponent(
            kind: .radiator,
            name: "Flachheizkörper Typ \(reference.type), H \(reference.heightMM) mm",
            quantity: quantity,
            unitVolumeLiters: each,
            source: reference.dataset,
            note: "Hersteller-/Baureihenwerte können abweichen. Für exakte Auslegung Hersteller-Wasserinhalt verwenden."
        )
    }

    public static func componentForSectionRadiator(
        reference: SectionRadiatorReference,
        sections: Double,
        quantity: Double
    ) -> VolumeComponent {
        let each = sectionRadiatorVolumeLiters(
            litersPerSection: reference.litersPerSection,
            sections: sections
        )
        return VolumeComponent(
            kind: .radiator,
            name: "\(reference.material.rawValue)-Gliederheizkörper · \(reference.displayName) · \(format(sections)) Glieder",
            quantity: quantity,
            unitVolumeLiters: each,
            source: reference.dataset,
            note: "Bestands-/Normreferenz. Bauform und Hersteller können abweichen; exakten Wasserinhalt bei bekannten Daten manuell eingeben."
        )
    }

    public static func format(_ value: Double) -> String {
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}
