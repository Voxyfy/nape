import SwiftUI

/// Uygulama girişi. Tüm servisler burada tek sefer kurulur ve ortama enjekte edilir.
@main
struct NapeApp: App {
    @StateObject private var motion: HeadMotionService
    @StateObject private var engine: PostureEngine
    @StateObject private var settings: AppSettings

    init() {
        let motion = HeadMotionService()
        let settings = AppSettings()
        _motion = StateObject(wrappedValue: motion)
        _settings = StateObject(wrappedValue: settings)
        _engine = StateObject(wrappedValue: PostureEngine(motion: motion, settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(motion)
                .environmentObject(engine)
                .environmentObject(settings)
        }
    }
}
