import SwiftUI
import UniformTypeIdentifiers

enum Destination: Hashable {
    case overview, storage, settings, tool(Tool)
    var title: String {
        switch self {
        case .overview: return "Visão geral"
        case .storage: return "Armazenamento"
        case .settings: return "Ajustes"
        case .tool(let tool): return tool.title
        }
    }
}

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @AppStorage(AppearancePreference.style) private var style = InterfaceStyle.liquidGlass
    @AppStorage(AppearancePreference.tint) private var accentTint = true
    @State private var selection: Destination? = .overview

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    switch selection ?? .overview {
                    case .overview: OverviewView(selection: $selection)
                    case .storage: DiskView()
                    case .settings: SettingsView()
                    case .tool(let tool): ToolView(tool: tool)
                    }
                }
                .padding(30)
                .frame(maxWidth: 1080, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .safeAreaInset(edge: .top, spacing: 0) { WorkspaceControls() }
            .navigationTitle(selection?.title ?? "Visão geral")
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.interfaceStyle, style)
        .environment(\.glassAccentTint, accentTint)
        .sheet(item: $model.session) { SessionView(session: $0) }
        .task { await model.refresh() }
    }
}

struct SidebarView: View {
    @Binding var selection: Destination?
    private static let tools = Tool.allCases.filter { $0 != .history }
    var body: some View {
        List(selection: $selection) {
            Section {
                NavigationLink(value: Destination.overview) { Label("Visão geral", systemImage: "square.grid.2x2") }
                NavigationLink(value: Destination.storage) { Label("Armazenamento", systemImage: "internaldrive") }
            }
            Section("Ferramentas") {
                ForEach(Self.tools) { tool in
                    NavigationLink(value: Destination.tool(tool)) { Label { Text(tool.title) } icon: { Image(systemName: tool.symbol) } }
                }
            }
            Section {
                NavigationLink(value: Destination.tool(.history)) { Label("Histórico", systemImage: "clock.arrow.circlepath") }
                NavigationLink(value: Destination.settings) { Label("Ajustes", systemImage: "gearshape") }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top) { SidebarBrand() }
        .safeAreaInset(edge: .bottom) {
            Label("Local. Sob seu controle.", systemImage: "lock.shield")
                .font(.caption).foregroundStyle(.secondary).padding(18)
        }
        .navigationTitle("Toca Desk")
    }
}
struct SidebarBrand: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill").font(.title2).foregroundStyle(TocaTheme.accent)
                .frame(width: 42, height: 42).background(TocaTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 3) {
                Text("Toca Desk").font(.title3.bold())
                Text("Um respiro para seu Mac").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }.padding(.horizontal, 18).padding(.vertical, 20)
    }
}
struct WorkspaceControls: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        GlassControlGroup(spacing: 12) {
            HStack(spacing: 12) {
                Label("Seu Mac, bem cuidado", systemImage: "leaf").font(.callout).foregroundStyle(.secondary)
                Spacer()
                ConnectionBadge(connected: model.executable != nil)
                NativeActionButton(action: { Task { await model.refresh() } }) {
                    Label("Atualizar", systemImage: "arrow.clockwise")
                }
                .disabled(model.loading)
                .help("Atualizar painel · ⌘R")
                .accessibilityLabel("Atualizar painel")
            }
        }
        .padding(.horizontal, 30).padding(.vertical, 16)
    }
}

