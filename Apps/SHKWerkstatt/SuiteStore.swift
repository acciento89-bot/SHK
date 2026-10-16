import SwiftUI
import StoreKit

@MainActor final class SuiteStore: ObservableObject {
    @Published private(set) var hasPro = false
    @Published private(set) var product: Product?
    @Published private(set) var loading = false
    @Published private(set) var busy = false
    @Published var message: String?
    private var observer: Task<Void, Never>?
    private var started = false
    deinit { observer?.cancel() }
    func start() async {
        guard !started else { return }; started = true
        observer = Task { [weak self] in
            for await result in StoreKit.Transaction.updates { await self?.handle(result) }
        }
        await refreshEntitlements(); await loadProduct()
    }
    func loadProduct() async {
        guard !loading else { return }; loading = true; defer { loading = false }
        do { product = try await Product.products(for: [SuiteAccess.proProductID]).first(where: { $0.id == SuiteAccess.proProductID && $0.type == .nonConsumable }) }
        catch { product = nil }
    }
    func refreshEntitlements() async {
        var active = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productType == .nonConsumable,
               SuiteAccess.hasPro(productID: transaction.productID, verified: true, revokedAt: transaction.revocationDate, expiresAt: transaction.expirationDate) { active = true }
        }
        hasPro = active
    }
    func purchase() async {
        guard !busy, let product, product.type == .nonConsumable else { return }
        busy = true; defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let result): await handle(result)
            case .pending: message = S("Der Kauf wartet auf Bestätigung. Pro wird nach der Freigabe automatisch aktiviert.", "The purchase is pending approval. Pro activates automatically after approval.")
            case .userCancelled: break
            @unknown default: message = S("Der Kauf konnte nicht abgeschlossen werden.", "The purchase could not be completed.")
            }
        } catch { message = S("Der Kauf konnte nicht abgeschlossen werden. Bitte versuche es erneut.", "The purchase could not be completed. Please try again.") }
    }
    func restore() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do {
            try await AppStore.sync(); await refreshEntitlements()
            message = hasPro ? S("Pro wurde wiederhergestellt.", "Pro was restored.") : S("Für dieses Apple-Konto wurde kein Pro-Kauf gefunden.", "No Pro purchase was found for this Apple account.")
        } catch { message = S("Käufe konnten nicht wiederhergestellt werden. Bitte prüfe deine Verbindung und versuche es erneut.", "Purchases could not be restored. Check your connection and try again.") }
    }
    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else {
            message = S("Der Kauf konnte nicht sicher geprüft werden. Bitte versuche „Käufe wiederherstellen“.", "The purchase could not be verified. Please try Restore Purchases."); return
        }
        guard transaction.productID == SuiteAccess.proProductID, transaction.productType == .nonConsumable else { return }
        hasPro = SuiteAccess.hasPro(productID: transaction.productID, verified: true, revokedAt: transaction.revocationDate, expiresAt: transaction.expirationDate)
        await transaction.finish()
        await refreshEntitlements()
    }
}
