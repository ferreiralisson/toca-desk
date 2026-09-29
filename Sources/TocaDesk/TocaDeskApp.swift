import SwiftUI
import AppKit

@main struct TocaDeskApp: App {
    @StateObject private var model = AppModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup("Toca Desk") {
            ContentView().environmentObject(model)
                .frame(minWidth: 1000, minHeight: 720)
                .tint(.mint)
        }
        .defaultSize(width: 1180, height: 820)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .toolbar) {
                Button("Atualizar painel") { Task { await model.refresh() } }.keyboardShortcut("r")
            }
        }
    }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard TerminalRegistry.current?.process.running == true else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Uma operação está em andamento"
        alert.informativeText = "Encerre a operação na sessão antes de sair para evitar uma interrupção incompleta."
        alert.addButton(withTitle: "Voltar à operação")
        alert.runModal()
        return .terminateCancel
    }
}
