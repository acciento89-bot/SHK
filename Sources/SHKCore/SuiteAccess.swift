import Foundation

public enum SuiteAccess {
    public static let proProductID = "de.kamilunavo.servicecheck.pro"
    public static func canCreateProject(count: Int, hasPro: Bool) -> Bool {
        count >= 0 && (hasPro || count == 0)
    }
    public static func hasPro(productID: String, verified: Bool, revokedAt: Date?, expiresAt: Date?, now: Date = Date()) -> Bool {
        productID == proProductID && verified && revokedAt == nil && (expiresAt.map { $0 > now } ?? true)
    }
}
