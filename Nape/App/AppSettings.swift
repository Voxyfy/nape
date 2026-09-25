import Foundation
import Combine

/// Kullanıcı ayarları. UserDefaults'a yazılır, tüm ekranlar aynı örneği paylaşır.
@MainActor
final class AppSettings: ObservableObject {
    /// Bu açının üstü "eğik" sayılır (derece). Hansraj tablosuna göre 30° civarı boyuna ~18 kg bindirir.
    @Published var thresholdDegrees: Double { didSet { save() } }
    /// Eşik üstünde kesintisiz bu kadar saniye kalınca uyarı verilir.
    @Published var dwellSeconds: Double { didSet { save() } }
    /// Uyarı hâlâ sürüyorsa bu aralıkla tekrarlanır.
    @Published var repeatSeconds: Double { didSet { save() } }
    @Published var hapticEnabled: Bool { didSet { save() } }
    @Published var soundEnabled: Bool { didSet { save() } }
    @Published var nudgeSound: NudgeSound { didSet { save() } }
    /// Aynı eğik kalış içinde her tekrar bir kademe sertleşir (1×, 2×, 3× ses ve daha sert haptik).
    @Published var escalates: Bool { didSet { save() } }
    @Published var intensity: NudgeIntensity { didSet { save() } }
    /// Uyarıyı bildirim olarak da gönder (kilitli iPhone → Apple Watch'a yansır).
    @Published var notificationsEnabled: Bool { didSet { save() } }
    /// Arka planda takip için sessiz ses oturumu açık tutulur (iOS'un uygulamayı askıya almaması için).
    @Published var backgroundTracking: Bool { didSet { save() } }
    /// Kalibrasyon sıfırı (radyan). Kullanıcı "düz bak" dediğinde alınan ham pitch.
    @Published var calibrationOffset: Double { didSet { save() } }
    @Published var hasCompletedOnboarding: Bool { didSet { save() } }
    /// Vücut ağırlığı (kg). 0 = girilmedi, varsayılan kafa kütlesi kullanılır.
    @Published var bodyWeightKg: Double { didSet { save() } }

    var headMassKg: Double { NeckLoad.headMass(bodyWeightKg: bodyWeightKg > 0 ? bodyWeightKg : nil) }

    private let d = UserDefaults.standard

    init() {
        thresholdDegrees = d.object(forKey: "thresholdDegrees") as? Double ?? 25
        dwellSeconds = d.object(forKey: "dwellSeconds") as? Double ?? 30
        repeatSeconds = d.object(forKey: "repeatSeconds") as? Double ?? 60
        hapticEnabled = d.object(forKey: "hapticEnabled") as? Bool ?? true
        soundEnabled = d.object(forKey: "soundEnabled") as? Bool ?? true
        nudgeSound = NudgeSound(rawValue: d.string(forKey: "nudgeSound") ?? "") ?? .default
        escalates = d.object(forKey: "escalates") as? Bool ?? true
        intensity = NudgeIntensity(rawValue: d.string(forKey: "intensity") ?? "") ?? .firm
        notificationsEnabled = d.object(forKey: "notificationsEnabled") as? Bool ?? true
        backgroundTracking = d.object(forKey: "backgroundTracking") as? Bool ?? true
        calibrationOffset = d.object(forKey: "calibrationOffset") as? Double ?? 0
        hasCompletedOnboarding = d.bool(forKey: "hasCompletedOnboarding")
        #if targetEnvironment(simulator)
        // `-simResetOnboarding`: ekran görüntüsü turunda öğreticiyi yeniden göster.
        if CommandLine.arguments.contains("-simResetOnboarding") { hasCompletedOnboarding = false }
        #endif
        bodyWeightKg = d.double(forKey: "bodyWeightKg")
    }

    /// Ön ayarı uygula; custom seçilirse mevcut değerler korunur.
    func apply(_ i: NudgeIntensity) {
        intensity = i
        guard let p = i.preset else { return }
        dwellSeconds = p.dwell
        repeatSeconds = p.repeatEvery
        escalates = p.escalates
    }

    /// Kaydırıcı elle değişince ön ayar artık geçerli değil.
    func markCustom() {
        if intensity != .custom { intensity = .custom }
    }

    private func save() {
        d.set(thresholdDegrees, forKey: "thresholdDegrees")
        d.set(dwellSeconds, forKey: "dwellSeconds")
        d.set(repeatSeconds, forKey: "repeatSeconds")
        d.set(hapticEnabled, forKey: "hapticEnabled")
        d.set(soundEnabled, forKey: "soundEnabled")
        d.set(nudgeSound.rawValue, forKey: "nudgeSound")
        d.set(escalates, forKey: "escalates")
        d.set(intensity.rawValue, forKey: "intensity")
        d.set(notificationsEnabled, forKey: "notificationsEnabled")
        d.set(backgroundTracking, forKey: "backgroundTracking")
        d.set(calibrationOffset, forKey: "calibrationOffset")
        d.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        d.set(bodyWeightKg, forKey: "bodyWeightKg")
    }
}
