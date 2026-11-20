import SwiftUI

@main
struct MedMinderApp: App {
    @StateObject private var storage = StorageService.shared
    @StateObject private var language = LanguageManager.shared
    
    init() {
        NotificationManager.shared.requestAuthorization { granted in
            print("MedMinder notifications granted: \(granted)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(storage)
                .environmentObject(language)
        }
    }
}
