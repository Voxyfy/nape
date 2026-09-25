import Foundation
import ActivityKit

/// Live Activity veri sözleşmesi. Uygulama ve widget uzantısı aynı dosyayı derler.
struct NapeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var tilt: Int            // derece, 0…60
        var leaning: Bool
        var leaningSeconds: Int  // eşik üstünde kaç saniyedir
        var connected: Bool
        var leaningMinutes: Int  // bugün eşik üstünde geçen dakika
        var avgLoadKg: Int       // eğikken ortalama yük
        var liveLoadKg: Int      // şu anki açıda yük
    }
    var startedAt: Date
}
