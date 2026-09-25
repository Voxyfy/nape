import Foundation

/// iPhone → Watch veri sözleşmesi. WatchConnectivity sözlükleri bu anahtarlarla kurulur.
/// Uygulama, saat uygulaması ve saat widget'ı aynı dosyayı derler.
enum WatchPayload {
    static let appGroup = "group.com.batuhanhaymana.nape"

    /// Anlık durum (applicationContext / complication userInfo)
    struct State: Codable, Equatable {
        var tilt: Int
        var leaning: Bool
        var connected: Bool
        var tracking: Bool
        var avgLoadKg: Int
        var leaningMinutes: Int
        var updatedAt: Date

        static let empty = State(tilt: 0, leaning: false, connected: false, tracking: false, avgLoadKg: 0, leaningMinutes: 0, updatedAt: .distantPast)

        var dictionary: [String: Any] {
            ["tilt": tilt, "leaning": leaning, "connected": connected, "tracking": tracking,
             "avgKg": avgLoadKg, "leaningMin": leaningMinutes, "at": updatedAt.timeIntervalSince1970]
        }

        init(tilt: Int, leaning: Bool, connected: Bool, tracking: Bool, avgLoadKg: Int, leaningMinutes: Int, updatedAt: Date) {
            self.tilt = tilt; self.leaning = leaning; self.connected = connected; self.tracking = tracking
            self.avgLoadKg = avgLoadKg; self.leaningMinutes = leaningMinutes; self.updatedAt = updatedAt
        }

        init?(dictionary d: [String: Any]) {
            guard let tilt = d["tilt"] as? Int else { return nil }
            self.init(tilt: tilt,
                      leaning: d["leaning"] as? Bool ?? false,
                      connected: d["connected"] as? Bool ?? false,
                      tracking: d["tracking"] as? Bool ?? false,
                      avgLoadKg: d["avgKg"] as? Int ?? 0,
                      leaningMinutes: d["leaningMin"] as? Int ?? 0,
                      updatedAt: Date(timeIntervalSince1970: d["at"] as? Double ?? 0))
        }
    }

    /// Anlık uyarı mesajı (sendMessage): ["nudge": kademe]
    static let nudgeKey = "nudge"

    /// Saat tarafında son durumun saklandığı App Group anahtarı (komplikasyon buradan okur).
    static let storedStateKey = "watch.lastState"

    static func store(_ s: State) {
        guard let d = UserDefaults(suiteName: appGroup), let data = try? JSONEncoder().encode(s) else { return }
        d.set(data, forKey: storedStateKey)
    }

    static func loadStored() -> State {
        guard let d = UserDefaults(suiteName: appGroup), let data = d.data(forKey: storedStateKey),
              let s = try? JSONDecoder().decode(State.self, from: data) else { return .empty }
        return s
    }
}
