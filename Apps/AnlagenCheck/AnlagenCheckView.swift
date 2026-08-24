import SwiftUI

struct AnlagenCheckView: View {
    @State private var flow = 55.0
    @State private var returnTemp = 45.0
    @State private var coldPressure = 1.5
    @State private var hotPressure = 1.9
    @State private var minPressure = 1.2
    @State private var maxPressure = 2.0

    private var checks: [SystemCheckResult] {
        AnlagenCheckCalculator.evaluate(flowC: flow, returnC: returnTemp, coldPressureBar: coldPressure, hotPressureBar: hotPressure, allowedMinBar: minPressure, allowedMaxBar: maxPressure)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SHKBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        SHKCard(content: {
                            Text("Heizungsanlage prüfen").font(.headline)
                            MetricField(title: "Vorlauf", unit: "°C", value: $flow)
                            MetricField(title: "Rücklauf", unit: "°C", value: $returnTemp)
                            MetricField(title: "Druck kalt", unit: "bar", value: $coldPressure)
                            MetricField(title: "Druck warm", unit: "bar", value: $hotPressure)
                            MetricField(title: "Vorgabe min.", unit: "bar", value: $minPressure)
                            MetricField(title: "Vorgabe max.", unit: "bar", value: $maxPressure)
                        })
                        ForEach(checks) { check in
                            SHKCard(content: {
                                Text(check.severity.rawValue.uppercased()).font(.caption.weight(.bold)).foregroundStyle(check.severity == .warning ? .orange : (check.severity == .notice ? .yellow : .mint))
                                Text(check.title).font(.headline)
                                Text(check.detail).foregroundStyle(.secondary)
                            })
                        }
                        Text("AnlagenCheck ist eine Plausibilitäts- und Dokumentationshilfe. Herstellerangaben, Normen und Messvorgaben haben Vorrang.")
                            .font(.footnote).foregroundStyle(.secondary).padding(.horizontal)
                    }.padding()
                }
            }.navigationTitle("AnlagenCheck")
        }
    }
}
