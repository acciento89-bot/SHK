import XCTest
import StoreKit
import StoreKitTest
@testable import SHKWerkstatt

final class SuiteCommerceTests: XCTestCase {
    @MainActor private func session() throws -> SKTestSession {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "SHKWerkstatt", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState(); session.clearTransactions(); session.disableDialogs = true
        return session
    }
    @MainActor private func waitForAccess(_ expected: Bool, store: SuiteStore) async throws {
        for _ in 0..<40 {
            await store.refreshEntitlements()
            if store.hasPro == expected { return }
            try await Task.sleep(for: .milliseconds(150))
        }
        XCTAssertEqual(store.hasPro, expected)
    }
    @MainActor func testRealStoreKitPurchaseRelaunchRestoreAndRefund() async throws {
        let session = try session(); defer { session.clearTransactions() }
        let store = SuiteStore(); await store.start()
        XCTAssertFalse(store.hasPro)
        let product = try XCTUnwrap(store.product)
        XCTAssertEqual(product.id, "de.kamilunavo.servicecheck.pro")
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertFalse(product.displayPrice.isEmpty)
        await store.purchase()
        try await waitForAccess(true, store: store)
        let reopenedStore = SuiteStore(); await reopenedStore.start()
        XCTAssertTrue(reopenedStore.hasPro, "Verified purchase must survive a new store instance")
        await reopenedStore.restore()
        XCTAssertTrue(reopenedStore.hasPro)
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == product.id })
        try session.refundTransaction(identifier: transaction.identifier)
        try await waitForAccess(false, store: reopenedStore)
        XCTAssertTrue(SuiteAccess.canCreateProject(count: 0, hasPro: reopenedStore.hasPro))
        XCTAssertFalse(SuiteAccess.canCreateProject(count: 1, hasPro: reopenedStore.hasPro))
    }
    @MainActor func testPendingAskToBuyDoesNotUnlockUntilApproval() async throws {
        let session = try session(); defer { session.clearTransactions() }
        session.askToBuyEnabled = true
        let store = SuiteStore(); await store.start()
        XCTAssertNotNil(store.product)
        await store.purchase()
        XCTAssertFalse(store.hasPro)
        XCTAssertNotNil(store.message)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.approveAskToBuyTransaction(identifier: transaction.identifier)
        try await waitForAccess(true, store: store)
    }
    @MainActor func testUnrelatedVerifiedPurchaseCannotUnlockPro() async throws {
        let session = try session(); defer { session.clearTransactions() }
        _ = try await session.buyProduct(identifier: "de.kamilunavo.tests.unrelated")
        let store = SuiteStore(); await store.start()
        XCTAssertFalse(store.hasPro)
    }
}
