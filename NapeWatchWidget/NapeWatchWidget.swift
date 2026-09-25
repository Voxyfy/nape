import WidgetKit
import SwiftUI

@main
struct NapeWatchWidgetBundle: WidgetBundle {
    var body: some Widget { NapeComplication() }
}

struct NapeEntry: TimelineEntry {
    let date: Date
    let state: WatchPayload.State
}

/// Komplikasyon verisi App Group'tan okunur; saat uygulaması her güncellemede yeniden yükletir.
struct NapeProvider: TimelineProvider {
    func placeholder(in context: Context) -> NapeEntry {
        NapeEntry(date: Date(), state: .init(tilt: 12, leaning: false, connected: true, tracking: true, avgLoadKg: 17, leaningMinutes: 23, updatedAt: Date()))
    }
    func getSnapshot(in context: Context, completion: @escaping (NapeEntry) -> Void) {
        completion(NapeEntry(date: Date(), state: context.isPreview ? placeholder(in: context).state : WatchPayload.loadStored()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NapeEntry>) -> Void) {
        let entry = NapeEntry(date: Date(), state: WatchPayload.loadStored())
        // 15 dk sonra "bayat" sayılır; uygulama gelen her veriyle zaten yeniler.
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))))
    }
}

struct NapeComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NapeComplication", provider: NapeProvider()) { entry in
            NapeComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Nape")
        .description("Neck load and current tilt.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct NapeComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NapeEntry
    private var s: WatchPayload.State { entry.state }
    private var fresh: Bool { s.tracking && Date().timeIntervalSince(s.updatedAt) < 1800 }

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -2) {
                    Image(systemName: "figure.stand").font(.system(size: 12))
                    Text(fresh ? "\(s.tilt)°" : "\(s.leaningMinutes)m")
                        .font(.system(size: 16, weight: .bold, design: .rounded)).monospacedDigit()
                }
            }
            .widgetAccentable()
        case .accessoryCorner:
            Text(fresh ? "\(s.tilt)°" : "\(s.leaningMinutes)m")
                .font(.system(size: 20, weight: .bold, design: .rounded)).monospacedDigit()
                .widgetCurvesContent()
                .widgetLabel { Text(fresh ? "Neck" : "Leaning") }
        case .accessoryInline:
            Label(fresh ? "\(s.tilt)° · \(s.leaningMinutes) min leaning" : "\(s.leaningMinutes) min leaning today", systemImage: "figure.stand")
        default:
            HStack(spacing: 8) {
                HeadSilhouetteShape()
                    .fill(fresh ? (s.leaning ? Color.orange : Color.green) : Color.gray)
                    .aspectRatio(HeadSilhouetteShape.aspect, contentMode: .fit)
                    .frame(height: 40)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Nape").font(.caption2).foregroundStyle(.secondary)
                    Text(fresh ? (s.leaning ? "Leaning" : "Upright") : "Tracking paused").font(.headline)
                    Text(s.avgLoadKg > 0 ? "\(s.leaningMinutes) min · avg \(s.avgLoadKg) kg" : "\(s.leaningMinutes) min leaning").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if fresh {
                    Text("\(s.tilt)°").font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit()
                }
            }
            .widgetAccentable()
        }
    }
}
