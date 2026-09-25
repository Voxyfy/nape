import SwiftUI
import StoreKit

/// Nape Pro sayfası: Apple'ın kendi satın alma sayfaları gibi; başlık, özellik listesi, fiyatlı tek düğme,
/// geri yükle ve yasal bağlantılar. Fiyat App Store'dan gelir, sabit yazılmaz.
struct PaywallView: View {
    @EnvironmentObject private var store: ProStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Image(systemName: "figure.stand")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 24)
                        Text("Nape Pro").font(.largeTitle.bold())
                        Text(store.isTrialActive
                             ? "Your trial ends in \(store.trialDaysLeft) days. Keep everything with a one-time purchase."
                             : "Your free trial has ended. Unlock everything with a one-time purchase.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        row("infinity", "Unlimited tracking", "Free tier tracks one hour a day after the trial.")
                        row("speaker.wave.2.fill", "Five sounds, three intensities", "Chime to siren, gentle to relentless, escalating nudges.")
                        row("chart.bar.fill", "Hourly chart and 7-day history", "See when you slouch and whether you're improving.")
                        row("scalemass.fill", "Personal load estimate", "Tuned to your body weight.")
                        row("applewatch", "Apple Watch", "Wrist nudges, live status and a complication.")
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        Task { await store.purchase(); if store.isPro { dismiss() } }
                    } label: {
                        HStack {
                            if store.purchaseInFlight { ProgressView().tint(.white) }
                            Text(priceLabel).font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .disabled((store.product == nil && !CommandLine.arguments.contains("-simFakePrice")) || store.purchaseInFlight)
                    HStack(spacing: 18) {
                        Button("Restore Purchases") { Task { await store.restore(); if store.isPro { dismiss() } } }
                        Link("Privacy", destination: URL(string: "https://voxyfy.github.io/nape/privacy.html")!)
                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    if let e = store.lastError { Text(e).font(.caption2).foregroundStyle(.red).lineLimit(2) }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(.bar)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Not now") { dismiss() } }
            }
        }
    }

    private var priceLabel: String {
        if let p = store.product { return String(localized: "Unlock for \(p.displayPrice)") }
        #if targetEnvironment(simulator)
        // simctl ile başlatınca StoreKit yapılandırması yüklenmez; ekran görüntüsü için sahte fiyat
        if CommandLine.arguments.contains("-simFakePrice") { return String(localized: "Unlock for \(Locale.current.identifier.hasPrefix("tr") ? "₺149,99" : "$4.99")") }
        #endif
        return String(localized: "Loading price…")
    }

    private func row(_ symbol: String, _ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Color.accentColor).frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
