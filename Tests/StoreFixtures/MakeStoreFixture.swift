import Foundation

@main struct MakeStoreFixture {
    static func main() throws {
        let out = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        for de in [true,false] {
            func t(_ a: String,_ b: String)->String {de ? a:b}
            var p = SuiteProject(name: t("Haus Lindenweg", "Linden House"), customer: t("Musterkunde · Beispieldaten", "Sample client · Example data"))
            p.address = t("Musterstraße 12", "12 Sample Street")
            let date = ISO8601DateFormatter().date(from: "2026-10-16T07:41:00Z")!
            p.createdAt = date;p.updatedAt = date
            for (deName,enName,demand,nominal) in [("Wohnzimmer","Living room",900.0,2500.0),("Bad","Bathroom",650.0,1800.0),("Büro","Office",450.0,1400.0)] {
                var r=HeatRoom();r.name=t(deName,enName);r.demandW=demand;r.nominalW=nominal;p.heat.rooms.append(r)
            }
            try p.transferHeatingFlow()
            for (a,b,di,len,zeta) in [("Keller–Verteiler","Basement–manifold",20.0,8.0,2.6),("Steigleitung","Riser",16.0,6.0,3.4),("Wohnbereich","Living area",13.0,10.0,4.2)] {
                var r=PipeSection();r.name=t(a,b);r.diameterMM=di;r.lengthM=len;r.zeta=zeta;p.pipe.sections.append(r)
            }
            try p.synchronizePipeVolumes()
            p.volume.components += [VolumeComponent(kind:.buffer,name:t("Pufferspeicher","Buffer tank"),unitVolumeLiters:80,source:t("Herstellerdaten · Beispiel","Manufacturer data · Example")),VolumeComponent(kind:.radiator,name:t("Heizkörper gesamt","Radiators combined"),unitVolumeLiters:12.6,source:t("Datenblatt · Beispiel","Data sheet · Example")),VolumeComponent(kind:.heatGenerator,name:t("Wärmeerzeuger","Heat generator"),unitVolumeLiters:3.2,source:t("Datenblatt · Beispiel","Data sheet · Example"))]
            var fill=FillCheck();fill.date=date;fill.meterStartL=1200;fill.meterEndL=1200+p.volume.calculatedVolumeLiters+1.2;fill.calculatedBaselineL=p.volume.calculatedVolumeLiters;fill.componentCount=p.volume.components.count;fill.confirmedEmptySystem=true;fill.note=t("Beispiel: Anlage vor Befüllung leer.","Example: system empty before filling.");p.volume.fillChecks=[fill]
            for (a,b,target,measured) in [("Wohnzimmer","Living room",80.0,78.0),("Bad","Bathroom",40.0,38.0),("Büro","Office",35.0,42.0)] {
                var terminal=AirTerminal();terminal.name=t(a,b);terminal.targetM3H=target;terminal.measuredM3H=measured;terminal.note=t("Messhaube · Beispielmessung","Flow hood · Example reading");p.air.terminals.append(terminal)
            }
            p.cold.refrigerant="R32"
            for (index,suction,evap,cond,liquid) in [(0,9.0,2.0,41.0,36.0),(1,8.0,3.0,40.0,35.0),(2,8.4,3.4,40.0,35.5)] {
                var r=ColdReading();r.date=date.addingTimeInterval(Double(index)*900);r.suctionC=suction;r.evaporationC=evap;r.condensationC=cond;r.liquidC=liquid;r.note=t("Beispielmessung","Example reading");p.cold.readings.append(r)
            }
            p.service.measuredFlowC=45;p.service.measuredReturnC=35;p.service.coldPressureBar=1.4;p.service.hotPressureBar=1.8
            p.service.completedTasks=["visual","venting","filter","vessel"]
            p.notes=t("Beispielprojekt zur Veranschaulichung der Funktionen.","Example project illustrating the app's functions.")
            guard p.isValid else { throw SuiteValidationError.invalidProject }
            try SuiteArchive(url:out.appendingPathComponent(de ? "example-de.json":"example-en.json")).save([p])
        }
    }
}