struct OverviewView: View {
    @Environment(AppModel.self) private var model
    @Binding var selection: Destination?
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            PageTitle(title: "Mais leve. Mais seu.", subtitle: "Um lugar tranquilo para cuidar do seu Mac.")
            if let error = model.error { Notice(text: error, icon: "exclamationmark.triangle", color: .orange) }
            HealthCard(hardware: model.snapshot?.hardware, score: model.snapshot?.health_score, message: model.snapshot?.health_score_msg, updated: model.updated, loading: model.loading)
            MetricsView(cpu: model.snapshot?.cpu.usage, memory: model.snapshot?.memory, disk: model.snapshot?.disks.first { $0.mount == "/" })
            Text("Por onde começar").font(.title3.bold())
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                ActionCard(tool: .clean, note: "Comece com uma prévia", color: TocaTheme.accent) { selection = .tool(.clean) }
                ActionCard(tool: .uninstall, note: "Fique com o essencial", color: .blue) { selection = .tool(.uninstall) }
                ActionCard(tool: .purge, note: "Espaço para criar", color: .orange) { selection = .tool(.purge) }
            }
            ActivityCard(activities: Array((model.snapshot?.top_processes ?? []).prefix(4)))
            Label("Nenhuma limpeza é iniciada automaticamente.", systemImage: "checkmark.shield")
                .font(.callout).foregroundStyle(.secondary)
        }
    }
}
struct HealthCard: View {
    let hardware: Snapshot.Hardware?
    let score: Int?
    let message: String?
    let updated: Date?
    let loading: Bool
    var body: some View {
        HStack(spacing: 26) {
            HealthGauge(score: score)
            VStack(alignment: .leading, spacing: 9) {
                Text(hardware?.model ?? "Conheça seu Mac").font(.title2.bold())
                Text(hardware.map { "\($0.cpu_model)  ·  \($0.total_ram)  ·  \($0.os_version)" } ?? "As informações do sistema aparecerão aqui.")
                    .font(.callout).foregroundStyle(.secondary)
                if let message { Text(message).font(.callout).foregroundStyle(.secondary) }
                if let updated { Text("Atualizado às \(updated.formatted(date: .omitted, time: .shortened))").font(.caption).foregroundStyle(.secondary) }
                if loading { ProgressView().controlSize(.small).accessibilityLabel("Consultando o sistema") }
            }
            Spacer(minLength: 0)
        }.tocaCard(padding: 28)
    }
}
struct HealthGauge: View {
    let score: Int?
    var body: some View {
        ZStack {
            Circle().stroke(TocaTheme.accent.opacity(0.16), lineWidth: 9)
            Circle().trim(from: 0, to: Double(min(100, max(0, score ?? 0))) / 100)
                .stroke(TocaTheme.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(score.map(String.init) ?? "—").font(.system(size: 36, weight: .medium, design: .rounded))
                Text("Saúde").font(.caption).foregroundStyle(.secondary)
            }
        }.frame(width: 108, height: 108)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Saúde do sistema")
            .accessibilityValue(score.map { "\($0) de 100" } ?? "Indisponível")
    }
}
struct MetricsView: View {
    let cpu: Double?
    let memory: Snapshot.Memory?
    let disk: Snapshot.Disk?
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 160), spacing: 16), count: 3), spacing: 16) {
            MetricCard(title: "CPU", icon: "cpu", value: cpu.map { String(format: "%.0f%%", $0) } ?? "—", detail: "Uso do processador", percent: cpu, color: TocaTheme.accent)
            MetricCard(title: "Memória", icon: "memorychip", value: memory.map { bytes($0.used) } ?? "—", detail: memory.map { "de \(bytes($0.total)) no total" } ?? "Aguardando leitura", percent: memory?.used_percent, color: .purple)
            MetricCard(title: "Espaço livre", icon: "internaldrive", value: disk.map { bytes(max(0, $0.total - $0.used)) } ?? "—", detail: disk.map { "\(bytes($0.used)) em uso" } ?? "Aguardando leitura", percent: disk?.used_percent, color: .blue)
        }
    }
}
struct ActionCard: View {
    let tool: Tool
    let note: LocalizedStringKey
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: tool.symbol).font(.title2).foregroundStyle(color)
                    Spacer()
                    Image(systemName: "arrow.up.right").foregroundStyle(.secondary)
                }
                Text(tool.title).font(.headline)
                Text(tool.description).font(.callout).foregroundStyle(.secondary).lineSpacing(3)
                    .frame(minHeight: 58, alignment: .top)
                Text(note).font(.caption.bold()).foregroundStyle(color)
            }.frame(minWidth: 160, maxWidth: .infinity, alignment: .leading).tocaCard()
        }.buttonStyle(.plain).accessibilityHint("Abrir ferramenta e revisar a prévia")
    }
}
struct ActivityCard: View {
    let activities: [Snapshot.Activity]
    var body: some View {
        if !activities.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text("Em atividade agora").font(.headline); Spacer(); Text("CPU").font(.caption).foregroundStyle(.secondary) }
                ForEach(activities) { process in
                    ActivityRow(name: process.name, cpu: process.cpu)
                }
            }.tocaCard()
        }
    }
}
struct ActivityRow: View {
    let name: String
    let cpu: Double
    var body: some View {
        HStack {
            Image(systemName: "app.dashed").foregroundStyle(.secondary)
            Text(name).lineLimit(1)
            Spacer()
            Text(cpu / 100, format: .percent.precision(.fractionLength(1))).monospacedDigit().foregroundStyle(.secondary)
        }.font(.callout).accessibilityElement(children: .combine)
    }
}

