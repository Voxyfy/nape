import SwiftUI

/// Profilden görünen takılı AirPod (Apple'ın tanıtım fotoğrafındaki duruş):
/// kulakta tomurcuk, sap aşağı ve hafif öne, sapın üstünde küçük koyu sensör çizgisi.
struct WornAirPodView: View {
    let connected: Bool
    /// 1 = ana ekran boyutu; widget'taki küçük figür için < 1.
    var scale: CGFloat = 1

    private var shell: LinearGradient {
        connected
            ? LinearGradient(colors: [Color.white, Color(white: 0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [Color(white: 0.64), Color(white: 0.50)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Sap: tomurcuğun altından öne-aşağı, hafif eğik
            ZStack(alignment: .top) {
                Capsule().fill(shell).frame(width: 4.5, height: 21)
                // Sensör/mikrofon çizgisi
                Capsule().fill(Color.black.opacity(0.35)).frame(width: 1.5, height: 4.5).offset(y: 4)
            }
            .rotationEffect(.degrees(-12), anchor: .top)
            .offset(x: 1, y: 7)
            // Tomurcuk
            Ellipse()
                .fill(shell)
                .frame(width: 10.5, height: 12)
            if !connected {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .offset(x: 9, y: -5)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1.5)
        .frame(width: 18, height: 34, alignment: .top)
        .scaleEffect(scale, anchor: .top)
    }
}

