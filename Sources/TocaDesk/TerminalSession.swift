import SwiftUI
import SwiftTerm

@MainActor enum TerminalRegistry { static weak var current: LocalProcessTerminalView? }

struct EmbeddedTerminal: NSViewRepresentable {
    let executable: String
    let session: Session
    let onExit: (Int32?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onExit: onExit) }
    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: CGRect(x: 0, y: 0, width: 900, height: 440))
        view.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        view.nativeBackgroundColor = NSColor(calibratedRed: 0.055, green: 0.067, blue: 0.08, alpha: 1)
        view.nativeForegroundColor = NSColor(calibratedWhite: 0.90, alpha: 1)
        view.processDelegate = context.coordinator
        TerminalRegistry.current = view
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = MoleClient.searchPath
        environment["TERM"] = "xterm-256color"
        environment["LANG"] = "en_US.UTF-8"
        view.startProcess(executable: executable, args: session.tool.arguments(preview: session.preview), environment: environment.map { "\($0.key)=\($0.value)" })
        DispatchQueue.main.async { view.window?.makeFirstResponder(view) }
        return view
    }
    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}
    static func dismantleNSView(_ view: LocalProcessTerminalView, coordinator: Coordinator) {
        view.processDelegate = nil
        if view.process.running { view.terminate() }
    }
    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        let onExit: (Int32?) -> Void
        init(onExit: @escaping (Int32?) -> Void) { self.onExit = onExit }
        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func processTerminated(source: TerminalView, exitCode: Int32?) { DispatchQueue.main.async { self.onExit(exitCode) } }
    }
}

struct SessionView: View {
    @EnvironmentObject var model: AppModel
    let session: Session
    @State private var finished = false
    @State private var exitCode: Int32?
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: session.preview ? "eye" : session.tool.symbol).font(.title2).foregroundStyle(.mint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title).font(.title2.bold())
                    Text(session.preview ? "Simulação: o Mole não aplicará esta operação." : (session.tool.mutable ? "Revise as solicitações do Mole antes de confirmar." : "Consulta local, sem alteração de arquivos.")).foregroundStyle(.secondary)
                }
                Spacer()
                if finished { Label(exitCode == 0 ? "Concluído" : "Encerrado · \(exitCode.map(String.init) ?? "erro")", systemImage: exitCode == 0 ? "checkmark.circle" : "exclamationmark.circle") }
                else { ProgressView().controlSize(.small); Text("Em andamento").foregroundStyle(.secondary) }
            }
            if let executable = model.executable {
                EmbeddedTerminal(executable: executable, session: session) { code in finished = true; exitCode = code }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            HStack(spacing: 12) {
                Text("Use ↑ ↓ para navegar, espaço para selecionar e Enter para confirmar.").font(.callout).foregroundStyle(.secondary)
                Spacer()
                if !finished {
                    Button("Interromper") { TerminalRegistry.current?.send(txt: "\u{03}") }
                        .help("Envia Ctrl+C. Aguarde o encerramento antes de fechar.")
                }
                Button("Fechar") { model.session = nil; Task { await model.refresh() } }.disabled(!finished)
            }
        }.padding(24).frame(width: 980, height: 620).interactiveDismissDisabled(!finished)
    }
}
