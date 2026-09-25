import Foundation
import AVFoundation
import UIKit

/// iOS, ses çalmayan uygulamayı arka planda askıya alır ve kulaklık verisi kesilir.
/// Çözüm: `audio` arka plan modu + neredeyse sessiz bir döngü. Posture Pal aynı yöntemi kullanır.
/// `.mixWithOthers` sayesinde kullanıcının müziği/aramaları kesilmez.
///
/// Kesinti yönetimi: telefon araması, Siri veya sesi tamamen alan başka bir uygulama döngüyü durdurur.
/// Kesinti bitince ve medya servisleri sıfırlanınca döngü kendiliğinden sürer; ayrıca 20 sn'lik bir
/// bekçi, çalar durmuşsa yeniden başlatır.
final class BackgroundKeepAlive {
    private var player: AVAudioPlayer?
    private var active = false
    private var observers: [NSObjectProtocol] = []
    private var watchdog: Timer?

    func start() {
        active = true
        activateSession()
        startPlayer()
        installObservers()
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            guard let self, self.active, self.player?.isPlaying != true else { return }
            self.activateSession()
            self.startPlayer()
        }
    }

    func stop() {
        active = false
        watchdog?.invalidate(); watchdog = nil
        player?.stop()
        player = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - İç

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func startPlayer() {
        if player == nil, let url = Bundle.main.url(forResource: "silence", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.01
        }
        if player?.isPlaying != true { player?.play() }
    }

    private func installObservers() {
        guard observers.isEmpty else { return }
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            guard let self, self.active,
                  let raw = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            if type == .ended {
                // shouldResume bayrağı gelmese de biz sürdürürüz: kullanıcı takibi kapatmadı.
                self.activateSession()
                self.startPlayer()
            }
        })
        observers.append(nc.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.active else { return }
            self.player = nil
            self.activateSession()
            self.startPlayer()
        })
        observers.append(nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.active, self.player?.isPlaying != true else { return }
            self.activateSession()
            self.startPlayer()
        })
    }
}
