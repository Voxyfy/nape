import SwiftUI

/// Saat ana ekranı: figür + açı, durum satırı, günlük yük, oturum düğmesi.
struct WatchHomeView: View {
    @EnvironmentObject private var model: WatchModel

    private var s: WatchPayload.State { model.state }
    private var live: Bool { s.tracking && s.connected && Date().timeIntervalSince(s.updatedAt) < 120 }
    private var tint: Color { !live ? .gray : (s.leaning ? .orange : .green) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 8) {
                        WatchFigure(tilt: live ? s.tilt : 0, color: tint, connected: s.connected)
                            .frame(width: 64, height: 72)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(live ? "\(s.tilt)°" : "—")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(tint)
                            Text(statusText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    HStack {
                        Label("\(s.leaningMinutes) min", systemImage: "clock.fill")
                        Spacer()
                        if s.avgLoadKg > 0 { Label("\(s.avgLoadKg) kg", systemImage: "scalemass.fill") }
                        Text("today").foregroundStyle(.secondary)
                    }
                    .font(.caption2)
                    .padding(.horizontal, 4)

                    Button(action: model.toggleSession) {
                        Label(model.sessionActive ? "End session" : "Start session",
                              systemImage: model.sessionActive ? "stop.fill" : "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(model.sessionActive ? .gray : .green)
                    Text("Session keeps the watch awake for up to an hour so nudges reach your wrist instantly.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Nape")
        }
    }

    private var statusText: LocalizedStringKey {
        if !s.tracking { return live ? "Upright" : (s.updatedAt == .distantPast ? "Open Nape on iPhone" : "Tracking paused") }
        if !s.connected { return "Put on your AirPods" }
        if Date().timeIntervalSince(s.updatedAt) >= 120 { return "Waiting for iPhone" }
        return s.leaning ? "Leaning" : "Upright"
    }
}

/// Saat için küçük figür, iPhone'daki silüetin aynısı.
struct WatchFigure: View {
    let tilt: Int
    let color: Color
    var connected: Bool = true
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height * 0.94
            let w = min(geo.size.width, h * HeadSilhouetteShape.aspect)
            let hh = w / HeadSilhouetteShape.aspect
            ZStack(alignment: .topLeading) {
                HeadSilhouetteShape()
                    .fill(LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w, height: hh)
                WornAirPodView(connected: connected, scale: hh / 150)
                    .position(x: 0.42 * w, y: 0.49 * hh + 11 * hh / 150)
            }
            .frame(width: w, height: hh)
            .rotationEffect(.degrees(Double(min(60, max(0, tilt))) * 0.7), anchor: UnitPoint(x: HeadSilhouetteShape.neckBaseX, y: 1))
            .animation(.easeOut(duration: 0.3), value: tilt)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
    }
}
