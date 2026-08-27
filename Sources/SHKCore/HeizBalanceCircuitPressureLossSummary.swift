import Foundation

enum HeizBalanceCircuitPressureLossSummaryCalculator {
    struct ComponentInput: Sendable, Equatable {
        var id: String
        var pressureLossKPa: Double?
    }

    struct Input: Sendable, Equatable {
        var partialPipePressureLossKPa: Double
        var completePipePressureLossKPa: Double?
        var components: [ComponentInput]
        var componentAssessmentComplete: Bool
    }

    struct Result: Sendable, Equatable {
        var knownPipePressureLossKPa: Double
        var knownComponentPressureLossKPa: Double
        var knownCircuitPressureLossKPa: Double
        var completeCircuitPressureLossKPa: Double?
        var pipeCoverageComplete: Bool
        var componentCoverageComplete: Bool
        var missingComponentCount: Int
    }

    static func calculate(_ input: Input) -> Result? {
        guard input.partialPipePressureLossKPa.isFinite,
              input.partialPipePressureLossKPa >= 0 else {
            return nil
        }

        if let completePipe = input.completePipePressureLossKPa,
           (!completePipe.isFinite || completePipe < 0) {
            return nil
        }

        var knownComponents = 0.0
        var missingComponents = 0

        for component in input.components {
            guard let loss = component.pressureLossKPa else {
                missingComponents += 1
                continue
            }
            guard loss.isFinite, loss >= 0 else {
                return nil
            }
            knownComponents += loss
        }

        let pipeComplete = input.completePipePressureLossKPa != nil
        let componentsComplete = input.componentAssessmentComplete && missingComponents == 0
        let knownTotal = input.partialPipePressureLossKPa + knownComponents

        let completeTotal: Double?
        if pipeComplete,
           componentsComplete,
           let completePipe = input.completePipePressureLossKPa {
            completeTotal = completePipe + knownComponents
        } else {
            completeTotal = nil
        }

        return Result(
            knownPipePressureLossKPa: input.partialPipePressureLossKPa,
            knownComponentPressureLossKPa: knownComponents,
            knownCircuitPressureLossKPa: knownTotal,
            completeCircuitPressureLossKPa: completeTotal,
            pipeCoverageComplete: pipeComplete,
            componentCoverageComplete: componentsComplete,
            missingComponentCount: missingComponents
        )
    }
}
