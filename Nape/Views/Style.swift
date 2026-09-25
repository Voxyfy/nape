import SwiftUI

/// Tasarım sabitleri: 8 pt ızgara, tek köşe yarıçapı, tek kart stili. Her ekran bunları kullanır.
enum NapeStyle {
    static let cardRadius: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let gap: CGFloat = 12
}

/// Kart: ikincil gruplu zemin + %6 beyaz ince kenar. Koyu temada derinlik, açıkta sessiz kalır.
struct NapeCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: NapeStyle.cardRadius, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: NapeStyle.cardRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func napeCard() -> some View { modifier(NapeCard()) }
}

/// Bölüm başlığı: küçük büyük harfli, ikincil renk. Apple Sağlık'taki "BUGÜN" gibi.
struct SectionLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .kerning(0.6)
    }
}
