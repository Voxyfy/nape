import Foundation
import AVFoundation
import UIKit

/// Uyarı çıkışı: iPhone'da haptik, kulaklıkta seçili ses.
/// Watch geldiğinde haptik oraya taşınacak, bu sınıfın arayüzü değişmez.
final class Alerter {
    private var players: [NudgeSound: AVAudioPlayer] = [:]

    init() {
        // Beş dosya küçük; hepsini baştan yükleyip gecikmesiz çalıyoruz.
        for s in NudgeSound.allCases {
            if let url = Bundle.main.url(forResource: s.fileName, withExtension: "wav"),
               let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                players[s] = p
            }
        }
    }

    /// level 1…3: kaç kez çalınacağı ve haptik sertliği. Kademe kapalıysa her zaman 1.
    func nudge(haptic: Bool, sound: Bool, which: NudgeSound, level: Int) {
        let n = max(1, min(3, level))
        if haptic {
            let gen = UINotificationFeedbackGenerator()
            gen.prepare()
            gen.notificationOccurred(n == 1 ? .warning : .error)
            if n == 3 {
                // Üçüncü kademede iki vuruş
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { gen.notificationOccurred(.error) }
            }
        }
        guard sound, let p = players[which] else { return }
        let gap = p.duration + 0.18
        for i in 0..<n {
            DispatchQueue.main.asyncAfter(deadline: .now() + gap * Double(i)) { [weak self] in self?.play(which) }
        }
    }

    /// Ayarlar ekranındaki önizleme için.
    func play(_ s: NudgeSound) {
        guard let p = players[s] else { return }
        p.currentTime = 0
        p.play()
    }
}
