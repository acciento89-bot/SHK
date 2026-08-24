import SwiftUI

struct HeizkoerperCalcView: View {
    @State private var nominalPower = 2000.0
    @State private var flow = 55.0
    @State private var returnTemp = 45.0
    @State private var room = 20.0
    @State private var exponent = 1.3

    private var deltaT: Double { RadiatorCalculator.meanTemperatureDifferenceK(flowC: flow, returnC: returnTemp, roomC: room) }
    private var power: Double { RadiatorCalculator.correctedPowerW(nominalPowerW: nominalPower, actualDeltaTK: deltaT, exponent: exponent) }

    var body: some View {
        NavigationStack {
            ZStack {
                SHKBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SHKCard(content: {
                            Text("Leistung umrechnen").font(.headline)
                            MetricField(title: "Nennleistung ΔT50", unit: "W", value: $nominalPower)
                            MetricField(title: "Vorlauf", unit: "°C", value: $flow)
                            MetricField(title: "Rücklauf", unit: "°C", value: $returnTemp)
                            MetricField(title: "Raum", unit: "°C", value: $room)
                            MetricField(title: "Exponent n", unit: "", value: $exponent)
                            BigResult(title: "LEISTUNG", value: String(format: "%.0f W", power), subtitle: String(format: "Mittlere Übertemperatur %.1f K", deltaT))
                        })
                        SHKCard(content: {
                            BigResult(title: "VOLUMENSTROM BEI AKTUELLER SPREIZUNG", value: String(format: "%.0f l/h", RadiatorCalculator.volumeFlowLPH(powerW: power, waterDeltaTK: max(0, flow - returnTemp))), subtitle: "Wasserleistung mit 1,163 Wh/(l·K)")
                        })
                    }.padding()
                }
            }.navigationTitle("HeizkörperCalc")
        }
    }
}
