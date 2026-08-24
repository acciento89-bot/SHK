import SwiftUI

struct LueftungsCalcView: View {
    @State private var flow = 250.0
    @State private var velocity = 3.0
    @State private var length = 5.0
    @State private var width = 4.0
    @State private var height = 2.5
    @State private var ach = 1.5

    var body: some View {
        NavigationStack {
            ZStack {
                SHKBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SHKCard(content: {
                            Text("Rundkanal").font(.headline)
                            MetricField(title: "Volumenstrom", unit: "m³/h", value: $flow)
                            MetricField(title: "Zielgeschwindigkeit", unit: "m/s", value: $velocity)
                            BigResult(title: "ERFORDERLICHER Ø", value: String(format: "%.0f mm", VentilationCalculator.roundDiameterMM(volumeFlowM3H: flow, targetVelocityMS: velocity)), subtitle: "Rechnerischer Innendurchmesser")
                        })
                        SHKCard(content: {
                            Text("Luftwechsel").font(.headline)
                            MetricField(title: "Raumlänge", unit: "m", value: $length)
                            MetricField(title: "Raumbreite", unit: "m", value: $width)
                            MetricField(title: "Raumhöhe", unit: "m", value: $height)
                            MetricField(title: "Luftwechsel", unit: "1/h", value: $ach)
                            BigResult(title: "ERFORDERLICHE LUFTMENGE", value: String(format: "%.0f m³/h", VentilationCalculator.requiredFlowM3H(roomLengthM: length, roomWidthM: width, roomHeightM: height, airChangesPerHour: ach)), subtitle: "Raumvolumen × Luftwechsel")
                        })
                    }.padding()
                }
            }.navigationTitle("LüftungsCalc")
        }
    }
}
