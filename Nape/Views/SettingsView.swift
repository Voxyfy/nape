import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var engine: PostureEngine
    @EnvironmentObject private var store: ProStore
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss
    @State private var showInfo = false

    /// Simülatörde `-simScrollBottom`: üst bölümleri gizleyip alt bölümleri ekran görüntüsü için gösterir.
    private var simPage2: Bool {
        #if targetEnvironment(simulator)
        CommandLine.arguments.contains("-simScrollBottom")
        #else
        false
        #endif
    }

    private var intensityHint: LocalizedStringKey {
        switch settings.intensity {
        case .gentle: "Nudge after 60 s, repeat every 2 min, no escalation."
        case .firm: "Nudge after 30 s, repeat every minute, escalating."
        case .relentless: "Nudge after 15 s, repeat every 30 s, escalating."
        case .custom: "Custom timing below."
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if !store.isPro {
                    Section {
                        Button { showPaywall = true } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Nape Pro").font(.headline).foregroundStyle(.primary)
                                    Text(store.isTrialActive ? "Trial: \(store.trialDaysLeft) days left" : "Trial ended")
                                        .font(.footnote).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(store.product?.displayPrice ?? "").foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                if !simPage2 {
                Section("Threshold") {
                    LabeledContent("Tilt angle", value: "\(Int(settings.thresholdDegrees))°")
                    Slider(value: $settings.thresholdDegrees, in: 15...45, step: 1)
                    Text("Above this angle Nape counts you as leaning. At \(Int(settings.thresholdDegrees))° your neck carries about \(Int(NeckLoad.kilograms(forTilt: settings.thresholdDegrees, headMassKg: settings.headMassKg).rounded())) kg.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Picker("Intensity", selection: Binding(
                        get: { settings.intensity },
                        set: { settings.apply($0) })) {
                        ForEach([NudgeIntensity.gentle, .firm, .relentless]) { i in
                            Text(String(localized: i.title)).tag(i)
                        }
                        if settings.intensity == .custom { Text(String(localized: NudgeIntensity.custom.title)).tag(NudgeIntensity.custom) }
                    }
                    .pickerStyle(.segmented)
                    .disabled(!store.isUnlocked)
                    Text(intensityHint)
                        .font(.footnote).foregroundStyle(.secondary)
                } header: {
                    Text("Nudges")
                }
                Section {
                    LabeledContent("After") { Text("\(Int(settings.dwellSeconds)) s") }
                    Slider(value: Binding(get: { settings.dwellSeconds }, set: { settings.dwellSeconds = $0; settings.markCustom() }), in: 10...120, step: 5)
                    LabeledContent("Repeat every") { Text("\(Int(settings.repeatSeconds)) s") }
                    Slider(value: Binding(get: { settings.repeatSeconds }, set: { settings.repeatSeconds = $0; settings.markCustom() }), in: 15...300, step: 15)
                    Toggle("Escalate on repeat", isOn: Binding(get: { settings.escalates }, set: { settings.escalates = $0; settings.markCustom() }))
                    Toggle("Haptic", isOn: $settings.hapticEnabled)
                    Toggle("Sound in AirPods", isOn: $settings.soundEnabled)
                } footer: {
                    Text("With escalation, each repeat within the same slouch plays the sound one more time and taps harder. Lifting your head resets it.")
                }
                }
                Section {
                    // Satır içi seçici: sistemin onay işaretli listesi; seçim değişince önizleme çalar.
                    Picker("Alert sound", selection: Binding(
                        get: { settings.nudgeSound },
                        set: { settings.nudgeSound = $0; engine.previewSound($0) })) {
                        ForEach(NudgeSound.allCases) { s in
                            Text(String(localized: s.title)).tag(s)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Alert sound")
                } footer: {
                    Text("Tap a sound to preview it in your AirPods.")
                }
                .disabled(!settings.soundEnabled || !store.isUnlocked)
                Section {
                    if !store.isUnlocked { Button("Unlock with Nape Pro") { showPaywall = true } }
                    Toggle("Personalize with body weight", isOn: Binding(
                        get: { settings.bodyWeightKg > 0 },
                        set: { settings.bodyWeightKg = $0 ? 70 : 0 }))
                    .disabled(!store.isUnlocked)
                    if settings.bodyWeightKg > 0 {
                        LabeledContent("Body weight", value: "\(Int(settings.bodyWeightKg)) kg")
                        Slider(value: $settings.bodyWeightKg, in: 40...150, step: 1)
                    }
                    Button("About neck load") { showInfo = true }
                } header: {
                    Text("Neck load")
                } footer: {
                    Text("Head and neck weigh about 8% of body weight. Without it Nape assumes 5.4 kg.")
                }
                Section {
                    Toggle("Nudge as notification", isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { settings.notificationsEnabled = $0; if $0 { engine.requestNotificationPermission() } }))
                } header: {
                    Text("Apple Watch")
                } footer: {
                    Text("When your iPhone is locked, the nudge shows on your Apple Watch with a tap on the wrist. Open the Nape app on the watch and start a session for instant taps while you use your iPhone.")
                }
                Section {
                    Toggle("Track in background", isOn: $settings.backgroundTracking)
                } footer: {
                    Text("Keeps a silent audio session open so iOS doesn't pause tracking when you switch apps. Uses a little more battery.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showInfo) { MetricInfoView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
