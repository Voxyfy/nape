import SwiftUI

/// Ana ekran: üstte canlı silüet (kahraman), ortada Screen Time tarzı grafik, altta kontroller.
struct HomeView: View {
    @EnvironmentObject private var motion: HeadMotionService
    @EnvironmentObject private var engine: PostureEngine
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: ProStore
    @State private var showWelcome = false
    @State private var showPaywall = false
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
                    if !store.isPro { trialBanner }
                    hero
                    if engine.dailyLimitReached && !store.isUnlocked { limitCard }
                    actions
                    TodayChartView(today: engine.today, week: engine.recentDays(7), locked: !store.isUnlocked) { showPaywall = true }
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
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: store.isPro) { _, pro in
                // Satın alma sonrası sınır kalkar, takip kendiliğinden sürer
                if pro && !engine.isTracking && !userPaused { engine.startTracking() }
            }
            .onAppear {
                engine.isUnlocked = { [weak store] in store?.isUnlocked ?? true }
                #if targetEnvironment(simulator)
                NSLog("HOME onAppear onboarding=%d calib=%.4f paused=%d tracking=%d unlocked=%d tracked=%.0f", settings.hasCompletedOnboarding, settings.calibrationOffset, userPaused, engine.isTracking, store.isUnlocked, engine.today.trackedSeconds)
                #endif
                // Sayfa sunumunu bir sonraki döngüye bırak: NavigationStack hazır olmadan sheet açmak sessizce başarısız olabiliyor.
                if !settings.hasCompletedOnboarding { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showWelcome = true } }
                else if settings.calibrationOffset == 0 && !engine.isTracking { showCalibration = true }
                // Kalibre edilmişse ve kullanıcı duraklatmadıysa takip kendiliğinden başlar; Apple uygulamaları gibi düğme beklemez.
                else if !userPaused && !engine.isTracking && motion.isAvailable { engine.startTracking() }
                #if targetEnvironment(simulator)
                // Tasarım turu: `-simOpenSettings` ayarları açar, `-simScrollBottom` alt kısmı gösterir.
                if CommandLine.arguments.contains("-simOpenPaywall") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showPaywall = true }
                }
                if CommandLine.arguments.contains("-simOpenSettings") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showSettings = true }
                }
                #endif
            }
        }
    }

    /// Deneme şeridi: kalan gün ya da bitti; dokununca Pro sayfası.
    private var trialBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: store.isTrialActive ? "clock.badge" : "lock.fill")
                    .foregroundStyle(store.isTrialActive ? Color.accentColor : Color.orange)
                Text(store.isTrialActive ? "Trial: \(store.trialDaysLeft) days left" : "Trial ended · Free tier active")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("Nape Pro").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .napeCard()
        }
        .buttonStyle(.plain)
    }

    /// Günlük ücretsiz sınır doldu.
    private var limitCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's free hour is used up", systemImage: "hourglass").font(.headline)
            Text("Tracking resumes tomorrow, or right now with Nape Pro.").font(.subheadline).foregroundStyle(.secondary)
            Button { showPaywall = true } label: {
                Text("Unlock Nape Pro").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(NapeStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .napeCard()
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
