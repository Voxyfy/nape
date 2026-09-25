import SwiftUI

/// Yarım daire gösterge: 0° solda düz, 60° sağda tam eğik. Eşik çizgisi ve iğne.
struct AngleGauge: View {
    let degrees: Double
    let threshold: Double
    let active: Bool

    private let maxDeg: Double = 60

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let r = w / 2 - 16
            let center = CGPoint(x: w / 2, y: geo.size.height - 30)
            ZStack {
                // Yay zemini
                arc(center: center, r: r, from: 0, to: maxDeg)
                    .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                // Eşik üstü kırmızımsı bölge
                arc(center: center, r: r, from: threshold, to: maxDeg)
                    .stroke(Color.orange.opacity(0.22), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                // Dolu kısım
                if active {
                    arc(center: center, r: r, from: 0, to: clamped)
                        .stroke(clamped >= threshold ? Color.orange : Color.green,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .animation(.easeOut(duration: 0.15), value: clamped)
                }
                // Değer
                VStack(spacing: 2) {
                    Text(active ? "\(Int(clamped.rounded()))°" : "—")
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("forward tilt").font(.caption).foregroundStyle(.secondary)
                }
                .position(x: center.x, y: center.y - r * 0.45)
            }
        }
    }

    private var clamped: Double { max(0, min(maxDeg, degrees)) }

    /// Derece → yay açısı. 0° = 180° (sol), 60° = 0° (sağ).
    private func arc(center: CGPoint, r: CGFloat, from a: Double, to b: Double) -> Path {
        var p = Path()
        let start = Angle.degrees(180 + a / maxDeg * 180)
        let end = Angle.degrees(180 + b / maxDeg * 180)
        p.addArc(center: center, radius: r, startAngle: start, endAngle: end, clockwise: false)
        return p
    }
}
