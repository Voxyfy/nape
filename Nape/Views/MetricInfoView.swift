import SwiftUI

/// "Tahmini boyun yükü" nasıl hesaplanır: kaynak, tablo ve sınırlar. Tıbbi iddia yok.
struct MetricInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    private let angles = [0, 15, 30, 45, 60]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Nape estimates how much your neck carries from the angle of your head. The further you look down, the heavier your head effectively becomes for the muscles and discs in your neck.")
                }
                Section("How it's calculated") {
                    Text("Load = m × (cos θ + 4.9 × sin θ)")
                        .font(.system(.body, design: .monospaced))
                    Text("m is the mass of your head and neck, θ the forward tilt. cos θ is the part of the head's weight pressing straight down the spine; 4.9 × sin θ is the pull of the neck muscles that keep the head from falling forward, since their leverage is about five times shorter than the head's. Tuned to match the Hansraj (2014) cervical spine model within 1.5 kg.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Load by tilt angle") {
                    ForEach(angles, id: \.self) { deg in
                        LabeledContent("\(deg)°") {
                            Text("≈ \(Int(NeckLoad.kilograms(forTilt: Double(deg), headMassKg: settings.headMassKg).rounded())) kg").monospacedDigit()
                        }
                    }
                    if settings.bodyWeightKg > 0 {
                        Text("Head and neck mass \(settings.headMassKg, format: .number.precision(.fractionLength(1))) kg, 8.1% of your body weight (Dempster, 1955).")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("Using an average head and neck mass of 5.4 kg. Enter your body weight in Settings to personalize.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Section("Average load") {
                    Text("While you are past your threshold, Nape averages the estimated load over that time. \"Avg. load 17 kg\" means that during the minutes you spent leaning today, your neck carried about 17 kg on average, roughly three times its upright load.")
                }
                Section("Limits") {
                    Text("This is a static lever model, not a measurement of your body. No clinical study links a specific kg·min figure to pain or injury. Treat the number as a trend to lower over time, not as a medical measurement.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("About neck load")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
