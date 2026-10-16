import Foundation

extension SuiteProject {
    public func reportText(language: SuiteLanguage) -> String {
        let de = language == .german
        func t(_ german: String, _ english: String) -> String { de ? german : english }
        guard isValid else { return t("Ungültige oder unvollständige Eingaben. Kein Berechnungsergebnis.", "Invalid or incomplete inputs. No calculation result.") }
        let locale = Locale(identifier: de ? "de_DE" : "en_GB")
        func n(_ value: Double, _ digits: Int = 2) -> String {
            guard value.isFinite else { return "—" }
            return value.formatted(.number.locale(locale).precision(.fractionLength(0...digits)))
        }
        let missing = t("Nicht erfasst", "Not recorded")
        func pressure(_ value: Double?) -> String { value.map { n($0) + " bar" } ?? missing }
        var lines = ["SHK Werkstatt · " + t("Projektbericht", "Project report"), name,
            t("Kunde: ", "Customer: ") + (customer.isEmpty ? missing : customer),
            t("Objekt: ", "Site: ") + (address.isEmpty ? missing : address),
            t("Stand: ", "Updated: ") + updatedAt.formatted(.dateTime.year().month().day().hour().minute().locale(locale)), "",
            "1 · " + t("Wärme", "Heating"), t("Auslegung: ", "Design: ") + "VL \(n(heat.flowC)) °C / RL \(n(heat.returnC)) °C · ΔT \(n(heat.flowC-heat.returnC)) K"]
        if heat.rooms.isEmpty { lines.append(missing) }
        for room in heat.rooms {
            lines.append("\(room.name): " + t("Bedarf", "Demand") + " \(n(room.demandW)) W; ΔT50 \(n(room.nominalW)) W; n=\(n(room.exponent, 3)); " + t("Raum", "Room") + " \(n(room.roomC)) °C; " + t("Leistung", "Output") + " \(n(room.power(flow: heat.flowC, returning: heat.returnC))) W")
        }
        if let flow = heatingFlowLPH { lines.append(t("Aus Wärmebedarf: ", "From heat demand: ") + "\(n(flow)) l/h") }
        lines += ["", "2 · " + t("Rohrnetz", "Pipe route"), "Q \(n(pipe.flowLPH)) l/h"]
        if pipe.sections.isEmpty { lines.append(missing) }
        for section in pipe.sections {
            let result = section.result(flow: pipe.flowLPH)
            lines.append("\(section.name): di \(n(section.diameterMM)) mm; L \(n(section.lengthM)) m; ε \(n(section.roughnessMM, 3)) mm; ζ \(n(section.zeta)); Δp \(n(result.totalPressureLossIncludingLocalKPa)) kPa; v \(n(result.base.velocityMS)) m/s; Re \(n(result.reynoldsNumber, 0))")
        }
        if !pipe.sections.isEmpty { lines.append("Σ Δp \(n(pipe.totalLossKPa)) kPa; V \(n(pipe.totalVolumeL)) l") }
        lines += [t("Serieller Fließweg, Wasser20°C; keine verzweigte Netzsimulation.", "Series flow path, water20°C; not a branched network simulation."), "", "3 · " + t("Wasserinhalt", "Water volume")]
        if volume.components.isEmpty { lines.append(missing) }
        for item in volume.components {
            lines.append("\(item.name): \(n(item.quantity)) × \(n(item.unitVolumeLiters)) l = \(n(item.totalLiters)) l; " + t("Quelle: ", "Source: ") + (item.source?.isEmpty == false ? item.source! : missing) + (item.note.map { " · " + $0 } ?? ""))
        }
        if !volume.components.isEmpty {
            lines += [t("Berechneter Wasserinhalt: ", "Calculated water volume: ") + "\(n(volume.calculatedVolumeLiters)) l",
                t("Planungsreserve separat: ", "Planning reserve, separately: ") + "\(n(volume.reservePercent)) % / \(n(volume.reserveLiters)) l"]
        }
        for check in volume.fillChecks ?? [] {
            lines += [t("Füllnachweis: ", "Fill verification: ") + check.date.formatted(.dateTime.year().month().day().hour().minute().locale(locale)),
                t("Zähler vorher / nachher: ", "Meter before / after: ") + "\(n(check.meterStartL)) / \(n(check.meterEndL)) l; " + t("abgelassen", "drained") + " \(n(check.drainedL)) l; " + t("netto", "net") + " \(n(check.netFillL)) l",
                t("Festgehaltene Inventar-Basis: ", "Frozen inventory baseline: ") + "\(n(check.calculatedBaselineL)) l / \(check.componentCount) " + t("Bauteile", "components") + "; " + t("Abweichung", "deviation") + " \(n(check.deviationL)) l / \(check.deviationPercent.map { n($0) } ?? missing) %; ±\(n(check.tolerancePercent)) %",
                t("Anlage anfangs leer und gleiche Systemgrenzen bestätigt. ", "Initially empty system and matching boundaries confirmed. ") + (check.isWithinTolerance ? t("Innerhalb Projekttoleranz.", "Within project tolerance.") : t("Abweichung untersuchen.", "Investigate deviation."))]
            if !check.note.isEmpty { lines.append(check.note) }
        }
        lines += ["", "4 · " + t("Lüftung", "Ventilation")]
        if air.terminals.isEmpty { lines.append(missing) }
        for terminal in air.terminals {
            let measured = terminal.measuredM3H.map { n($0) + " m³/h" } ?? missing
            let stream = terminal.stream == .supply ? t("Zuluft", "Supply") : t("Abluft", "Extract")
            lines.append("\(terminal.name) [\(stream)]: " + t("Soll", "Target") + " \(n(terminal.targetM3H)) m³/h; " + t("Ist", "Measured") + " \(measured); " + t("Abweichung", "Deviation") + " \(terminal.deviationPercent.map { n($0) + " %" } ?? missing)")
            if !terminal.note.isEmpty { lines.append(terminal.note) }
        }
        lines += [t("Projekttoleranz: ", "Project tolerance: ") + "±\(n(air.tolerancePercent)) %", "", "5 · " + t("Kälte", "Refrigeration"), t("Kältemittel: ", "Refrigerant: ") + (cold.refrigerant.isEmpty ? missing : cold.refrigerant)]
        if cold.readings.isEmpty { lines.append(missing) }
        for reading in cold.chronological {
            lines.append(reading.date.formatted(.dateTime.year().month().day().hour().minute().locale(locale)) + ": " + t("Sauggas", "Suction") + " \(n(reading.suctionC)) °C; " + t("Verdampfung", "Evaporation") + " \(n(reading.evaporationC)) °C; " + t("Verflüssigung", "Condensation") + " \(n(reading.condensationC)) °C; " + t("Flüssigkeit", "Liquid") + " \(n(reading.liquidC)) °C; SH \(n(reading.superheatK)) K; SC \(n(reading.subcoolingK)) K")
            if !reading.note.isEmpty { lines.append(reading.note) }
        }
        lines += ["", "6 · Service", t("Vorlauf gemessen: ", "Measured supply: ") + (service.measuredFlowC.map { n($0) + " °C" } ?? missing),
            t("Rücklauf gemessen: ", "Measured return: ") + (service.measuredReturnC.map { n($0) + " °C" } ?? missing),
            t("Druck kalt: ", "Cold pressure: ") + pressure(service.coldPressureBar), t("Druck warm: ", "Hot pressure: ") + pressure(service.hotPressureBar),
            t("Eingestellte Vorgaben: ", "Entered criteria: ") + "\(n(service.minimumPressureBar))–\(n(service.maximumPressureBar)) bar; ΔT \(n(service.minimumSpreadK))–\(n(service.maximumSpreadK)) K; h \(n(service.staticHeightM)) m; " + t("statische Reserve", "static reserve") + " \(n(service.staticReserveBar)) bar; SV \(n(service.safetyValveBar)) bar; " + t("SV-Reserve", "safety margin") + " \(n(service.safetyMarginBar)) bar; max. Δp \(n(service.maximumPressureRiseBar)) bar"]
        let checks = service.recordedChecks(language: language)
        if checks.isEmpty { lines.append(t("Prüfung unvollständig: tatsächliche Vorlauf-, Rücklauf- und beide Druckmessungen erforderlich.", "Incomplete check: actual supply, return and both pressure measurements required.")) }
        for check in checks {
            let severity = de ? check.severity.rawValue : (check.severity == .ok ? "OK" : check.severity == .notice ? "Note" : "Check")
            lines.append("[\(severity)] \(check.title): \(check.detail)")
        }
        let labels = de ? ["Sichtprüfung", "Entlüftung", "Filter", "Ausdehnungsgefäß", "Sicherheitsventil", "Pumpe / Regelung"] : ["Visual inspection", "Venting", "Filter", "Expansion vessel", "Safety valve", "Pump / controls"]
        for (index, task) in SuiteService.tasks.enumerated() { lines.append((service.completedTasks.contains(task) ? "[✓] " : "[ ] ") + labels[index]) }
        for note in [notes, heat.notes, pipe.notes, air.notes, cold.notes, service.notes] where !note.isEmpty { lines += ["", note] }
        lines += ["", t("Berechnungs- und Dokumentationshilfe. Herstellerdaten und tatsächliche Messungen haben Vorrang. Keine automatische Sicherheits- oder Normfreigabe. Fehlende Messungen sind keine Nullmessungen.", "Calculation and documentation aid. Manufacturer data and actual measurements take precedence. Not an automatic safety or standards approval. Missing measurements are not zero measurements.")]
        return lines.joined(separator: "\n")
    }
}
