import Foundation

public enum RefrigerationCalculator {
    public static func superheat(suctionGasC: Double, evaporationC: Double) -> Double {
        max(0, suctionGasC - evaporationC)
    }

    public static func subcooling(condensationC: Double, liquidLineC: Double) -> Double {
        max(0, condensationC - liquidLineC)
    }

    public static func airSideCapacityKW(volumeFlowM3H: Double, deltaTK: Double) -> Double {
        max(0, volumeFlowM3H) * max(0, deltaTK) * 0.000335
    }
}

public enum VentilationCalculator {
    public static func roundDiameterMM(volumeFlowM3H: Double, targetVelocityMS: Double) -> Double {
        guard volumeFlowM3H > 0, targetVelocityMS > 0 else { return 0 }
        let q = volumeFlowM3H / 3600
        return sqrt((4 * q) / (.pi * targetVelocityMS)) * 1000
    }

    public static func velocityMS(volumeFlowM3H: Double, widthMM: Double, heightMM: Double) -> Double {
        let area = widthMM / 1000 * heightMM / 1000
        guard area > 0 else { return 0 }
        return volumeFlowM3H / 3600 / area
    }

    public static func requiredFlowM3H(roomLengthM: Double, roomWidthM: Double, roomHeightM: Double, airChangesPerHour: Double) -> Double {
        max(0, roomLengthM) * max(0, roomWidthM) * max(0, roomHeightM) * max(0, airChangesPerHour)
    }

    public static func airChangesPerHour(volumeFlowM3H: Double, roomVolumeM3: Double) -> Double {
        guard roomVolumeM3 > 0 else { return 0 }
        return max(0, volumeFlowM3H) / roomVolumeM3
    }
}

public enum RadiatorCalculator {
    public static func meanTemperatureDifferenceK(flowC: Double, returnC: Double, roomC: Double) -> Double {
        max(0, ((flowC + returnC) / 2) - roomC)
    }

    public static func correctedPowerW(nominalPowerW: Double, actualDeltaTK: Double, nominalDeltaTK: Double = 50, exponent: Double = 1.3) -> Double {
        guard nominalPowerW > 0, actualDeltaTK > 0, nominalDeltaTK > 0, exponent > 0 else { return 0 }
        return nominalPowerW * pow(actualDeltaTK / nominalDeltaTK, exponent)
    }

    public static func volumeFlowLPH(powerW: Double, waterDeltaTK: Double) -> Double {
        guard powerW > 0, waterDeltaTK > 0 else { return 0 }
        return powerW / (1.163 * waterDeltaTK)
    }
}

public struct PipeHydraulics: Sendable {
    public let velocityMS: Double
    public let pipeVolumeL: Double
    public let pressureDropPaPerM: Double
    public let totalPressureDropKPa: Double

    public init(velocityMS: Double, pipeVolumeL: Double, pressureDropPaPerM: Double, totalPressureDropKPa: Double) {
        self.velocityMS = velocityMS
        self.pipeVolumeL = pipeVolumeL
        self.pressureDropPaPerM = pressureDropPaPerM
        self.totalPressureDropKPa = totalPressureDropKPa
    }
}

public enum PipeCalculator {
    public static func calculate(
        volumeFlowLPH: Double,
        innerDiameterMM: Double,
        lengthM: Double,
        roughnessMM: Double = 0.01,
        densityKGPerM3: Double = 998.0,
        kinematicViscosityM2S: Double = 1.004e-6
    ) -> PipeHydraulics {
        guard volumeFlowLPH > 0, innerDiameterMM > 0 else {
            return .init(velocityMS: 0, pipeVolumeL: 0, pressureDropPaPerM: 0, totalPressureDropKPa: 0)
        }

        let d = innerDiameterMM / 1000
        let area = .pi * d * d / 4
        let q = volumeFlowLPH / 1000 / 3600
        let velocity = q / area
        let volumeL = area * max(0, lengthM) * 1000
        let reynolds = velocity * d / kinematicViscosityM2S
        let relativeRoughness = max(0, roughnessMM / 1000) / d

        let friction: Double
        if reynolds > 0 && reynolds < 2300 {
            friction = 64 / reynolds
        } else if reynolds >= 2300 {
            let term = pow(relativeRoughness / 3.7, 1.11) + 6.9 / reynolds
            friction = 1 / pow(-1.8 * log10(term), 2)
        } else {
            friction = 0
        }

        let dpPerM = friction * (densityKGPerM3 * velocity * velocity / 2) / d
        return .init(
            velocityMS: velocity,
            pipeVolumeL: volumeL,
            pressureDropPaPerM: dpPerM,
            totalPressureDropKPa: dpPerM * max(0, lengthM) / 1000
        )
    }
}

public enum CheckSeverity: String, Sendable {
    case ok = "OK"
    case notice = "Hinweis"
    case warning = "Prüfen"
}

public struct SystemCheckResult: Identifiable, Sendable {
    public let id: String
    public let severity: CheckSeverity
    public let title: String
    public let detail: String

    public init(id: String, severity: CheckSeverity, title: String, detail: String) {
        self.id = id
        self.severity = severity
        self.title = title
        self.detail = detail
    }
}

public enum AnlagenCheckCalculator {
    public static func evaluate(flowC: Double, returnC: Double, coldPressureBar: Double, hotPressureBar: Double, allowedMinBar: Double, allowedMaxBar: Double) -> [SystemCheckResult] {
        var results: [SystemCheckResult] = []
        let deltaT = flowC - returnC

        if deltaT < 0 {
            results.append(.init(id: "deltaT", severity: .warning, title: "Vorlauf/Rücklauf prüfen", detail: "Der Rücklauf liegt über dem Vorlauf."))
        } else if deltaT < 2 {
            results.append(.init(id: "deltaT", severity: .notice, title: "Sehr kleine Spreizung", detail: String(format: "Aktuell %.1f K. Betriebszustand und Volumenstrom prüfen.", deltaT)))
        } else if deltaT > 30 {
            results.append(.init(id: "deltaT", severity: .notice, title: "Große Spreizung", detail: String(format: "Aktuell %.1f K. Betriebszustand und Volumenstrom prüfen.", deltaT)))
        } else {
            results.append(.init(id: "deltaT", severity: .ok, title: "Temperaturspreizung plausibel", detail: String(format: "Aktuell %.1f K.", deltaT)))
        }

        if coldPressureBar < allowedMinBar || coldPressureBar > allowedMaxBar {
            results.append(.init(id: "coldPressure", severity: .warning, title: "Kaltfülldruck außerhalb Vorgabe", detail: String(format: "%.2f bar bei eingestelltem Bereich %.2f–%.2f bar.", coldPressureBar, allowedMinBar, allowedMaxBar)))
        } else {
            results.append(.init(id: "coldPressure", severity: .ok, title: "Kaltfülldruck im Vorgabebereich", detail: String(format: "%.2f bar.", coldPressureBar)))
        }

        let rise = hotPressureBar - coldPressureBar
        if rise < 0 {
            results.append(.init(id: "pressureRise", severity: .warning, title: "Druckverlauf prüfen", detail: "Der Warmdruck liegt unter dem Kaltfülldruck."))
        } else {
            results.append(.init(id: "pressureRise", severity: rise > 1.0 ? .notice : .ok, title: "Druckanstieg warm", detail: String(format: "+%.2f bar gegenüber kalt.", rise)))
        }

        return results
    }
}
