import Foundation

enum HeizBalanceProductDataDistributionScope: String, Codable, CaseIterable, Identifiable, Sendable {
    case localUserImport
    case organizationInternal
    case bundledApplication

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localUserImport:
            "Nur lokaler Benutzerimport"
        case .organizationInternal:
            "Interne Organisationsnutzung"
        case .bundledApplication:
            "Verteilung im App-Bundle"
        }
    }
}

enum HeizBalanceProductDataRightsGate {
    struct Input: Sendable, Equatable {
        var usageBasis: String
        var sourceReference: String
        var rightsNote: String?
        var distributionScope: HeizBalanceProductDataDistributionScope?
        var authorizationReference: String?
    }

    enum Issue: Sendable, Equatable, CustomStringConvertible {
        case missingSourceReference
        case distributionScopeNotDocumented
        case missingRightsNote
        case missingAuthorizationReference
        case usageBasisNotSufficientForOrganization(String)
        case usageBasisNotSufficientForBundling(String)

        var description: String {
            switch self {
            case .missingSourceReference:
                "Quellenreferenz fehlt"
            case .distributionScopeNotDocumented:
                "Distributionsumfang ist nicht dokumentiert; Datensatz bleibt nur lokal nutzbar"
            case .missingRightsNote:
                "Rechtehinweis für den beanspruchten Distributionsumfang fehlt"
            case .missingAuthorizationReference:
                "Konkrete Autorisierungs-/Lizenzreferenz für den beanspruchten Distributionsumfang fehlt"
            case .usageBasisNotSufficientForOrganization(let basis):
                "Nutzungsgrundlage erlaubt keine bestätigte Organisationsverteilung: \(basis)"
            case .usageBasisNotSufficientForBundling(let basis):
                "Nutzungsgrundlage erlaubt keine bestätigte App-Bundle-Verteilung: \(basis)"
            }
        }
    }

    struct Assessment: Sendable, Equatable {
        var declaredScope: HeizBalanceProductDataDistributionScope?
        var effectiveScope: HeizBalanceProductDataDistributionScope
        var issues: [Issue]

        var canImportLocally: Bool {
            !issues.contains(.missingSourceReference)
        }

        var canUseOrganizationInternally: Bool {
            canImportLocally
                && issues.isEmpty
                && (effectiveScope == .organizationInternal || effectiveScope == .bundledApplication)
        }

        var canBundleInApplication: Bool {
            canImportLocally
                && issues.isEmpty
                && effectiveScope == .bundledApplication
        }
    }

    static func assess(_ input: Input) -> Assessment {
        let usageBasis = input.usageBasis.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceReference = input.sourceReference.trimmingCharacters(in: .whitespacesAndNewlines)
        let rightsNote = input.rightsNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let authorizationReference = input.authorizationReference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var issues: [Issue] = []
        if sourceReference.isEmpty {
            issues.append(.missingSourceReference)
        }

        guard let declaredScope = input.distributionScope else {
            issues.append(.distributionScopeNotDocumented)
            return Assessment(
                declaredScope: nil,
                effectiveScope: .localUserImport,
                issues: issues
            )
        }

        switch declaredScope {
        case .localUserImport:
            return Assessment(
                declaredScope: declaredScope,
                effectiveScope: .localUserImport,
                issues: issues
            )

        case .organizationInternal:
            if rightsNote.isEmpty { issues.append(.missingRightsNote) }
            if authorizationReference.isEmpty { issues.append(.missingAuthorizationReference) }
            if !organizationUsageBases.contains(usageBasis) {
                issues.append(.usageBasisNotSufficientForOrganization(usageBasis))
            }
            return Assessment(
                declaredScope: declaredScope,
                effectiveScope: issues.isEmpty ? .organizationInternal : .localUserImport,
                issues: issues
            )

        case .bundledApplication:
            if rightsNote.isEmpty { issues.append(.missingRightsNote) }
            if authorizationReference.isEmpty { issues.append(.missingAuthorizationReference) }
            if !bundlingUsageBases.contains(usageBasis) {
                issues.append(.usageBasisNotSufficientForBundling(usageBasis))
            }
            return Assessment(
                declaredScope: declaredScope,
                effectiveScope: issues.isEmpty ? .bundledApplication : .localUserImport,
                issues: issues
            )
        }
    }

    private static let organizationUsageBases: Set<String> = [
        "manufacturerAuthorized",
        "licensed",
        "otherDocumented"
    ]

    private static let bundlingUsageBases: Set<String> = [
        "manufacturerAuthorized",
        "licensed"
    ]
}
