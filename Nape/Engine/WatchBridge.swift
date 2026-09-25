import Foundation
import WatchConnectivity

/// iPhone → Apple Watch köprüsü.
/// - Durum: `updateApplicationContext` (en son değer, saat uyanınca okur), kısılmış.
/// - Komplikasyon: `transferCurrentComplicationUserInfo` (günde ~50 bütçe), yalnız yük değişince ve 15 dk'da bir.
/// - Uyarı: saat uygulaması erişilebilirse `sendMessage` ile anında bilek titreşimi.
final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()

    private var lastContext: WatchPayload.State?
    private var lastContextAt = Date.distantPast
    private var lastComplicationAt = Date.distantPast
    private var lastComplicationMinutes = -1

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func activate() { _ = WatchBridge.shared }

    var isPaired: Bool { WCSession.isSupported() && WCSession.default.isPaired && WCSession.default.isWatchAppInstalled }

    // MARK: - Gönderim

    func push(_ state: WatchPayload.State) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated, WCSession.default.isPaired else { return }
        let now = Date()
        let changed = lastContext.map { $0.leaning != state.leaning || $0.connected != state.connected || $0.tracking != state.tracking || abs($0.tilt - state.tilt) >= 5 } ?? true
        if changed || now.timeIntervalSince(lastContextAt) >= 10 {
            try? WCSession.default.updateApplicationContext(state.dictionary)
            lastContext = state
            lastContextAt = now
        }
        // Komplikasyon: 15 dk'da bir ya da takip açılıp kapanınca
        let trackingFlip = lastContext.map { $0.tracking != state.tracking } ?? true
        if WCSession.default.isComplicationEnabled,
           (trackingFlip || now.timeIntervalSince(lastComplicationAt) >= 900) && state.leaningMinutes != lastComplicationMinutes {
            WCSession.default.transferCurrentComplicationUserInfo(state.dictionary)
            lastComplicationAt = now
            lastComplicationMinutes = state.leaningMinutes
        }
    }

    func nudge(level: Int) {
        guard WCSession.isSupported(), WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([WatchPayload.nudgeKey: level], replyHandler: nil, errorHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
