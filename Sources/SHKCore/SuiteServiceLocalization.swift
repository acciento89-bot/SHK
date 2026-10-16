import Foundation

extension SuiteService {
    /// Reuse the existing grading. Translate presentation, never re-grade here.
    public func localizedChecks(flowC: Double, returnC: Double, language: SuiteLanguage) -> [SystemCheckResult] {
        let values = checks(flowC: flowC, returnC: returnC)
        guard language == .english else { return values }
        func n(_ value: Double) -> String {
            value.formatted(.number.locale(Locale(identifier: "en_GB")).precision(.fractionLength(0...2)))
        }
        return values.map { check in
            let title: String, detail: String
            switch check.id {
            case "temperatureSpread":
                title = "Temperature difference"
                detail = "Measured \(n(flowC-returnC)) K; entered range \(n(minimumSpreadK))–\(n(maximumSpreadK)) K."
            case "coldPressureRange":
                title = "Cold fill pressure"
                detail = "Measured \(n(coldPressureBar ?? 0)) bar; entered range \(n(minimumPressureBar))–\(n(maximumPressureBar)) bar."
            case "staticPressure":
                title = "Static fill pressure"
                let required = AnlagenCheckCalculator.minimumColdFillPressureBar(staticHeightM: staticHeightM, reserveBar: staticReserveBar)
                detail = "Entered height \(n(staticHeightM)) m + reserve \(n(staticReserveBar)) bar; calculated minimum \(n(required)) bar."
            case "pressureRise":
                title = "Warm pressure rise"
                let rise = AnlagenCheckCalculator.pressureRiseBar(coldPressureBar: coldPressureBar ?? 0, hotPressureBar: hotPressureBar ?? 0)
                detail = "Measured change \(n(rise)) bar; entered maximum \(n(maximumPressureRiseBar)) bar. Check operating state if negative."
            case "safetyMargin":
                title = "Safety valve margin"
                detail = "Hot pressure \(n(hotPressureBar ?? 0)) bar; entered valve value \(n(safetyValveBar)) bar; required reserve \(n(safetyMarginBar)) bar."
            default:
                title = check.id; detail = "Review entered criteria and actual measurements."
            }
            return SystemCheckResult(id: check.id, severity: check.severity, title: title, detail: detail)
        }
    }
}
