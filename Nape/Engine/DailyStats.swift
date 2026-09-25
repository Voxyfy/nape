import Foundation

/// Bir günün özet sayıları. Motor her örnekte bunu günceller, DayStore diske yazar.
struct DailyStats: Codable, Equatable {
    var day: String                 // "2026-09-25", yerel takvim
    var trackedSeconds: Double = 0  // kulaklık takılıyken geçen süre
    var tiltedSeconds: Double = 0   // eşik üstünde geçen süre
    var loadKgMinutes: Double = 0   // Σ yük(kg) × süre(dk), tüm takip süresi (iç hesap)
    var leaningLoadKgMinutes: Double = 0 // aynı toplam, yalnız eşik üstündeyken; ortalama yük buradan
    var maxTiltDegrees: Double = 0
    var alertCount: Int = 0
    /// Saat saat eşik üstü süre; grafik bunu çizer.
    var hourlyTiltedSeconds: [Double] = Array(repeating: 0, count: 24)

    init(day: String) { self.day = day }

    // Eski kayıtlarda saatlik alan yok; eksikse sıfırla doldur.
    enum CodingKeys: String, CodingKey { case day, trackedSeconds, tiltedSeconds, loadKgMinutes, leaningLoadKgMinutes, maxTiltDegrees, alertCount, hourlyTiltedSeconds }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        day = try c.decode(String.self, forKey: .day)
        trackedSeconds = try c.decodeIfPresent(Double.self, forKey: .trackedSeconds) ?? 0
        tiltedSeconds = try c.decodeIfPresent(Double.self, forKey: .tiltedSeconds) ?? 0
        loadKgMinutes = try c.decodeIfPresent(Double.self, forKey: .loadKgMinutes) ?? 0
        leaningLoadKgMinutes = try c.decodeIfPresent(Double.self, forKey: .leaningLoadKgMinutes) ?? 0
        maxTiltDegrees = try c.decodeIfPresent(Double.self, forKey: .maxTiltDegrees) ?? 0
        alertCount = try c.decodeIfPresent(Int.self, forKey: .alertCount) ?? 0
        let h = try c.decodeIfPresent([Double].self, forKey: .hourlyTiltedSeconds) ?? []
        hourlyTiltedSeconds = h.count == 24 ? h : Array(repeating: 0, count: 24)
    }

    /// Eğik dururken boyna binen ortalama yük (kg). Eğik süre yoksa 0.
    var averageLeaningLoadKg: Double {
        tiltedSeconds > 30 ? leaningLoadKgMinutes / (tiltedSeconds / 60) : 0
    }

    static func key(for date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
