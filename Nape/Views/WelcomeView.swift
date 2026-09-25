import SwiftUI

/// İlk açılış öğreticisi. Apple'ın kendi uygulamalarındaki "Welcome to …" sayfasının düzeni:
/// büyük başlık, ikonlu özellik satırları, altta gizlilik notu ve tek "Continue" düğmesi.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 36) {
                    Image(systemName: HeadphoneInfo.placeholderSymbol)
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, 48)
                    Text("Welcome to Nape")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 28) {
                        row("figure.stand", "Measure your tilt",
                            "Nape uses the motion sensors in your AirPods to see how far your head leans forward.")
                        row("bell.badge.fill", "Get a nudge",
                            "Lean too long and Nape plays a sound in your AirPods so you lift your head.")
                        row("clock.fill", "See your day",
                            "How long you leaned today, and the average weight your neck carried while you did.")
                        row("iphone.gen3", "Works in the background",
                            "Switch apps or lock your phone; Nape keeps watching. Just don't swipe it away.")
                        row("platter.filled.top.iphone", "Live in the Dynamic Island",
                            "Your current tilt sits at the top of the screen and on the Lock Screen while tracking.")
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 28)
            }
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.title3)
                    Text("Head motion is processed on your iPhone. Nape never uploads it anywhere.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }

    private func row(_ symbol: String, _ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
