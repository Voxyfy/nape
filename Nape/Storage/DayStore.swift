import Foundation

/// Günlük istatistikleri UserDefaults'ta JSON olarak tutar.
/// MVP için yeterli; geçmiş büyüyünce SwiftData'ya taşınır.
final class DayStore {
    private let key = "dailyStats.v1"
    private let d = UserDefaults.standard

    func loadAll() -> [String: DailyStats] {
        guard let data = d.data(forKey: key),
              let dict = try? JSONDecoder().decode([String: DailyStats].self, from: data) else { return [:] }
        return dict
    }

    func load(day: String) -> DailyStats {
        loadAll()[day] ?? DailyStats(day: day)
    }

    func save(_ stats: DailyStats) {
        var all = loadAll()
        all[stats.day] = stats
        // Son 90 günü tut, gerisini at.
        if all.count > 90 {
            for k in all.keys.sorted().prefix(all.count - 90) { all.removeValue(forKey: k) }
        }
        if let data = try? JSONEncoder().encode(all) { d.set(data, forKey: key) }
    }

    /// Son n gün, eskiden yeniye. Veri olmayan günler boş kayıtla doldurulur.
    func recent(days n: Int) -> [DailyStats] {
        let all = loadAll()
        return (0..<n).reversed().map { back in
            let date = Calendar.current.date(byAdding: .day, value: -back, to: Date())!
            let k = DailyStats.key(for: date)
            return all[k] ?? DailyStats(day: k)
        }
    }
}
