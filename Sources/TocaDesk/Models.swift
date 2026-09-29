import Foundation
import AppKit
import Combine

struct Snapshot: Decodable {
    struct Hardware: Decodable { let model: String; let cpu_model: String; let total_ram: String; let os_version: String }
    struct CPU: Decodable { let usage: Double }
    struct Memory: Decodable { let used: Double; let total: Double; let used_percent: Double }
    struct Disk: Decodable { let mount: String; let used: Double; let total: Double; let used_percent: Double }
    struct Activity: Decodable, Identifiable { var id: Int { pid }; let pid: Int; let name: String; let cpu: Double; let memory_bytes: Double? }
    let host: String
    let uptime: String
    let hardware: Hardware?
    let health_score: Int?
    let health_score_msg: String?
    let cpu: CPU
    let memory: Memory
    let disks: [Disk]
    let top_processes: [Activity]?
}

struct DiskReport: Decodable {
    struct Entry: Decodable, Identifiable {
        var id: String { path }
        let name: String
        let path: String
        let size: Double
        let is_dir: Bool
        let scan_status: String?
    }
    let path: String
    let entries: [Entry]
    let total_size: Double
    let scan_status: String?
}

enum Tool: String, CaseIterable, Identifiable {
    case clean, uninstall, optimize, purge, installer, status, history
    var id: String { rawValue }
    var title: String {
        switch self {
        case .clean: return "Limpeza inteligente"
        case .uninstall: return "Aplicativos"
        case .optimize: return "Otimização"
        case .purge: return "Projetos"
        case .installer: return "Instaladores"
        case .status: return "Monitor ao vivo"
        case .history: return "Histórico do Mole"
        }
    }
    var symbol: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "square.grid.2x2"
        case .optimize: return "slider.horizontal.3"
        case .purge: return "curlybraces"
        case .installer: return "shippingbox"
        case .status: return "waveform.path.ecg"
        case .history: return "clock.arrow.circlepath"
        }
    }
    var description: String {
        switch self {
        case .clean: return "Revise caches, logs e arquivos temporários que podem ser removidos."
        case .uninstall: return "Remova aplicativos junto com os arquivos associados identificados pelo Mole."
        case .optimize: return "Revise tarefas de manutenção de caches e serviços do macOS."
        case .purge: return "Encontre dependências e artefatos de projetos que podem ser reconstruídos."
        case .installer: return "Encontre instaladores antigos que continuam ocupando espaço."
        case .status: return "Acompanhe CPU, memória, bateria e processos em tempo real."
        case .history: return "Consulte o registro das operações realizadas pelo Mole."
        }
    }
    var mutable: Bool { self != .status && self != .history }
    func arguments(preview: Bool) -> [String] { [rawValue] + (preview && mutable ? ["--dry-run"] : []) }
}

struct Session: Identifiable {
    let id = UUID()
    let tool: Tool
    let preview: Bool
    var title: String { preview ? "Prévia · \(tool.title)" : tool.title }
}

func bytes(_ value: Double) -> String {
    guard value.isFinite, value >= 0, value < Double(Int64.max) else { return "Indisponível" }
    return ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
}

enum MoleError: LocalizedError {
    case missing, failed(String), timeout
    var errorDescription: String? {
        switch self {
        case .missing: return "Mole não encontrado. Instale o CLI ou selecione o executável mo nos ajustes."
        case .failed(let message): return message
        case .timeout: return "A consulta demorou mais que o esperado. Tente novamente ou selecione uma pasta menor."
        }
    }
}

struct MoleClient {
    static let searchPath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    static func locate(custom: String = "") -> String? {
        let candidates = [custom, "/opt/homebrew/bin/mo", "/usr/local/bin/mo", NSHomeDirectory() + "/.local/bin/mo", "/Library/Application Support/TocaDesk/CLI/mo"]
        return candidates.first { !$0.isEmpty && FileManager.default.isExecutableFile(atPath: $0) }
    }
    // Arguments are passed directly, never interpolated into a shell command.
    static func query(executable: String, arguments: [String], timeout: Double = 30) async throws -> Data {
        try await Task.detached(priority: .utility) {
            try blockingQuery(executable: executable, arguments: arguments, timeout: timeout)
        }.value
    }
    private static func blockingQuery(executable: String, arguments: [String], timeout: Double) throws -> Data {
            let process = Process()
            let output = Pipe()
            let error = Pipe()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = searchPath
            environment["NO_COLOR"] = "1"
            process.environment = environment
            process.standardOutput = output
            process.standardError = error
            process.standardInput = FileHandle.nullDevice
            // Drain both streams concurrently, avoiding full-pipe deadlocks.
            let group = DispatchGroup()
            let buffer = OutputBuffer()
            try process.run()
            group.enter()
            DispatchQueue.global().async { buffer.output = output.fileHandleForReading.readDataToEndOfFile(); group.leave() }
            group.enter()
            DispatchQueue.global().async { buffer.error = error.fileHandleForReading.readDataToEndOfFile(); group.leave() }
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.1) }
            if process.isRunning {
                process.terminate()
                Thread.sleep(forTimeInterval: 0.3)
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                throw MoleError.timeout
            }
            group.wait()
            guard process.terminationStatus == 0 else {
                throw MoleError.failed(String(data: buffer.error, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "O Mole encerrou a consulta com código \(process.terminationStatus).")
            }
            return buffer.output
    }
}
private final class OutputBuffer: @unchecked Sendable { var output = Data(); var error = Data() }
private extension String { var nilIfEmpty: String? { isEmpty ? nil : self } }

@MainActor final class AppModel: ObservableObject {
    @Published var snapshot: Snapshot?
    @Published var updated: Date?
    @Published var loading = false
    @Published var error: String?
    @Published var executable: String?
    @Published var session: Session?
    @Published var report: DiskReport?
    @Published var scanning = false
    @Published var scanError: String?
    @Published var version = ""
    init() { executable = MoleClient.locate(custom: UserDefaults.standard.string(forKey: "molePath") ?? "") }
    func refresh() async {
        guard !loading else { return }
        guard let executable else { error = MoleError.missing.localizedDescription; return }
        loading = true
        defer { loading = false }
        do {
            let data = try await MoleClient.query(executable: executable, arguments: ["status", "--json"])
            snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            updated = Date(); error = nil
        } catch { self.error = error.localizedDescription }
    }
    func scan(_ path: String) async {
        guard !scanning, let executable else { return }
        scanning = true; scanError = nil; report = nil
        defer { scanning = false }
        do {
            let data = try await MoleClient.query(executable: executable, arguments: ["analyze", "--json", path], timeout: 180)
            report = try JSONDecoder().decode(DiskReport.self, from: data)
        } catch { scanError = error.localizedDescription }
    }
    func selectExecutable() {
        let panel = NSOpenPanel()
        panel.title = "Selecione o executável mo"
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            guard FileManager.default.isExecutableFile(atPath: url.path) else { error = "Selecione um arquivo executável válido."; return }
            UserDefaults.standard.set(url.path, forKey: "molePath")
            executable = url.path
            Task { await refresh() }
        }
    }
}
