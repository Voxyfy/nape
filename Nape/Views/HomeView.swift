import SwiftUI

/// Ana ekran: üstte canlı silüet (kahraman), ortada Screen Time tarzı grafik, altta kontroller.
struct HomeView: View {
    @EnvironmentObject private var motion: HeadMotionService
    @EnvironmentObject private var engine: PostureEngine
    @EnvironmentObject private var settings: AppSettings
    @State private var showWelcome = false
    @State private var showCalibration = false
    @State private var showSettings = false
    /// Kullanıcı bilerek duraklattıysa uygulama açılışta kendiliğinden başlatmaz.
    @AppStorage("userPaused") private var userPaused = false

    private var isLeaning: Bool { if case .leaning = engine.state { return true } else { return false } }
    private var live: Bool { engine.isTracking && motion.isConnected }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NapeStyle.gap) {
                    hero
                    actions
                    TodayChartView(today: engine.today, week: engine.recentDays(7))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nape")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showWelcome, onDismiss: { showCalibration = true }) {
                WelcomeView {
                    settings.hasCompletedOnboarding = true
                    showWelcome = false
                }
            }
            .sheet(isPresented: $showCalibration) { CalibrationView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onAppear {
                // Sayfa sunumunu bir sonraki döngüye bırak: NavigationStack hazır olmadan sheet açmak sessizce başarısız olabiliyor.
                if !settings.hasCompletedOnboarding { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showWelcome = true } }
                else if settings.calibrationOffset == 0 && !engine.isTracking { showCalibration = true }
                // Kalibre edilmişse ve kullanıcı duraklatmadıysa takip kendiliğinden başlar; Apple uygulamaları gibi düğme beklemez.
                else if !userPaused && !engine.isTracking && motion.isAvailable { engine.startTracking() }
                #if targetEnvironment(simulator)
                // Tasarım turu: `-simOpenSettings` ayarları açar, `-simScrollBottom` alt kısmı gösterir.
                if CommandLine.arguments.contains("-simOpenSettings") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showSettings = true }
                }
                #endif
            }
        }
    }

    // MARK: - Kahraman alan

    private var stateColor: Color { !live ? Color(.systemGray3) : (isLeaning ? .orange : .green) }

    private var hero: some View {
        ZStack(alignment: .topTrailing) {
            // Figür sol altta; öne eğilirken sağdaki boşluğa düşer
            HeadProfileView(tiltDegrees: live ? engine.tiltDegrees : 0, connected: motion.isConnected, leaning: isLeaning)
                .frame(width: 180, height: 214)
                .frame(maxWidth: .infinity, alignment: .bottomLeading)
                .padding(.leading, 4)
            VStack(alignment: .trailing, spacing: 6) {
                Text(live ? "\(Int(max(0, engine.tiltDegrees).rounded()))°" : "—")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(stateColor)
                statusLine
                TiltBar(degrees: live ? engine.tiltDegrees : 0, threshold: settings.thresholdDegrees, active: live)
                    .frame(width: 132, height: 6)
                    .padding(.top, 6)
                if live {
                    // Açının somut karşılığı: şu an boyna binen tahmini yük
                    Text("≈ \(Int(NeckLoad.kilograms(forTilt: max(0, engine.tiltDegrees), headMassKg: settings.headMassKg).rounded())) kg on your neck")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
                deviceLine
            }
            .padding(.top, 16)
            .padding(.trailing, NapeStyle.cardPadding)
            .padding(.bottom, NapeStyle.cardPadding)
        }
        .frame(height: 228)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: NapeStyle.cardRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: NapeStyle.cardRadius, style: .continuous)
                        .fill(RadialGradient(colors: [stateColor.opacity(live ? 0.10 : 0.05), .clear], center: .bottomLeading, startRadius: 10, endRadius: 300))
                )
                .animation(.easeInOut(duration: 0.4), value: stateColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: NapeStyle.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NapeStyle.cardRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .onChange(of: isLeaning) { _, leaning in
            // Duruma geçişte hafif dokunuş: eğilince belirgin, düzelince yumuşak.
            UIImpactFeedbackGenerator(style: leaning ? .medium : .light).impactOccurred()
        }
    }

    private var statusLine: some View {
        Group {
            switch engine.state {
            case .idle: Text("Tracking off")
            case .disconnected: Text("Put on your AirPods")
            case .upright: Text("Upright")
            case .leaning(let s): Text("Leaning for \(Int(s))s")
            }
        }
        .font(.headline)
        .multilineTextAlignment(.trailing)
        .foregroundStyle(live ? Color.primary : Color.secondary)
        .contentTransition(.numericText())
    }

    private var deviceLine: some View {
        HStack(spacing: 6) {
            Image(systemName: motion.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(motion.isConnected ? Color.green : Color.red)
            // Koşullu String yerine ayrı Text: yalnızca sabit anahtar yerelleştirilir.
            if motion.isConnected {
                Text(HeadphoneInfo.current()?.name ?? "AirPods").lineLimit(1)
            } else {
                Text("Not connected")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }

    /// Kart altı hızlı eylemler: iki eşit kapsül, ikon + açık etiket. Ne yaptığı okunur.
    private var actions: some View {
        HStack(spacing: NapeStyle.gap) {
            Button {
                if engine.isTracking { engine.stopTracking(); userPaused = true }
                else { engine.startTracking(); userPaused = false }
            } label: {
                Label(engine.isTracking ? "Pause tracking" : "Resume tracking",
                      systemImage: engine.isTracking ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(engine.isTracking ? .primary : .accentColor)
            .disabled(!motion.isAvailable)

            Button { showCalibration = true } label: {
                Label("Set upright pose", systemImage: "figure.stand")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(.primary)
        }
    }
}


/// Yatay eğim çubuğu: 0…60°, eşik işareti. Kahraman alandaki sayının altında küçük mühendislik detayı.
struct TiltBar: View {
    let degrees: Double
    let threshold: Double
    let active: Bool
    private let maxDeg = 60.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let fill = max(0, min(maxDeg, degrees)) / maxDeg
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                if active {
                    Capsule()
                        .fill(degrees >= threshold ? Color.orange : Color.green)
                        .frame(width: max(6, w * fill))
                        .animation(.easeOut(duration: 0.2), value: fill)
                }
                Rectangle()
                    .fill(Color.primary.opacity(0.45))
                    .frame(width: 1.5, height: geo.size.height + 6)
                    .offset(x: w * threshold / maxDeg)
            }
        }
    }
}
