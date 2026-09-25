import Foundation

/// Uyarı şiddeti ön ayarları. Seçim, süre ve kademeli tekrar ayarlarını tek hamlede belirler;
/// kullanıcı kaydırıcılarla oynarsa "custom"a düşer.
enum NudgeIntensity: String, CaseIterable, Identifiable {
    case gentle, firm, relentless, custom
    var id: String { rawValue }

    var title: String.LocalizationValue {
        switch self {
        case .gentle: "Gentle"
        case .firm: "Firm"
        case .relentless: "Relentless"
        case .custom: "Custom"
        }
    }

    /// (eşik üstü bekleme sn, tekrar aralığı sn, kademeli mi)
    var preset: (dwell: Double, repeatEvery: Double, escalates: Bool)? {
        switch self {
        case .gentle: (60, 120, false)
        case .firm: (30, 60, true)
        case .relentless: (15, 30, true)
        case .custom: nil
        }
    }
}
