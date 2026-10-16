import Foundation
import Testing
@testable import SHKCore

@Test func freeProjectLimitNeverDeletesOrLocksExistingProjects() {
    #expect(SuiteAccess.canCreateProject(count: 0, hasPro: false))
    #expect(!SuiteAccess.canCreateProject(count: 1, hasPro: false))
    #expect(!SuiteAccess.canCreateProject(count: 4, hasPro: false))
    #expect(SuiteAccess.canCreateProject(count: 4, hasPro: true))
    #expect(!SuiteAccess.canCreateProject(count: -1, hasPro: true))
}

@Test func onlyVerifiedMatchingNonrevokedProTransactionsGrantAccess() {
    let now = Date(timeIntervalSince1970: 1_792_128_000)
    #expect(SuiteAccess.hasPro(productID: "de.kamilunavo.servicecheck.pro", verified: true, revokedAt: nil, expiresAt: nil, now: now))
    #expect(!SuiteAccess.hasPro(productID: "de.other.product", verified: true, revokedAt: nil, expiresAt: nil, now: now))
    #expect(!SuiteAccess.hasPro(productID: "de.kamilunavo.servicecheck.pro", verified: false, revokedAt: nil, expiresAt: nil, now: now))
    #expect(!SuiteAccess.hasPro(productID: "de.kamilunavo.servicecheck.pro", verified: true, revokedAt: now, expiresAt: nil, now: now))
    #expect(!SuiteAccess.hasPro(productID: "de.kamilunavo.servicecheck.pro", verified: true, revokedAt: nil, expiresAt: now.addingTimeInterval(-1), now: now))
}
