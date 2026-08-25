import Foundation

struct HeizBalanceDocumentationMetadata: Codable, Hashable {
    enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
        case workInProgress
        case captureComplete
        case hydraulicPreparationComplete
        case fieldAdjustmentPrepared
        case fieldAdjustmentRecorded
        case handoverPrepared

        var id: String { rawValue }

        var title: String {
            switch self {
            case .workInProgress: "In Bearbeitung"
            case .captureComplete: "Aufnahme vollständig"
            case .hydraulicPreparationComplete: "Hydraulik technisch vorbereitet"
            case .fieldAdjustmentPrepared: "Einstellwerte vorbereitet"
            case .fieldAdjustmentRecorded: "Einstellung dokumentiert"
            case .handoverPrepared: "Übergabe vorbereitet"
            }
        }
    }

    var companyName: String
    var technicianName: String
    var preparedBy: String
    var projectStatus: ProjectStatus
    var executionDate: Date?
    var handoverRecipient: String
    var handoverNote: String
    var signaturePrintedName: String
    var signaturePlace: String

    init(
        companyName: String = "",
        technicianName: String = "",
        preparedBy: String = "",
        projectStatus: ProjectStatus = .workInProgress,
        executionDate: Date? = nil,
        handoverRecipient: String = "",
        handoverNote: String = "",
        signaturePrintedName: String = "",
        signaturePlace: String = ""
    ) {
        self.companyName = companyName
        self.technicianName = technicianName
        self.preparedBy = preparedBy
        self.projectStatus = projectStatus
        self.executionDate = executionDate
        self.handoverRecipient = handoverRecipient
        self.handoverNote = handoverNote
        self.signaturePrintedName = signaturePrintedName
        self.signaturePlace = signaturePlace
    }

    var hasMeaningfulContent: Bool {
        projectStatus != .workInProgress
            || executionDate != nil
            || !companyName.trimmed.isEmpty
            || !technicianName.trimmed.isEmpty
            || !preparedBy.trimmed.isEmpty
            || !handoverRecipient.trimmed.isEmpty
            || !handoverNote.trimmed.isEmpty
            || !signaturePrintedName.trimmed.isEmpty
            || !signaturePlace.trimmed.isEmpty
    }
}

struct HeizBalanceDocumentationSnapshot: Codable, Hashable {
    var companyName: String
    var technicianName: String
    var preparedBy: String
    var projectStatus: String
    var projectStatusTitle: String
    var executionDate: Date?
    var handoverRecipient: String
    var handoverNote: String
    var signaturePrintedName: String
    var signaturePlace: String

    init(metadata: HeizBalanceDocumentationMetadata) {
        companyName = metadata.companyName
        technicianName = metadata.technicianName
        preparedBy = metadata.preparedBy
        projectStatus = metadata.projectStatus.rawValue
        projectStatusTitle = metadata.projectStatus.title
        executionDate = metadata.executionDate
        handoverRecipient = metadata.handoverRecipient
        handoverNote = metadata.handoverNote
        signaturePrintedName = metadata.signaturePrintedName
        signaturePlace = metadata.signaturePlace
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
