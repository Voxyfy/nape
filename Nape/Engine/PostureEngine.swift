import Foundation
import Combine

/// Duruş motoru: ham açıyı alır, eşik + süre mantığını işletir, günlük sayıları biriktirir, uyarı tetikler.
@MainActor
final class PostureEngine: ObservableObject {
    enum State: Equatable {
        case idle           // takip kapalı
        case disconnected   // takip açık ama sensörlü kulaklık yok
        case upright
        case leaning(seconds: Double) // eşik üstünde, kaç saniyedir
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var tiltDegrees: Double = 0
    @Published private(set) var today: DailyStats
    @Published private(set) var isTracking = false
    /// Ücretsiz katman günlük sınırına ulaştı (deneme bitmiş, Pro yok).
    @Published private(set) var dailyLimitReached = false
    /// Dışarıdan verilir: Pro/deneme açık mı. Kapalıysa günlük takip sınırı uygulanır.
    var isUnlocked: () -> Bool = { true }

    private let motion: HeadMotionService
    private let settings: AppSettings
    private let store = DayStore()
    private let alerter = Alerter()
    private let keepAlive = BackgroundKeepAlive()
    private let liveActivity = LiveActivityController()
    private let notifier = NudgeNotifier()
    private let watch = WatchBridge.shared
    private var bag = Set<AnyCancellable>()

    private var lastSampleAt: Date?
    private var leaningSince: Date?
    private var lastAlertAt: Date?
    /// Bu eğik kalış içinde kaç uyarı verildi; dikleşince sıfırlanır.
    private var episodeNudges = 0
    private var lastSaveAt = Date()

    init(motion: HeadMotionService, settings: AppSettings) {
        self.motion = motion
        self.settings = settings
        self.today = store.load(day: DailyStats.key())
        notifier.refreshStatus()
        #if targetEnvironment(simulator)
        // `-simSeed`: grafikleri dolu görmek için bugüne ve son 6 güne sahte veri basar.
        if CommandLine.arguments.contains("-simSeed") {
            var rng = SystemRandomNumberGenerator()
            for back in 0..<7 {
                let date = Calendar.current.date(byAdding: .day, value: -back, to: Date())!
                var d = DailyStats(day: DailyStats.key(for: date))
                let hours = back == 0 ? Calendar.current.component(.hour, from: Date()) : 23
                for h in 8...max(8, hours) { d.hourlyTiltedSeconds[h] = Double.random(in: 0...1500, using: &rng) * (h % 3 == 0 ? 0.3 : 1) }
                d.tiltedSeconds = d.hourlyTiltedSeconds.reduce(0, +)
                d.trackedSeconds = d.tiltedSeconds * 2.6
                d.loadKgMinutes = d.trackedSeconds / 60 * 9 + d.tiltedSeconds / 60 * 10
                d.leaningLoadKgMinutes = d.tiltedSeconds / 60 * Double.random(in: 15...20, using: &rng)
                d.alertCount = Int(d.tiltedSeconds / 400)
                d.maxTiltDegrees = Double.random(in: 35...52, using: &rng)
                store.save(d)
            }
            self.today = store.load(day: DailyStats.key())
        }
        #endif

        // Her ham örnekte motoru bir adım ilerlet.
        motion.$rawPitch
            .sink { [weak self] pitch in self?.tick(rawPitch: pitch) }
            .store(in: &bag)

        motion.$isConnected
            .sink { [weak self] connected in
                guard let self, self.isTracking else { return }
                if !connected { self.state = .disconnected; self.lastSampleAt = nil; self.leaningSince = nil }
                self.liveActivity.update(self.activityState())
            }
            .store(in: &bag)
    }

    // MARK: - Kontrol

    func startTracking() {
        guard !isTracking else { return }
        if !isUnlocked() && today.trackedSeconds >= ProStore.freeDailyTrackingSeconds { dailyLimitReached = true; return }
        dailyLimitReached = false
        isTracking = true
        state = motion.isConnected ? .upright : .disconnected
        motion.start()
        if settings.backgroundTracking { keepAlive.start() }
        liveActivity.start(state: activityState())
        watch.push(watchState())
    }

    func stopTracking() {
        isTracking = false
        motion.stop()
        keepAlive.stop()
        liveActivity.end()
        state = .idle
        watch.push(watchState())
        leaningSince = nil
        lastSampleAt = nil
        persist(force: true)
    }

    /// Şu anki kafa pozisyonunu "düz" kabul et.
    func calibrate() {
        settings.calibrationOffset = motion.rawPitch
        leaningSince = nil
    }

    // MARK: - Motor adımı

