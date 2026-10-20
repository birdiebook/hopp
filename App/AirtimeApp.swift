import SwiftUI

@main
struct AirtimeApp: App {
    @State private var store = Store()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
