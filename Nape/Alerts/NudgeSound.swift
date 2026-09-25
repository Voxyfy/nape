import Foundation

/// Kullanıcının seçebildiği uyarı sesleri. Dosyalar Resources/nudge_<rawValue>.wav, hepsi üretici script ile sentezlendi.
enum NudgeSound: String, CaseIterable, Identifiable {
    case chime, beeps, alarm, siren, rapid

    var id: String { rawValue }
    var fileName: String { "nudge_\(rawValue)" }

    /// Ekranda görünen ad; xcstrings anahtarı.
    var title: String.LocalizationValue {
        switch self {
        case .chime: "Chime"
        case .beeps: "Triple beep"
        case .alarm: "Alarm"
        case .siren: "Siren"
        case .rapid: "Rapid"
        }
    }

    static let `default`: NudgeSound = .beeps
}
