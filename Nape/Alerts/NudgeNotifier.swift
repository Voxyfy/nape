import Foundation
import UserNotifications

/// Uyarıyı yerel bildirim olarak da yayınlar. iPhone kilitliyken iOS bildirimi Apple Watch'a
/// yansıtır ve bilek titrer; saat uygulaması kurulu olmasa bile çalışır.
/// Telefon kilidi açıkken bildirim telefonda kısa bir başlık olarak görünür (ses yok, haptik zaten var).
final class NudgeNotifier {
    private let center = UNUserNotificationCenter.current()
    private(set) var authorized = false

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] ok, _ in
            self?.authorized = ok
        }
    }

    func refreshStatus() {
        center.getNotificationSettings { [weak self] s in
            self?.authorized = s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
        }
    }

    func post(level: Int, tilt: Int) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Lift your head")
        content.body = String(localized: "You've been leaning at \(tilt)° for a while.")
        content.sound = nil
        content.interruptionLevel = level >= 2 ? .timeSensitive : .active
        content.threadIdentifier = "nudge"
        // Aynı kimlik: yeni uyarı eskisinin yerine geçer, bildirim yığını oluşmaz.
        let req = UNNotificationRequest(identifier: "nape.nudge", content: content, trigger: nil)
        center.add(req)
    }

    func clear() {
        center.removeDeliveredNotifications(withIdentifiers: ["nape.nudge"])
    }
}
