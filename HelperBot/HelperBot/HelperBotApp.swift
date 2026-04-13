import SwiftUI

@main
struct HelperBotApp: App {
    @StateObject private var store = ChecklistStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
