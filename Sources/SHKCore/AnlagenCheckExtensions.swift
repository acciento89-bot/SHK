import Foundation

public extension AnlagenCheckCalculator {
    static func minimumColdFillPressureBar(staticHeightM: Double, reserveBar: Double = 0.3) -> Double {
        max(0, staticHeightM) * 0.098_066_5 + max(0, reserveBar)
    }

    static func pressureRiseBar(coldPressureBar: Double, hotPressureBar: Double) -> Double {
        hotPressureBar - coldPressureBar
    }

    static func evaluateExtended(
        flowC: Double,
        returnC: Double,
        coldPressureBar: Double,
        hotPressureBar: Double,
        allowedMinBar: Double,
        allowedMaxBar: Double,
        minimumSpreadK: Double,
        maximumSpreadK: Double,
        staticHeightM: Double,
        staticPressureReserveBar: Double,
        safetyValveBar: Double,
        requiredSafetyMarginBar: Double,
        maximumPressureRiseBar: Double
    ) -> [SystemCheckResult] {
        var results: [SystemCheckResult] = []

        let spread = flowC - returnC
        if spread < 0 {
            results.append(.init(
                id: "temperatureSpread",
                severity: .warning,
                title: "Vorlauf / Rücklauf prüfen",
                detail: "Der Rücklauf liegt über dem Vorlauf. Messpunkte, Fühlerzuordnung oder Betriebszustand prüfen."
            ))
        } else if spread < max(0, minimumSpreadK) || spread > max(minimumSpreadK, maximumSpreadK) {
            results.append(.init(
                id: "temperatureSpread",
                severity: .notice,
                title: "Spreizung außerhalb Vorgabe",
                detail: String(format: "Gemessen %.1f K, eingestellter Bereich %.1f–%.1f K.", spread, minimumSpreadK, maximumSpreadK)
            ))
        } else {
            results.append(.init(
                id: "temperatureSpread",
                severity: .ok,
                title: "Temperaturspreizung im Vorgabebereich",
                detail: String(format: "Gemessen %.1f K.", spread)
            ))
        }

        if coldPressureBar < allowedMinBar || coldPressureBar > allowedMaxBar {
            results.append(.init(
                id: "coldPressureRange",
                severity: .warning,
                title: "Kaltfülldruck außerhalb Vorgabe",
                detail: String(format: "Gemessen %.2f bar, eingestellter Bereich %.2f–%.2f bar.", coldPressureBar, allowedMinBar, allowedMaxBar)
            ))
        } else {
            results.append(.init(
                id: "coldPressureRange",
                severity: .ok,
                title: "Kaltfülldruck im Vorgabebereich",
                detail: String(format: "Gemessen %.2f bar.", coldPressureBar)
            ))
        }

        let minimumFromHeight = minimumColdFillPressureBar(
            staticHeightM: staticHeightM,
            reserveBar: staticPressureReserveBar
        )
        if staticHeightM > 0 {
            if coldPressureBar < minimumFromHeight {
                results.append(.init(
                    id: "staticPressure",
                    severity: .warning,
                    title: "Druck unter statischer Mindestvorgabe",
                    detail: String(format: "Aus %.1f m statischer Höhe + %.2f bar Reserve ergeben sich rechnerisch mindestens %.2f bar.", staticHeightM, staticPressureReserveBar, minimumFromHeight)
                ))
            } else {
                results.append(.init(
                    id: "staticPressure",
                    severity: .ok,
                    title: "Statische Druckhöhe abgedeckt",
                    detail: String(format: "Rechnerische Mindestvorgabe %.2f bar.", minimumFromHeight)
                ))
            }
        }

        let rise = pressureRiseBar(coldPressureBar: coldPressureBar, hotPressureBar: hotPressureBar)
        if rise < 0 {
            results.append(.init(
                id: "pressureRise",
                severity: .warning,
                title: "Druckverlauf prüfen",
                detail: "Der Warmdruck liegt unter dem Kaltfülldruck. Messzeitpunkt und Betriebszustand prüfen."
            ))
        } else if rise > max(0, maximumPressureRiseBar) {
            results.append(.init(
                id: "pressureRise",
                severity: .notice,
                title: "Druckanstieg über Vorgabe",
                detail: String(format: "Anstieg %.2f bar, eingestellte Obergrenze %.2f bar.", rise, maximumPressureRiseBar)
            ))
        } else {
            results.append(.init(
                id: "pressureRise",
                severity: .ok,
                title: "Druckanstieg im Vorgabebereich",
                detail: String(format: "+%.2f bar gegenüber kalt.", rise)
            ))
        }

        if safetyValveBar > 0 {
            let margin = safetyValveBar - hotPressureBar
            if margin <= 0 {
                results.append(.init(
                    id: "safetyMargin",
                    severity: .warning,
                    title: "Warmdruck erreicht Sicherheitsventilwert",
                    detail: String(format: "Warmdruck %.2f bar, eingestellter Sicherheitsventilwert %.2f bar.", hotPressureBar, safetyValveBar)
                ))
            } else if margin < max(0, requiredSafetyMarginBar) {
                results.append(.init(
                    id: "safetyMargin",
                    severity: .notice,
                    title: "Geringe Druckreserve zum Sicherheitsventil",
                    detail: String(format: "Reserve %.2f bar, eingestellte Mindestreserve %.2f bar.", margin, requiredSafetyMarginBar)
                ))
            } else {
                results.append(.init(
                    id: "safetyMargin",
                    severity: .ok,
                    title: "Druckreserve zum Sicherheitsventil vorhanden",
                    detail: String(format: "Aktuelle Reserve %.2f bar.", margin)
                ))
            }
        }

        return results
    }

    static func overallSeverity(for results: [SystemCheckResult]) -> CheckSeverity {
        if results.contains(where: { $0.severity == .warning }) { return .warning }
        if results.contains(where: { $0.severity == .notice }) { return .notice }
        return .ok
    }
}
