import SwiftUI

/// "Düz bak, dokun" kalibrasyonu. Şu anki ham açı sıfır kabul edilir.
struct CalibrationView: View {
    @EnvironmentObject private var motion: HeadMotionService
    @EnvironmentObject private var engine: PostureEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "figure.stand")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            Text("Sit up straight and look ahead")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Hold your head in a comfortable neutral position, then tap the button. Nape measures every tilt from here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !motion.isConnected {
                Label("Put on your AirPods first", systemImage: "airpodspro")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            if !engine.isTracking {
                // Sistem izin penceresinden önce bağlam: neden bildirim istiyoruz
                Label("Next, Nape asks to send notifications so nudges reach your Apple Watch while your iPhone is locked.", systemImage: "bell.badge")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Button {
                engine.calibrate()
                if !engine.isTracking { engine.startTracking() }
                engine.requestNotificationPermission()
                dismiss()
            } label: {
                Text("Set as upright").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!motion.isConnected)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .onAppear { motion.start() }
    }
}
