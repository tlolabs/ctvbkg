import AppKit
import SwiftUI

@main
struct ChabotBackgrounderApp: App {
    @StateObject private var store = BackgrounderStore()

    var body: some Scene {
        WindowGroup("Chabot News Backgrounder") {
            ContentView(store: store)
                .frame(minWidth: 620, minHeight: 560)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Choose Download Folder…") { store.chooseFolder() }
                    .keyboardShortcut("o")
                Button("Refresh") { store.refresh() }
                    .keyboardShortcut("r")
                Button("Toggle Progress Overlay") { store.toggleOverlay() }
                    .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
