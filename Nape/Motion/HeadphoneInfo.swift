import Foundation
import AVFoundation
import UIKit

/// Takılı kulaklığın adı ve ona uyan SF Symbol. CoreMotion model bilgisi vermez;
/// ses yolundaki port adından ("Batuhan's AirPods Pro") tahmin edilir.
struct HeadphoneInfo {
    let name: String
    let symbol: String

    static func current() -> HeadphoneInfo? {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        guard let port = outputs.first(where: { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE }) else { return nil }
        return HeadphoneInfo(name: port.portName, symbol: symbol(for: port.portName))
    }

    /// Ada göre sembol; bulunamayan sembol için eski nesle düş.
    static func symbol(for name: String) -> String {
        let n = name.lowercased()
        let candidates: [String]
        if n.contains("max") { candidates = ["airpods.max", "airpodsmax"] }
        else if n.contains("pro") { candidates = ["airpods.pro", "airpodspro"] }
        else if n.contains("beats") { candidates = ["beats.fitpro", "beats.headphones", "headphones"] }
        else { candidates = ["airpods.gen4", "airpods.gen3", "airpods"] }
        return candidates.first { UIImage(systemName: $0) != nil } ?? "airpods"
    }

    /// Kulaklık yokken gösterilecek varsayılan sembol.
    static var placeholderSymbol: String { symbol(for: "airpods") }
}
