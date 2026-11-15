import SwiftUI

@main
struct FoliaApp: App {
    @StateObject private var store = WebStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    AudioSession.activate()
                }
        }
    }
}
