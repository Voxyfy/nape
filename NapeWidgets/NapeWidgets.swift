import WidgetKit
import SwiftUI
import ActivityKit

@main
struct NapeWidgets: WidgetBundle {
    var body: some Widget {
        NapeLiveActivity()
    }
}

/// Dynamic Island + kilit ekranı. Renk dili uygulamayla aynı: dik yeşil, eğik turuncu, kulaklık yok gri.
struct NapeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NapeActivityAttributes.self) { context in
            LockScreenCard(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let s = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    MiniFigure(tilt: s.tilt, color: tint(s), connected: s.connected)
                        .frame(width: 56, height: 64)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(s.tilt)°")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(tint(s))
                        Text(statusText(s)).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(s.leaningMinutes) min leaning · \(s.liveLoadKg) kg", systemImage: "scalemass.fill")
                        Spacer()
                        if s.leaning {
                            Label("\(s.leaningSeconds)s", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                Image(systemName: s.connected ? "figure.stand" : "airpods")
                    .foregroundStyle(tint(s))
            } compactTrailing: {
                Text(s.connected ? "\(s.tilt)°" : "—")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(tint(s))
            } minimal: {
                Text(s.connected ? "\(s.tilt)" : "—")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(tint(s))
            }
            .keylineTint(tint(s))
        }
    }

    private func tint(_ s: NapeActivityAttributes.ContentState) -> Color {
        !s.connected ? .gray : (s.leaning ? .orange : .green)
    }

    private func statusText(_ s: NapeActivityAttributes.ContentState) -> LocalizedStringKey {
        !s.connected ? "No AirPods" : (s.leaning ? "Leaning" : "Upright")
    }
}

/// Kilit ekranı kartı: solda figür, sağda açı ve durum.
struct LockScreenCard: View {
    let state: NapeActivityAttributes.ContentState
    private var tint: Color { !state.connected ? .gray : (state.leaning ? .orange : .green) }

    var body: some View {
        HStack(spacing: 14) {
            MiniFigure(tilt: state.tilt, color: tint, connected: state.connected)
                .frame(width: 64, height: 72)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nape").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(state.connected ? (state.leaning ? "Leaning for \(state.leaningSeconds)s" : "Upright") : "Put on your AirPods")
                    .font(.headline)
                Text(state.connected ? "\(state.leaningMinutes) min leaning today · \(state.liveLoadKg) kg now" : "\(state.leaningMinutes) min leaning today").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(state.connected ? "\(state.tilt)°" : "—")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .padding(16)
    }
}

/// Küçük profil: uygulamadaki silüetin aynısı, açıyla döner.
struct MiniFigure: View {
    let tilt: Int
    let color: Color
    var connected: Bool = true

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height * 0.92
            let w = min(geo.size.width, h * HeadSilhouetteShape.aspect)
            let hh = w / HeadSilhouetteShape.aspect
            ZStack(alignment: .topLeading) {
                HeadSilhouetteShape()
                    .fill(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: hh)
                // Kulaklık, ana ekrandaki çizimin ölçeklenmiş hali
                WornAirPodView(connected: connected, scale: hh / 150)
                    .position(x: 0.42 * w, y: 0.49 * hh + 11 * hh / 150)
            }
            .frame(width: w, height: hh)
            .rotationEffect(.degrees(Double(min(60, max(0, tilt))) * 0.7), anchor: UnitPoint(x: HeadSilhouetteShape.neckBaseX, y: 1))
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }
}
