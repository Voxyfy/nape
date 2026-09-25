import Foundation

/// Kafa eğim açısından servikal omurga tabanına (C7) binen yaklaşık basınç yükü, kg cinsinden.
///
/// Fizik modeli (statik denge, tek eklemli kaldıraç):
///   - Kafanın ağırlığı m·g; omurga eksenine düşen bileşeni m·g·cos θ.
///   - Kafanın ağırlık merkezi dönme ekseninin L kadar önündedir; eğimde gravite momenti M = m·g·L·sin θ.
///   - Ense ekstansör kasları bu momenti r kaldıraç koluyla karşılar: F_kas = M / r = m·g·(L/r)·sin θ.
///   - Basınç yükü = eksen bileşeni + kas kuvveti = m·g·(cos θ + k·sin θ),  k = L/r.
///
/// k = 4.9, Hansraj (2014) tablosuna en küçük hata ile uydurulmuştur (15°→12, 30°→18, 45°→22, 60°→27 kg;
/// model 12.1 / 17.9 / 21.9 / 25.6 verir). Kafa kütlesi varsayılan 5.4 kg; vücut ağırlığı girilirse
/// Dempster (1955) baş+boyun oranı %8.1 ile kişiselleştirilir.
enum NeckLoad {
    /// Kaldıraç oranı L/r.
    static let leverRatio: Double = 4.9
    /// Kişiselleştirme yoksa kullanılan kafa kütlesi (kg).
    static let defaultHeadMassKg: Double = 5.4
    /// Baş+boyun segmentinin vücut kütlesine oranı (Dempster 1955).
    static let headNeckFraction: Double = 0.081

    static func headMass(bodyWeightKg: Double?) -> Double {
        guard let w = bodyWeightKg, w > 0 else { return defaultHeadMassKg }
        return w * headNeckFraction
    }

    /// Verilen açıda omurgaya binen yük, kg-kuvvet olarak (g sadeleşir).
    static func kilograms(forTilt degrees: Double, headMassKg: Double = defaultHeadMassKg) -> Double {
        let t = max(0, min(90, degrees)) * .pi / 180
        return headMassKg * (cos(t) + leverRatio * sin(t))
    }
}
