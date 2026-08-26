import XCTest
@testable import SHKCore

final class HeizBalanceHydraulicNetworkTreeEditingTests: XCTestCase {
    func testSubtreeContainsOnlyRootAndDescendantsInStableOrder() throws {
        let segments = fixture()
        let subtree = try XCTUnwrap(
            HeizBalanceHydraulicNetworkTreeEditing.subtreeIDs(
                rootID: "floor-a",
                segments: segments
            )
        )

        XCTAssertEqual(subtree, ["floor-a", "branch-a1", "branch-a2"])
    }

    func testMoveRejectsSelfAndDescendantParents() {
        let segments = fixture()

        XCTAssertFalse(
            HeizBalanceHydraulicNetworkTreeEditing.canMove(
                rootID: "floor-a",
                toParentID: "floor-a",
                segments: segments
            )
        )
        XCTAssertFalse(
            HeizBalanceHydraulicNetworkTreeEditing.canMove(
                rootID: "floor-a",
                toParentID: "branch-a1",
                segments: segments
            )
        )
    }

    func testMoveAllowsRootSiblingAndOtherBranchParents() {
        let segments = fixture()

        XCTAssertTrue(
            HeizBalanceHydraulicNetworkTreeEditing.canMove(
                rootID: "floor-a",
                toParentID: nil,
                segments: segments
            )
        )
        XCTAssertTrue(
            HeizBalanceHydraulicNetworkTreeEditing.canMove(
                rootID: "branch-a1",
                toParentID: "floor-b",
                segments: segments
            )
        )
    }

    func testValidParentsExcludeEntireOwnSubtree() throws {
        let parents = try XCTUnwrap(
            HeizBalanceHydraulicNetworkTreeEditing.validParentIDs(
                rootID: "floor-a",
                segments: fixture()
            )
        )

        XCTAssertEqual(parents, ["branch-b1", "floor-b", "root"])
        XCTAssertFalse(parents.contains("floor-a"))
        XCTAssertFalse(parents.contains("branch-a1"))
        XCTAssertFalse(parents.contains("branch-a2"))
    }

    func testInvalidTreesAreRejectedBeforeEditing() {
        let cycle = [
            HeizBalanceHydraulicNetworkTreeEditing.Segment(id: "a", parentSegmentID: "b"),
            HeizBalanceHydraulicNetworkTreeEditing.Segment(id: "b", parentSegmentID: "a")
        ]
        let missingParent = [
            HeizBalanceHydraulicNetworkTreeEditing.Segment(id: "a", parentSegmentID: "missing")
        ]

        XCTAssertNil(HeizBalanceHydraulicNetworkTreeEditing.subtreeIDs(rootID: "a", segments: cycle))
        XCTAssertNil(HeizBalanceHydraulicNetworkTreeEditing.subtreeIDs(rootID: "a", segments: missingParent))
        XCTAssertFalse(
            HeizBalanceHydraulicNetworkTreeEditing.canMove(
                rootID: "a",
                toParentID: nil,
                segments: cycle
            )
        )
    }

    private func fixture() -> [HeizBalanceHydraulicNetworkTreeEditing.Segment] {
        [
            .init(id: "root", parentSegmentID: nil),
            .init(id: "floor-a", parentSegmentID: "root"),
            .init(id: "branch-a2", parentSegmentID: "floor-a"),
            .init(id: "branch-a1", parentSegmentID: "floor-a"),
            .init(id: "floor-b", parentSegmentID: "root"),
            .init(id: "branch-b1", parentSegmentID: "floor-b")
        ]
    }
}
