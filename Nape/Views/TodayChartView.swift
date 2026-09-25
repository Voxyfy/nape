import SwiftUI
import Charts

/// Bugün kartı: ikonlu üç metrik, Apple Sağlık tarzı saatlik çubuklar, yedi günlük şerit.
struct TodayChartView: View {
    let today: DailyStats
    let week: [DailyStats]   // eskiden yeniye, 7 gün
    var locked: Bool = false
    var onUnlock: () -> Void = {}
    @State private var showInfo = false

    private var currentHour: Int { Calendar.current.component(.hour, from: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(text: "Today")
                Spacer()
                Text(Date(), format: .dateTime.weekday(.wide).day().month())
                    .font(.footnote).foregroundStyle(.secondary)
            }

            // Birincil metrik: eğik süre. Ekran Süresi gibi, herkesin bildiği birim.
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").font(.footnote).foregroundStyle(.orange)
                    Text("Time leaning").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                }
                Text(Self.duration(today.tiltedSeconds))
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            // İkincil metrikler: eğikken ortalama yük (kg) ve uyarı sayısı
            HStack(spacing: NapeStyle.gap) {
                tile(icon: "scalemass.fill", tint: .blue, label: "Avg. load", value: today.averageLeaningLoadKg, unit: "kg", info: true)
                tile(icon: "bell.fill", tint: .purple, label: "Nudges", value: Double(today.alertCount), unit: nil, info: false)
            }

            ZStack {
            VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(0..<24, id: \.self) { h in
                    BarMark(x: .value("Hour", h), y: .value("Minutes", today.hourlyTiltedSeconds[h] / 60), width: .fixed(8))
                        .foregroundStyle(h == currentHour ? Color.orange : Color.orange.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 2.5))
                }
            }
            .chartXScale(domain: -0.5...23.5)
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3])).foregroundStyle(Color.primary.opacity(0.15))
                    AxisValueLabel { if let h = v.as(Int.self) { Text(String(format: "%02d", h)).font(.caption2).foregroundStyle(.secondary) } }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.primary.opacity(0.08))
                    AxisValueLabel { if let m = v.as(Double.self) { Text("\(Int(m))").font(.caption2).foregroundStyle(.secondary) } }
                }
            }
            .frame(height: 84)

            Divider().overlay(Color.primary.opacity(0.06))

            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("7 days").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text("min leaning").font(.caption2).foregroundStyle(.tertiary)
                }
                .frame(width: 56, alignment: .leading)
                .padding(.bottom, 14)
                let maxMin = max(1, week.map(\.tiltedSeconds).max() ?? 1)
                ForEach(week, id: \.day) { d in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(d.day == today.day ? Color.orange : Color.orange.opacity(0.3))
                            .frame(height: max(4, 28 * d.tiltedSeconds / maxMin))
                        Text(weekdayLetter(d.day))
                            .font(.caption2.weight(d.day == today.day ? .bold : .regular))
                            .foregroundStyle(d.day == today.day ? Color.primary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 46, alignment: .bottom)
            }
            .blur(radius: locked ? 6 : 0)
            .allowsHitTesting(!locked)
            if locked {
                // Grafik ve geçmiş Pro; bulanık önizleme + tek düğme
                Button(action: onUnlock) {
                    Label("Charts and history with Nape Pro", systemImage: "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(.regularMaterial))
                }
                .buttonStyle(.plain)
            }
            }
        }
        .padding(NapeStyle.cardPadding)
        .napeCard()
        .sheet(isPresented: $showInfo) { MetricInfoView() }
    }

    /// Küçük kutucuk: renkli ikon + etiket üstte, sayı altta. Üçüncül zemin kartın içinde derinlik verir.
    private func tile(icon: String, tint: Color, label: LocalizedStringKey, value: Double, unit: LocalizedStringKey?, info: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(tint))
                Text(label).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                if info {
                    Button { showInfo = true } label: {
                        Image(systemName: "info.circle").font(.footnote).foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value, format: .number.precision(.fractionLength(0)).grouping(.never))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if let unit { Text(unit).font(.caption.weight(.medium)).foregroundStyle(.secondary) }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.tertiarySystemGroupedBackground)))
    }

    /// "58 min" ya da "1 h 12 min"; saniyeyi göstermez.
    static func duration(_ seconds: Double) -> String {
        let m = Int(seconds / 60)
        if m < 60 { return String(localized: "\(m) min") }
        return String(localized: "\(m / 60) h \(m % 60) min")
    }

    private func weekdayLetter(_ day: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: day) else { return "" }
        let w = DateFormatter(); w.dateFormat = "EEEEE"
        return w.string(from: d)
    }
}