struct SettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(title: "Do seu jeito.", subtitle: "Aparência e conexão com as ferramentas do seu Mac.")
            AppearanceSettings()
            MoleSettings()
            AboutCard()
        }
    }
}
struct AppearanceSettings: View {
    @AppStorage(AppearancePreference.style) private var style = InterfaceStyle.liquidGlass
    @AppStorage(AppearancePreference.tint) private var accentTint = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Aparência", systemImage: "paintpalette").font(.headline)
            Picker("Estilo dos controles", selection: $style) {
                ForEach(InterfaceStyle.allCases) { option in Text(option.title).tag(option) }
            }.pickerStyle(.segmented).frame(maxWidth: 380)
            Toggle("Usar a cor verde nos controles de vidro", isOn: $accentTint)
                .disabled(style == .classic)
            if #available(macOS 26, *) {
                Text("Liquid Glass usa o material nativo do macOS na faixa de controles e nos botões. Métricas e listas mantêm superfícies legíveis.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Text("Liquid Glass requer macOS 26 ou posterior. Neste Mac, os controles usam a aparência clássica.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            if reduceTransparency || contrast == .increased {
                Label("As preferências de acessibilidade do macOS têm prioridade sobre a transparência.", systemImage: "accessibility")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }.tocaCard()
    }
}
struct MoleSettings: View {
    @Environment(AppModel.self) private var model
    @State private var showExecutablePicker = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Instalação do Mole", systemImage: "link").font(.headline)
            Text(model.executable ?? "Não encontrado").font(.system(.callout, design: .monospaced)).textSelection(.enabled)
            NativeActionButton(action: { showExecutablePicker = true }) { Label("Selecionar executável…", systemImage: "folder") }
            Text("Homebrew, ~/.local/bin e o CLI incluído pelo instalador são detectados automaticamente.")
                .font(.callout).foregroundStyle(.secondary)
            if let error = model.error { Notice(text: error, icon: "exclamationmark.triangle", color: .orange) }
        }.tocaCard()
        .fileImporter(isPresented: $showExecutablePicker, allowedContentTypes: [.item]) { result in
            if case .success(let url) = result { model.selectExecutable(url) }
        }
    }
}
struct AboutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Feito para ficar no seu Mac", systemImage: "lock.shield").font(.headline)
            Text("Sem conta, anúncios ou telemetria. As consultas e operações são executadas localmente pelo CLI instalado.")
            Text("Toca Desk é uma interface independente e não é o aplicativo oficial Mole for Mac. O Mole e o SwiftTerm pertencem aos seus respectivos autores.")
                .foregroundStyle(.secondary)
            Link("Conhecer o projeto Mole", destination: URL(string: "https://github.com/tw93/mole")!)
            Link("SwiftTerm · licença MIT", destination: URL(string: "https://github.com/migueldeicaza/SwiftTerm")!)
        }.font(.callout).tocaCard()
    }
}

struct ToolView: View {
    @Environment(AppModel.self) private var model
    let tool: Tool
    @State private var confirm = false
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            PageTitle(title: LocalizedStringKey(tool.title), subtitle: LocalizedStringKey(tool.description))
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: tool.symbol).font(.system(size: 40, weight: .light)).foregroundStyle(TocaTheme.accent)
                    .padding(20).background(TocaTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                Text(tool.mutable ? "Primeiro, veja o que pode mudar." : "Tudo à vista, em um só lugar.").font(.title2.bold())
                Text(tool.mutable ? "A prévia executa uma simulação do Mole. Revise os resultados e, quando estiver pronto, inicie a operação. A seleção e as confirmações acontecem na sessão integrada." : "Abra a sessão integrada para consultar as informações diretamente no Mole.")
                    .foregroundStyle(.secondary).lineSpacing(5)
                GlassControlGroup(spacing: 14) {
                    HStack(spacing: 14) {
                        if tool.mutable {
                            NativeActionButton(prominent: true, action: { model.session = Session(tool: tool, preview: true) }) {
                                Label("Visualizar prévia", systemImage: "eye")
                            }
                            NativeActionButton(action: { confirm = true }) { Label("Iniciar operação…", systemImage: "play") }
                        } else {
                            NativeActionButton(prominent: true, action: { model.session = Session(tool: tool, preview: false) }) {
                                Label("Abrir sessão", systemImage: "terminal")
                            }
                        }
                    }.controlSize(.large).disabled(model.executable == nil)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).tocaCard(padding: 30)
            Notice(text: tool.mutable ? "A operação pode modificar ou excluir arquivos. O Mole poderá solicitar sua senha de administrador na sessão, apenas quando necessário." : "Esta ferramenta apenas consulta informações.", icon: "checkmark.shield", color: TocaTheme.accent)
            if model.executable == nil { Notice(text: "Conecte o Mole em Ajustes para continuar.", icon: "exclamationmark.triangle", color: .orange) }
        }
        .confirmationDialog("Iniciar \(tool.title.lowercased())?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Iniciar operação", role: .destructive) { model.session = Session(tool: tool, preview: false) }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação pode alterar ou excluir arquivos. Revise a prévia e confirme as seleções solicitadas pelo Mole na sessão.")
        }
    }
}

