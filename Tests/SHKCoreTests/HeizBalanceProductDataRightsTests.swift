import XCTest
@testable import SHKCore

final class HeizBalanceProductDataRightsTests: XCTestCase {
    func testLegacyUndocumentedScopeFallsBackToLocalOnly() {
        let result = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "manufacturerAuthorized",
                sourceReference: "Herstellerportal 2026-08",
                rightsNote: "Technische Produktdaten",
                distributionScope: nil,
                authorizationReference: nil
            )
        )

        XCTAssertTrue(result.canImportLocally)
        XCTAssertFalse(result.canUseOrganizationInternally)
        XCTAssertFalse(result.canBundleInApplication)
        XCTAssertEqual(result.effectiveScope, .localUserImport)
        XCTAssertTrue(result.issues.contains(.distributionScopeNotDocumented))
    }

    func testUserProvidedDatasetCanStayLocalButCannotClaimBundling() {
        let result = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "userProvided",
                sourceReference: "Lokaler Import",
                rightsNote: "Vom Nutzer bereitgestellt",
                distributionScope: .bundledApplication,
                authorizationReference: "user-upload"
            )
        )

        XCTAssertTrue(result.canImportLocally)
        XCTAssertFalse(result.canBundleInApplication)
        XCTAssertEqual(result.effectiveScope, .localUserImport)
        XCTAssertTrue(
            result.issues.contains(.usageBasisNotSufficientForBundling("userProvided"))
        )
    }

    func testManufacturerAuthorizationCanPermitAppBundlingWhenFullyDocumented() {
        let result = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "manufacturerAuthorized",
                sourceReference: "Hersteller-Datensatz 2026-08",
                rightsNote: "Herstellerfreigabe umfasst Einbettung und Weitergabe in HeizBalance.",
                distributionScope: .bundledApplication,
                authorizationReference: "Freigabe ABC-2026-0815"
            )
        )

        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertTrue(result.canImportLocally)
        XCTAssertTrue(result.canUseOrganizationInternally)
        XCTAssertTrue(result.canBundleInApplication)
        XCTAssertEqual(result.effectiveScope, .bundledApplication)
    }

    func testLicensedBundlingRequiresConcreteAuthorizationReferenceAndRightsNote() {
        let result = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "licensed",
                sourceReference: "Lizenzierter Datenexport",
                rightsNote: nil,
                distributionScope: .bundledApplication,
                authorizationReference: nil
            )
        )

        XCTAssertTrue(result.canImportLocally)
        XCTAssertFalse(result.canBundleInApplication)
        XCTAssertTrue(result.issues.contains(.missingRightsNote))
        XCTAssertTrue(result.issues.contains(.missingAuthorizationReference))
        XCTAssertEqual(result.effectiveScope, .localUserImport)
    }

    func testOtherDocumentedBasisMayBeOrganizationInternalButNotBundled() {
        let internalResult = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "otherDocumented",
                sourceReference: "Vertragliche Datenbereitstellung",
                rightsNote: "Interne Nutzung im Betrieb dokumentiert.",
                distributionScope: .organizationInternal,
                authorizationReference: "Vertrag INTERN-42"
            )
        )
        XCTAssertTrue(internalResult.issues.isEmpty)
        XCTAssertTrue(internalResult.canUseOrganizationInternally)
        XCTAssertFalse(internalResult.canBundleInApplication)

        let bundledResult = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "otherDocumented",
                sourceReference: "Vertragliche Datenbereitstellung",
                rightsNote: "Interne Nutzung im Betrieb dokumentiert.",
                distributionScope: .bundledApplication,
                authorizationReference: "Vertrag INTERN-42"
            )
        )
        XCTAssertFalse(bundledResult.canBundleInApplication)
        XCTAssertTrue(
            bundledResult.issues.contains(.usageBasisNotSufficientForBundling("otherDocumented"))
        )
    }

    func testMissingSourceReferenceBlocksEvenLocalImportReadiness() {
        let result = HeizBalanceProductDataRightsGate.assess(
            .init(
                usageBasis: "licensed",
                sourceReference: "   ",
                rightsNote: nil,
                distributionScope: .localUserImport,
                authorizationReference: nil
            )
        )

        XCTAssertFalse(result.canImportLocally)
        XCTAssertTrue(result.issues.contains(.missingSourceReference))
    }
}
