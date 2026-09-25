import Foundation
import WatchConnectivity
import WatchKit
import WidgetKit
import Combine

/// Saat tarafı: iPhone'dan gelen durumu tutar, uyarı mesajında bileği titretir,
/// istenirse uzatılmış çalışma oturumuyla bir saate kadar uyanık kalır.
@MainActor
final class WatchModel: NSObject, ObservableObject {
    @Published private(set) var state: WatchPayload.State = WatchPayload.loadStored()
    @Published private(set) var phoneReachable = false
    @Published private(set) var sessionActive = false

    private var runtime: WKExtendedRuntimeSession?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Oturum

    func toggleSession() {
        if sessionActive { endSession() } else { startSession() }
    }

    private func startSession() {
        // "mindfulness" türü: 1 saate kadar arka planda çalışır, haptik izinli. HealthKit gerekmez.
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start()
        runtime = s
        sessionActive = true
    }

    private func endSession() {
        runtime?.invalidate()
        runtime = nil
        sessionActive = false
    }

    // MARK: - Uyarı

    private func nudge(level: Int) {
        let dev = WKInterfaceDevice.current()
        dev.play(level >= 2 ? .failure : .notification)
        if level >= 3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { dev.play(.failure) }
        }
    }

    private func apply(_ dict: [String: Any]) {
        guard let s = WatchPayload.State(dictionary: dict) else { return }
        state = s
        WatchPayload.store(s)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension WatchModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let ctx = session.receivedApplicationContext
        Task { @MainActor in
            self.phoneReachable = session.isReachable
            if !ctx.isEmpty { self.apply(ctx) }
        }
    }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let r = session.isReachable
        Task { @MainActor in self.phoneReachable = r }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext ctx: [String: Any]) {
        Task { @MainActor in self.apply(ctx) }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.apply(userInfo) }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let level = message[WatchPayload.nudgeKey] as? Int {
            Task { @MainActor in self.nudge(level: level) }
        }
    }
}

extension WatchModel: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(_ s: WKExtendedRuntimeSession) {}
    nonisolated func extendedRuntimeSessionWillExpire(_ s: WKExtendedRuntimeSession) {}
    nonisolated func extendedRuntimeSession(_ s: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        Task { @MainActor in self.sessionActive = false; self.runtime = nil }
    }
}
