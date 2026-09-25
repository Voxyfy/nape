import SwiftUI

/// "Hayalet" figür: sağa bakan gerçek profil + omuzlar tek parça, alt uçta saydamlaşarak kaybolur.
/// (Arkadaki bulanık ışıma denendi; figürle dönünce maske sınırında şerit yapıyordu, kaldırıldı.) Bütün figür omuz tabanından öne eğilir; görünen sağ kulakta sağ AirPod.
struct HeadProfileView: View {
    let tiltDegrees: Double
    let connected: Bool
    let leaning: Bool

    /// Kulağın kafa kutusundaki yeri (0…1). Görsele göre elle ayarlandı.
    private let ear = CGPoint(x: 0.42, y: 0.49)
    /// Omuzlar kafa kutusunun altına bu oranda uzar; kart tabanının çok altına taşar ki
    /// figür dönerken sol altta zemin açılmasın (kart zaten kırpar).
    private let shoulderExtent: CGFloat = 1.1

    var body: some View {
        GeometryReader { geo in
            // Kafa kutusu yüksekliği: kart yüksekliğinin %62'si; omuzlar altta taşar
            let hh = min(geo.size.height * 0.62, geo.size.width * 0.78 / HeadSilhouetteShape.aspect)
            let w = hh * HeadSilhouetteShape.aspect
            let figH = hh * (1 + shoulderExtent)
            let box = CGRect(x: (geo.size.width - w) / 2, y: geo.size.height * 0.08, width: w, height: figH)
            // Dönüş merkezi: kart tabanı hizası, figür ortası
            let pivotY = (geo.size.height - box.minY) / figH
            // Eğim 1:1 değil; 60° gerçek eğim ekranda 42° olur, figür karttan taşmaz ama düşüş net görünür.
            let visualTilt = max(0, min(60, tiltDegrees)) * 0.7

            // Üstten hizalı: figür ve kulaklık aynı koordinat sisteminde (kafa kutusu tepesi = 0)
            ZStack(alignment: .topLeading) {
                figure(headBox: CGRect(x: 0, y: 0, width: w, height: hh))
                    .blur(radius: 0.7)
                earPod
                    .position(x: ear.x * w, y: ear.y * hh + 11)
            }
            .frame(width: w, height: figH, alignment: .topLeading)
            .rotationEffect(.degrees(visualTilt), anchor: UnitPoint(x: 0.5, y: pivotY))
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: visualTilt)
            .offset(x: box.minX, y: box.minY)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            // Hayalet solması kart uzayında: dönüşten bağımsız, her zaman yatay taban
            .mask(
                LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.70), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(width: geo.size.width * 3, height: geo.size.height)
            )
        }
    }

    /// Kafa + omuz, tek dolgu. Omuz şekli kafa kutusunun altına taşar; kırpılmaz.
    private func figure(headBox: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            ShouldersShape(extent: shoulderExtent)
                .fill(fill)
                .frame(width: headBox.width, height: headBox.height)
            HeadSilhouetteShape()
                .fill(fill)
                .frame(width: headBox.width, height: headBox.height)
        }
    }

    private var stateColor: Color { !connected ? Color(.systemGray2) : (leaning ? .orange : .green) }

    private var fill: LinearGradient {
        LinearGradient(colors: [stateColor, stateColor.opacity(0.85)], startPoint: .top, endPoint: .bottom)
    }

    /// Yandan takılı AirPod: kulakta tomurcuk + öne-aşağı inen sap. SF sembolü önden çizildiği için
    /// profil üstünde yapıştırma gibi duruyordu; bu çizim kafa ile aynı perspektifte.
    private var earPod: some View {
        WornAirPodView(connected: connected)
    }

}

/// Omuzlar: kafa kutusunun boyun tabanından (x 0.112…0.665) aşağı ve dışa doğru genişler.
/// Koordinatlar kafa kutusuna göre; 1.0'ın altı ve 0…1 dışı bilinçli taşma.
struct ShouldersShape: Shape {
    var extent: CGFloat
    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height) }
        var p = Path()
        let b = 1 + extent
        p.move(to: pt(0.112, 0.985))
        p.addCurve(to: pt(-0.34, b), control1: pt(0.06, 1.12), control2: pt(-0.30, 1.16))
        p.addLine(to: pt(1.30, b))
        p.addCurve(to: pt(0.665, 0.985), control1: pt(1.22, 1.14), control2: pt(0.82, 1.10))
        p.closeSubpath()
        return p
    }
}
