import Testing
@testable import SHKCore

@Test func heizBalanceTechnicalPreviewProfileCannotClaimNormativeOutput() {
    let profile = HeizBalanceCalculationProfile.technicalPreviewV1

    #expect(profile.engineID == .technicalPreviewV1)
    #expect(profile.validationState == .developmentOnly)
    #expect(profile.normativeOutputAllowed == false)
}

@Test func heizBalanceGermanNormProfileIsReservedAndBlockedUntilValidation() {
    let profile = HeizBalanceCalculationProfile.germanRoomHeatLoad2017_2020

    #expect(profile.engineID == .deRoomHeatLoad2017_2020)
    #expect(profile.validationState == .developmentOnly)
    #expect(profile.normativeOutputAllowed == false)
    #expect(profile.sourceEditions.contains(.init(document: "DIN EN 12831-1", edition: "2017-09")))
    #expect(profile.sourceEditions.contains(.init(document: "DIN/TS 12831-1", edition: "2020-04")))
}