    /// `$rawPitch` Combine'da willSet anında yayınlanır; o an `motion.rawPitch` hâlâ eski değerdir,
    /// bu yüzden örnek parametreyle gelir.
    private func tick(rawPitch: Double) {
        guard isTracking, motion.isConnected else { return }
        let now = Date()
        rolloverIfNeeded(now)

        let tilt = HeadMotionService.forwardTiltDegrees(rawPitch: rawPitch, offset: settings.calibrationOffset)
        tiltDegrees = tilt

        // İlk örnekte dt yok, sadece zamanı kaydet.
        guard let last = lastSampleAt else { lastSampleAt = now; return }
        let dt = min(now.timeIntervalSince(last), 1.0) // uyku/duraklama sonrası dev sıçramayı kes
        lastSampleAt = now

        today.trackedSeconds += dt
        if !isUnlocked() && today.trackedSeconds >= ProStore.freeDailyTrackingSeconds {
            // Yumuşak kilit: bugünlük bu kadar. Kullanıcı Pro alırsa hemen sürer.
            dailyLimitReached = true
            stopTracking()
            return
        }
        today.maxTiltDegrees = max(today.maxTiltDegrees, tilt)
        let loadKg = NeckLoad.kilograms(forTilt: tilt, headMassKg: settings.headMassKg)
        today.loadKgMinutes += loadKg * dt / 60

        if tilt >= settings.thresholdDegrees {
            today.tiltedSeconds += dt
            today.leaningLoadKgMinutes += loadKg * dt / 60
            today.hourlyTiltedSeconds[Calendar.current.component(.hour, from: now)] += dt
            if leaningSince == nil { leaningSince = now }
            let leanSec = now.timeIntervalSince(leaningSince!)
            state = .leaning(seconds: leanSec)
            maybeAlert(now: now, leanSec: leanSec)
        } else {
            leaningSince = nil
            lastAlertAt = nil
            if episodeNudges > 0 { notifier.clear() }
            episodeNudges = 0
            state = .upright
        }

        persist(force: false)
        liveActivity.update(activityState())
        watch.push(watchState())
    }

    private func watchState() -> WatchPayload.State {
        .init(tilt: Int(max(0, min(60, tiltDegrees)).rounded()),
              leaning: { if case .leaning = state { return true } else { return false } }(),
              connected: motion.isConnected,
              tracking: isTracking,
              avgLoadKg: Int(today.averageLeaningLoadKg.rounded()),
              leaningMinutes: Int(today.tiltedSeconds / 60),
              updatedAt: Date())
    }

    /// Bildirim izni: kullanıcı ayardan açınca ya da ilk takipte istenir.
    func requestNotificationPermission() { notifier.requestAuthorization() }

    private func activityState() -> NapeActivityAttributes.ContentState {
        var leaningSec = 0
        if case .leaning(let s) = state { leaningSec = Int(s) }
        return .init(tilt: Int(max(0, min(60, tiltDegrees)).rounded()),
                     leaning: leaningSec > 0,
                     leaningSeconds: leaningSec,
                     connected: motion.isConnected,
                     leaningMinutes: Int(today.tiltedSeconds / 60),
                     avgLoadKg: Int(today.averageLeaningLoadKg.rounded()),
                     liveLoadKg: Int(NeckLoad.kilograms(forTilt: max(0, tiltDegrees), headMassKg: settings.headMassKg).rounded()))
    }

    private func maybeAlert(now: Date, leanSec: Double) {
        guard leanSec >= settings.dwellSeconds else { return }
        if let last = lastAlertAt, now.timeIntervalSince(last) < settings.repeatSeconds { return }
        lastAlertAt = now
        today.alertCount += 1
        episodeNudges += 1
        let level = settings.escalates ? episodeNudges : 1
        alerter.nudge(haptic: settings.hapticEnabled, sound: settings.soundEnabled, which: settings.nudgeSound, level: level)
        watch.nudge(level: level)
        if settings.notificationsEnabled { notifier.post(level: level, tilt: Int(tiltDegrees.rounded())) }
    }

    /// Gece yarısı geçtiyse yeni güne geç.
    private func rolloverIfNeeded(_ now: Date) {
        let key = DailyStats.key(for: now)
        if key != today.day {
            store.save(today)
            today = DailyStats(day: key)
        }
    }

    private func persist(force: Bool) {
        let now = Date()
        if force || now.timeIntervalSince(lastSaveAt) >= 10 {
            store.save(today)
            lastSaveAt = now
        }
    }

    func recentDays(_ n: Int) -> [DailyStats] { store.recent(days: n) }

    /// Ayarlar ekranından ses önizlemesi.
    func previewSound(_ s: NudgeSound) { alerter.play(s) }
}
