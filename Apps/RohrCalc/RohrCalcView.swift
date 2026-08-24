import SwiftUI

struct RohrCalcView: View {
    @State private var flow = 1000.0
    @State private var diameter = 20.0
    @State private var length = 10.0
    @State private var roughness = 0.01

    private var result: PipeHydraulics {
        PipeCalculator.calculate(volumeFlowLPH: flow, innerDiameterMM: diameter, lengthM: length, roughnessMM: roughness)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SHKBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SHKCard(content: {
                            Text("Rohrhydraulik").font(.headline)
                            MetricField(title: "Volumenstrom", unit: "l/h", value: $flow)
                            MetricField(title: "Innendurchmesser", unit: "mm", value: $diameter)
                            MetricField(title: "Länge", unit: "m", value: $length)
                            MetricField(title: "Rauheit", unit: "mm", value: $roughness)
                        })
                        SHKCard(content: {
                            BigResult(title: "STRÖMUNGSGESCHWINDIGKEIT", value: String(format: "%.2f m/s", result.velocityMS), subtitle: "aus Volumenstrom und freiem Querschnitt")
                            Divider().padding(.vertical, 6)
                            BigResult(title: "DRUCKVERLUST", value: String(format: "%.0f Pa/m", result.pressureDropPaPerM), subtitle: String(format: "Gesamt %.2f kPa", result.totalPressureDropKPa))
                            Divider().padding(.vertical, 6)
                            BigResult(title: "ROHRINHALT", value: String(format: "%.2f l", result.pipeVolumeL), subtitle: "Wasserinhalt der eingegebenen Länge")
                        })
                    }.padding()
                }
            }.navigationTitle("RohrCalc")
        }
    }
}
