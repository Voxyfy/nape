import Foundation
import CoreMotion
import Combine

/// AirPods'tan kafa yönelimini okur. Tek sorumluluğu ham veriyi yayınlamak;
/// eşik, süre ve uyarı mantığı PostureEngine'de.
///
/// Desteklenen cihazlar: AirPods Pro (tüm nesiller), AirPods 3/4, AirPods Max, Beats Fit Pro.
/// AirPods 1/2'de hareket sensörü yok, `isAvailable` false döner.
@MainActor
final class HeadMotionService: NSObject, ObservableObject {
    /// Ham pitch, radyan. Kalibrasyon uygulanmamış.
    @Published private(set) var rawPitch: Double = 0
    /// Sensörlü kulaklık şu an takılı ve veri akıyor mu.
    @Published private(set) var isConnected = false
    /// Cihaz/işletim sistemi bu API'yi destekliyor mu.
    @Published private(set) var isAvailable = false
    @Published private(set) var isRunning = false
    @Published private(set) var authorization: CMAuthorizationStatus = .notDetermined
    @Published private(set) var lastSampleAt: Date?

    private let manager = CMHeadphoneMotionManager()
    #if targetEnvironment(simulator)
    /// Simülatörde AirPods yok; tasarım üstünde çalışabilmek için sahte bir kafa hareketi üretilir.
    private var simTimer: Timer?
    private var simStart = Date()
    #endif

    override init() {
        super.init()
        manager.delegate = self
        #if targetEnvironment(simulator)
        isAvailable = true
        #else
        isAvailable = manager.isDeviceMotionAvailable
        #endif
        authorization = CMHeadphoneMotionManager.authorizationStatus()
    }

    func start() {
        guard isAvailable, !isRunning else { return }
        isRunning = true
        #if targetEnvironment(simulator)
        // `-simDisconnected` argümanıyla "kulaklık yok" hali görülebilir.
        if CommandLine.arguments.contains("-simDisconnected") { isConnected = false; return }
        // 120 sn'lik döngü: düz otur → 40°'ye eğil (~34 sn eşik üstü, uyarı tetiklenir) → geri gel.
        // Ham değer mevcut kalibrasyon sıfırına göre üretilir; kullanıcı ne zaman kalibre ederse etsin gösterge döngüyü aynen gösterir.
        isConnected = true
        simStart = Date()
        simTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            let elapsed = Date().timeIntervalSince(self.simStart)
            let phase = (elapsed.truncatingRemainder(dividingBy: 120)) / 120
            let deg = max(0, sin(phase * .pi * 2) * 40) + Double.random(in: -0.6...0.6)
            let offset = UserDefaults.standard.double(forKey: "calibrationOffset")
            self.rawPitch = offset - deg * .pi / 180 // öne eğim ham veride negatif
            self.lastSampleAt = Date()
        }
        return
        #endif
        // Örnekler ~25-50 Hz gelir; UI ve motor ana kuyrukta çalıştığı için doğrudan ana kuyruğa alıyoruz.
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }
            self.authorization = CMHeadphoneMotionManager.authorizationStatus()
            if error != nil { return }
            guard let motion else { return }
            self.rawPitch = motion.attitude.pitch
            self.lastSampleAt = Date()
            if !self.isConnected { self.isConnected = true }
        }
    }

    func stop() {
        #if targetEnvironment(simulator)
        simTimer?.invalidate(); simTimer = nil
        #endif
        manager.stopDeviceMotionUpdates()
        isRunning = false
        isConnected = false
    }

    /// Kalibre edilmiş öne eğilme açısı, derece. Pozitif = kafa öne düşmüş.
    /// Not: Mac testinde kafa öne eğilince ham pitch negatife gitti, işaret o gözleme göre çevrildi.
    static func forwardTiltDegrees(rawPitch: Double, offset: Double) -> Double {
        -(rawPitch - offset) * 180 / .pi
    }
}

extension HeadMotionService: CMHeadphoneMotionManagerDelegate {
    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.isConnected = true }
    }
    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.isConnected = false }
    }
}