struct DiskView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var showFolderPicker = false
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(title: "Espaço para o que importa.", subtitle: "Explore suas pastas e descubra onde seu armazenamento está sendo usado.")
            GlassControlGroup(spacing: 14) {
                HStack(spacing: 14) {
                    NativeActionButton(prominent: true, action: { showFolderPicker = true }) { Label("Escolher pasta", systemImage: "folder.badge.plus") }
                    NativeActionButton(action: { Task { await model.scan(NSHomeDirectory() + "/Downloads") } }) { Text("Analisar Downloads") }
                    Spacer()
                    if model.scanning { ProgressView().controlSize(.small); Text("Analisando…").foregroundStyle(.secondary) }
                }.disabled(model.scanning || model.executable == nil)
            }
            if let error = model.scanError { Notice(text: error, icon: "exclamationmark.triangle", color: .orange) }
            if let report = model.report {
                DiskReportView(report: report, entries: model.sortedEntries, query: $query)
            } else if !model.scanning {
                StorageEmptyState()
            }
        }
        .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                Task {
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    await model.scan(url.path)
                }
            }
        }
    }
}
struct DiskReportView: View {
    let report: DiskReport
    let entries: [DiskReport.Entry]
    @Binding var query: String
    var body: some View {
        let filtered = entries.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(bytes(report.total_size)).font(.largeTitle.bold())
                    Text(report.path).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Spacer()
                Text("\(filtered.count) itens").foregroundStyle(.secondary)
            }
            if report.scan_status != "complete" { Notice(text: "A leitura pode ser parcial. Pastas sem permissão ou ignoradas pelo Mole podem não estar incluídas no total.", icon: "info.circle", color: .orange) }
            TextField("Filtrar por nome", text: $query).textFieldStyle(.roundedBorder)
            LazyVStack(spacing: 4) {
                ForEach(filtered) { entry in StorageRow(entry: entry, totalSize: report.total_size) }
            }
            if filtered.isEmpty { Text("Nenhum item encontrado.").foregroundStyle(.secondary).padding(.vertical) }
        }.tocaCard()
    }
}
struct StorageRow: View {
    @Environment(AppModel.self) private var model
    let entry: DiskReport.Entry
    let totalSize: Double
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.is_dir ? "folder.fill" : "doc.fill")
                .foregroundStyle(entry.is_dir ? Color.blue : .gray).font(.title3)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(entry.name).lineLimit(1)
                    if entry.scan_status == "partial" || entry.scan_status == "unavailable" { Text("Leitura parcial").font(.caption).foregroundStyle(.orange) }
                }
                UsageBar(fraction: entry.size / max(1, totalSize), color: TocaTheme.accent)
            }
            Text(entry.scan_status == "unavailable" ? "Indisponível" : bytes(entry.size))
                .font(.callout).monospacedDigit().frame(width: 100, alignment: .trailing)
            Button { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.path)]) } label: { Image(systemName: "arrow.up.forward.square") }
                .help("Mostrar no Finder").accessibilityLabel("Mostrar \(entry.name) no Finder")
            if entry.is_dir {
                Button { Task { await model.scan(entry.path) } } label: { Image(systemName: "chevron.right") }
                    .disabled(model.scanning).help("Explorar pasta").accessibilityLabel("Explorar \(entry.name)")
            }
        }.padding(.vertical, 10)
    }
}
struct StorageEmptyState: View {
    var body: some View {
        ContentUnavailableView("Vamos olhar com calma.", systemImage: "internaldrive",
                               description: Text("Escolha uma pasta para começar. A análise não remove arquivos."))
            .frame(maxWidth: .infinity).padding(.vertical, 55).tocaCard()
    }
}
struct MetricCard: View {
    let title: LocalizedStringKey
    let icon: String
    let value: String
    let detail: String
    let percent: Double?
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text(title).font(.callout.bold()); Spacer(); Image(systemName: icon).foregroundStyle(color) }
            Text(value).font(.system(size: 29, weight: .semibold, design: .rounded))
            UsageBar(fraction: (percent ?? 0) / 100, color: color)
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).tocaCard()
    }
}
struct UsageBar: View {
    let fraction: Double
    let color: Color
    var body: some View {
        GeometryReader { geometry in
            Capsule().fill(color).frame(width: geometry.size.width * (fraction.isFinite ? min(1, max(0, fraction)) : 0))
        }.frame(height: 5).background(.quaternary, in: Capsule()).accessibilityHidden(true)
    }
}
struct PageTitle: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 32, weight: .bold, design: .rounded))
            Text(subtitle).foregroundStyle(.secondary).lineSpacing(4)
        }
    }
}
struct Notice: View {
    let text: String
    let icon: String
    let color: Color
    var body: some View {
        Label { Text(text).font(.callout).lineSpacing(3) } icon: { Image(systemName: icon).foregroundStyle(color) }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityElement(children: .combine)
    }
}
