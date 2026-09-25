import Foundation
import ActivityKit

/// Dynamic Island / kilit ekranı canlı etkinliği. Motor takibi başlatınca açılır, durdurunca kapanır.
/// Güncellemeler kısılır: açı 3°'den az değiştiyse ve durum aynıysa gönderilmez; eğikken saniye sayacı
/// 5 sn'de bir yenilenir. Sistem bütçesi böylece tükenmez.
@MainActor
final class LiveActivityController {
    private var activity: Activity<NapeActivityAttributes>?
    private var lastSent: NapeActivityAttributes.ContentState?
    private var lastSentAt = Date.distantPast

    func start(state: NapeActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, activity == nil else { return }
        let attrs = NapeActivityAttributes(startedAt: Date())
        activity = try? Activity.request(attributes: attrs, content: .init(state: state, staleDate: nil))
        lastSent = state
        lastSentAt = Date()
    }

    func update(_ state: NapeActivityAttributes.ContentState) {
        guard let activity else { return }
        let now = Date()
        if let last = lastSent {
            let angleMoved = abs(last.tilt - state.tilt) >= 3
            let stateChanged = last.leaning != state.leaning || last.connected != state.connected
            let tick = state.leaning && now.timeIntervalSince(lastSentAt) >= 5
            guard angleMoved || stateChanged || tick else { return }
        }
        lastSent = state
        lastSentAt = now
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    func end() {
        guard let activity else { return }
        let final = lastSent ?? .init(tilt: 0, leaning: false, leaningSeconds: 0, connected: false, leaningMinutes: 0, avgLoadKg: 0, liveLoadKg: 0)
        Task { await activity.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate) }
        self.activity = nil
        lastSent = nil
    }
}
