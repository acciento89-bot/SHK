import SwiftUI

struct KalteCalcView: View {
    @State private var evaporation = 4.0
    @State private var suction = 11.0
    @State private var condensation = 42.0
    @State private var liquid = 36.0
    @State private var airFlow = 800.0
    @State private var airDelta = 8.0

    var body: some View {
        NavigationStack {
            ZStack {
                SHKBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SHKCard(content: {
                            Text("Überhitzung").font(.headline)
                            MetricField(title: "Verdampfung", unit: "°C", value: $evaporation)
                            MetricField(title: "Sauggas", unit: "°C", value: $suction)
                            BigResult(title: "ERGEBNIS", value: String(format: "%.1f K", RefrigerationCalculator.superheat(suctionGasC: suction, evaporationC: evaporation)), subtitle: "Sauggastemperatur minus Verdampfungstemperatur")
                        })
                        SHKCard(content: {
                            Text("Unterkühlung").font(.headline)
                            MetricField(title: "Kondensation", unit: "°C", value: $condensation)
                            MetricField(title: "Flüssigkeitsleitung", unit: "°C", value: $liquid)
                            BigResult(title: "ERGEBNIS", value: String(format: "%.1f K", RefrigerationCalculator.subcooling(condensationC: condensation, liquidLineC: liquid)), subtitle: "Kondensation minus Flüssigkeitsleitung")
                        })
                        SHKCard(content: {
                            Text("Luftseitige Leistung").font(.headline)
                            MetricField(title: "Luftmenge", unit: "m³/h", value: $airFlow)
                            MetricField(title: "ΔT Luft", unit: "K", value: $airDelta)
                            BigResult(title: "NÄHERUNG", value: String(format: "%.2f kW", RefrigerationCalculator.airSideCapacityKW(volumeFlowM3H: airFlow, deltaTK: airDelta)), subtitle: "Luftseitige sensible Näherung")
                        })
                    }.padding()
                }
            }
            .navigationTitle("KälteCalc")
        }
    }
}
