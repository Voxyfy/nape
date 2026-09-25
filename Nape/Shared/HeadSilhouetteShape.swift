import SwiftUI

/// Gerçek insan profili silüeti. Kullanıcının verdiği görselden potrace ile vektörleştirildi,
/// koordinatlar 0…1 aralığına normalize edildi; en/boy oranı 0.8912.
struct HeadSilhouetteShape: Shape {
    static let aspect: CGFloat = 0.8912
    /// Boyun tabanının yatay konumu (0…1); kafa bu noktadan döner.
    static let neckBaseX: CGFloat = 0.4053

    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var p = Path()
        p.move(to: pt(0.4068, 0.0246))
        p.addCurve(to: pt(0.1404, 0.1293), control1: pt(0.2978, 0.0371), control2: pt(0.2081, 0.0722))
        p.addCurve(to: pt(0.0562, 0.5131), control1: pt(0.0307, 0.2217), control2: pt(0.0000, 0.3617))
        p.addCurve(to: pt(0.1149, 0.6139), control1: pt(0.0720, 0.5560), control2: pt(0.0745, 0.5605))
        p.addCurve(to: pt(0.1770, 0.7409), control1: pt(0.1655, 0.6814), control2: pt(0.1770, 0.7047))
        p.addCurve(to: pt(0.1630, 0.8713), control1: pt(0.1770, 0.7658), control2: pt(0.1696, 0.8350))
        p.addCurve(to: pt(0.1379, 0.9936), control1: pt(0.1568, 0.9059), control2: pt(0.1404, 0.9853))
        p.addCurve(to: pt(0.4059, 1.0000), control1: pt(0.1360, 1.0000), control2: pt(0.1360, 1.0000))
        p.addCurve(to: pt(0.6795, 0.9784), control1: pt(0.6761, 1.0000), control2: pt(0.6761, 1.0000))
        p.addCurve(to: pt(0.7050, 0.8957), control1: pt(0.6854, 0.9449), control2: pt(0.6947, 0.9145))
        p.addCurve(to: pt(0.8006, 0.8777), control1: pt(0.7146, 0.8785), control2: pt(0.7146, 0.8785))
        p.addCurve(to: pt(0.9047, 0.8694), control1: pt(0.8866, 0.8768), control2: pt(0.8866, 0.8768))
        p.addCurve(to: pt(0.9394, 0.7883), control1: pt(0.9332, 0.8575), control2: pt(0.9394, 0.8428))
        p.addCurve(to: pt(0.9531, 0.7315), control1: pt(0.9394, 0.7465), control2: pt(0.9394, 0.7465))
        p.addCurve(to: pt(0.9652, 0.7016), control1: pt(0.9658, 0.7171), control2: pt(0.9665, 0.7155))
        p.addCurve(to: pt(0.9556, 0.6795), control1: pt(0.9640, 0.6908), control2: pt(0.9618, 0.6853))
        p.addCurve(to: pt(0.9627, 0.6551), control1: pt(0.9447, 0.6695), control2: pt(0.9447, 0.6704))
        p.addCurve(to: pt(0.9680, 0.6081), control1: pt(0.9829, 0.6385), control2: pt(0.9842, 0.6252))
        p.addCurve(to: pt(0.9578, 0.5644), control1: pt(0.9429, 0.5818), control2: pt(0.9407, 0.5715))
        p.addCurve(to: pt(0.9764, 0.5599), control1: pt(0.9637, 0.5619), control2: pt(0.9720, 0.5599))
        p.addCurve(to: pt(1.0000, 0.5336), control1: pt(0.9898, 0.5599), control2: pt(1.0000, 0.5486))
        p.addCurve(to: pt(0.9522, 0.4644), control1: pt(1.0000, 0.5134), control2: pt(0.9879, 0.4957))
        p.addCurve(to: pt(0.8901, 0.3164), control1: pt(0.8972, 0.4163), control2: pt(0.8870, 0.3919))
        p.addCurve(to: pt(0.8714, 0.2098), control1: pt(0.8922, 0.2588), control2: pt(0.8901, 0.2455))
        p.addCurve(to: pt(0.4068, 0.0246), control1: pt(0.7997, 0.0714), control2: pt(0.6205, 0.0000))
        p.closeSubpath()
        return p
    }
}
