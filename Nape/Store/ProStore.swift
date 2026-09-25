import Foundation
import StoreKit
import Combine

/// Nape Pro: tek seferlik satın alma + 7 günlük tam deneme.
/// - Deneme başlangıcı Keychain'de; sil-yükle sıfırlamaz.
/// - Yetki StoreKit 2 `Transaction.currentEntitlements` ile her açılışta doğrulanır; iade olursa düşer.
/// - Deneme bitince yumuşak kilit: takip günde 1 saat, Pro özellikler kapalı. Uygulama "bozulmaz".
@MainActor
final class ProStore: ObservableObject {
    static let productID = "com.batuhanhaymana.nape.pro"
    static let trialDays = 7
    /// Deneme bittikten sonra ücretsiz günlük takip süresi (sn).
    static let freeDailyTrackingSeconds: Double = 3600

    @Published private(set) var isPro = false
    @Published private(set) var product: Product?
    @Published private(set) var trialStartedAt: Date
    @Published private(set) var purchaseInFlight = false
    @Published var lastError: String?

    private var updates: Task<Void, Never>?

    init() {
        // İlk açılış = deneme başlangıcı
        if let s = Keychain.get("trialStart"), let t = TimeInterval(s) {
            trialStartedAt = Date(timeIntervalSince1970: t)
        } else {
            let now = Date()
            Keychain.set(String(now.timeIntervalSince1970), for: "trialStart")
            trialStartedAt = now
        }
        #if targetEnvironment(simulator)
        // `-simTrialExpired`: deneme bitmiş hali; `-simPro`: satın alınmış hali
        if CommandLine.arguments.contains("-simTrialExpired") { trialStartedAt = Date().addingTimeInterval(-9 * 86400) }
        if CommandLine.arguments.contains("-simPro") { isPro = true }
        #endif
        updates = Task { await listenForTransactions() }
        Task { await refresh() }
    }

    deinit { updates?.cancel() }

    // MARK: - Durum

    var trialDaysLeft: Int {
        let end = trialStartedAt.addingTimeInterval(Double(Self.trialDays) * 86400)
        return max(0, Int(ceil(end.timeIntervalSince(Date()) / 86400)))
    }
    var isTrialActive: Bool { trialDaysLeft > 0 }
    /// Pro ya da deneme sürüyor → her şey açık.
    var isUnlocked: Bool { isPro || isTrialActive }

    // MARK: - StoreKit

    func refresh() async {
        await loadProduct()
        await checkEntitlement()
    }

    private func loadProduct() async {
        do { product = try await Product.products(for: [Self.productID]).first }
        catch { lastError = error.localizedDescription }
    }

    private func checkEntitlement() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil { pro = true }
        }
        #if targetEnvironment(simulator)
        if CommandLine.arguments.contains("-simPro") { pro = true }
        #endif
        isPro = pro
    }

    func purchase() async {
        guard let product, !purchaseInFlight else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    isPro = true
                }
            case .userCancelled, .pending: break
            @unknown default: break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        do { try await AppStore.sync() } catch { lastError = error.localizedDescription }
        await checkEntitlement()
    }

    /// Arka planda gelen işlemler (başka cihazdan satın alma, iade)
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let t) = result {
                await t.finish()
                await checkEntitlement()
            }
        }
    }
}
