import SwiftUI

private let accent = Color(red: 0.20, green: 0.72, blue: 0.56)

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    @State private var selection = "overview"
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 225)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Label("SEU MAC, BEM CUIDADO", systemImage: "leaf").font(.system(size: 10, weight: .semibold, design: .rounded)).tracking(2).foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle().fill(model.executable == nil ? .orange : accent).frame(width: 6, height: 6)
                            Text(model.executable == nil ? "Mole não encontrado" : "Mole conectado").font(.caption)
                        }.padding(.horizontal, 12).padding(.vertical, 7).background(.quaternary.opacity(0.4), in: Capsule())
                    }
                    if selection == "overview" { overview }
                    else if selection == "disk" { DiskView() }
                    else if selection == "settings" { settings }
                    else if let tool = Tool(rawValue: selection) { ToolView(tool: tool) }
                }.padding(36)
            }.background(Color(nsColor: .windowBackgroundColor))
        }
        .sheet(item: $model.session) { SessionView(session: $0).environmentObject(model) }
        .task { await model.refresh() }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill").font(.title2).foregroundStyle(accent).frame(width: 36, height: 36).background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 1) { Text("Toca Desk").font(.system(size: 21, weight: .bold, design: .rounded)); Text("Um respiro para o seu Mac").font(.system(size: 9)).foregroundStyle(.secondary) }
            }.padding(.bottom, 32).padding(.top, 22)
            nav("Visão geral", "square.grid.2x2", "overview")
            nav("Armazenamento", "internaldrive", "disk")
            Text("FERRAMENTAS").font(.system(size: 9, weight: .semibold)).tracking(1.8).foregroundStyle(.tertiary).padding(.top, 24).padding(.bottom, 8).padding(.leading, 12)
            ForEach(Tool.allCases.filter { $0 != .history }) { tool in nav(tool.title, tool.symbol, tool.rawValue) }
            Spacer(minLength: 30)
            nav("Histórico", "clock.arrow.circlepath", "history")
            nav("Ajustes", "gearshape", "settings")
            Divider().padding(.vertical, 10)
            Label("Local. Privado. Sob seu controle.", systemImage: "lock.shield").font(.system(size: 10)).foregroundStyle(.secondary).padding(.bottom, 16)
        }.padding(.horizontal, 16).background(.ultraThinMaterial)
    }
    private func nav(_ title: String, _ icon: String, _ id: String) -> some View {
        Button { selection = id } label: {
            HStack(spacing: 11) { Image(systemName: icon).frame(width: 19); Text(title).font(.system(size: 12, weight: selection == id ? .semibold : .regular)); Spacer() }
                .foregroundStyle(selection == id ? accent : Color.primary.opacity(0.7)).padding(.horizontal, 12).padding(.vertical, 11)
                .background(selection == id ? accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 9))
        }.buttonStyle(.plain).accessibilityAddTraits(selection == id ? .isSelected : [])
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mais leve. Mais seu.").font(.system(size: 33, weight: .bold, design: .rounded))
                    Text("Um lugar tranquilo para cuidar do seu Mac.").foregroundStyle(.secondary)
                }
                Spacer()
                Button { Task { await model.refresh() } } label: { Image(systemName: "arrow.clockwise").padding(5) }.disabled(model.loading).help("Atualizar métricas · ⌘R")
            }
            if let error = model.error { Notice(text: error, icon: "exclamationmark.triangle", color: .orange) }
            HStack(spacing: 26) {
                ZStack {
                    Circle().stroke(accent.opacity(0.16), lineWidth: 9)
                    Circle().trim(from: 0, to: Double(model.snapshot?.health_score ?? 0) / 100).stroke(accent, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 1) { Text(model.snapshot?.health_score.map(String.init) ?? "—").font(.system(size: 36, weight: .medium, design: .rounded)); Text("SAÚDE").font(.system(size: 8, weight: .bold)).tracking(2).foregroundStyle(.secondary) }
                }.frame(width: 105, height: 105).accessibilityElement(children: .ignore).accessibilityLabel("Saúde do sistema: \(model.snapshot?.health_score.map(String.init) ?? "indisponível") de 100")
                VStack(alignment: .leading, spacing: 9) {
                    Text(model.snapshot?.hardware?.model ?? "Conheça seu Mac").font(.title2.bold())
                    Text(model.snapshot?.hardware.map { "\($0.cpu_model)  ·  \($0.total_ram)  ·  \($0.os_version)" } ?? "As informações do sistema aparecerão aqui.").font(.callout).foregroundStyle(.secondary)
                    if let message = model.snapshot?.health_score_msg { Text(message).font(.caption).foregroundStyle(.secondary) }
                    if let updated = model.updated { Text("Atualizado às \(updated.formatted(date: .omitted, time: .shortened))").font(.caption2).foregroundStyle(.tertiary) }
                    if model.loading { ProgressView().controlSize(.small) }
                }
                Spacer()
            }.padding(28).frame(maxWidth: .infinity, alignment: .leading).background(accent.opacity(0.055), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(accent.opacity(0.16)))
            HStack(spacing: 14) {
                MetricCard(title: "CPU", icon: "cpu", value: model.snapshot.map { String(format: "%.0f%%", $0.cpu.usage) } ?? "—", detail: "Uso do processador", percent: model.snapshot?.cpu.usage, color: accent)
                MetricCard(title: "MEMÓRIA", icon: "memorychip", value: model.snapshot.map { bytes($0.memory.used) } ?? "—", detail: model.snapshot.map { "de \(bytes($0.memory.total)) no total" } ?? "Aguardando leitura", percent: model.snapshot?.memory.used_percent, color: .purple)
                MetricCard(title: "ESPAÇO LIVRE", icon: "internaldrive", value: disk.map { bytes(max(0, $0.total - $0.used)) } ?? "—", detail: disk.map { "\(bytes($0.used)) em uso" } ?? "Aguardando leitura", percent: disk?.used_percent, color: .blue)
            }
            HStack { Text("Um pouco de cuidado faz diferença").font(.headline); Spacer(); Text("POR ONDE COMEÇAR").font(.system(size: 9, weight: .medium)).tracking(1).foregroundStyle(.tertiary) }
            HStack(alignment: .top, spacing: 14) {
                actionCard(.clean, note: "COMECE COM UMA PRÉVIA", color: accent)
                actionCard(.uninstall, note: "FIQUE COM O ESSENCIAL", color: .blue)
                actionCard(.purge, note: "ESPAÇO PARA CRIAR", color: .orange)
            }
            if let activities = model.snapshot?.top_processes, !activities.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    HStack { Text("Em atividade agora").font(.headline); Spacer(); Text("CPU").font(.caption).foregroundStyle(.secondary) }
                    ForEach(Array(activities.prefix(4))) { process in
                        HStack { Image(systemName: "app.dashed").foregroundStyle(.secondary); Text(process.name).lineLimit(1); Spacer(); Text(String(format: "%.1f%%", process.cpu)).monospacedDigit().foregroundStyle(.secondary) }.font(.callout)
                        if process.id != activities.prefix(4).last?.id { Divider().opacity(0.5) }
                    }
                }.card()
            }
            Label("Nenhuma limpeza é iniciada automaticamente.", systemImage: "checkmark.shield").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var disk: Snapshot.Disk? { model.snapshot?.disks.first { $0.mount == "/" } }
    private func actionCard(_ tool: Tool, note: String, color: Color) -> some View {
        Button { selection = tool.rawValue } label: {
            VStack(alignment: .leading, spacing: 13) {
                HStack { Image(systemName: tool.symbol).font(.title2).foregroundStyle(color); Spacer(); Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.tertiary) }
                Text(tool.title).font(.headline)
                Text(tool.description).font(.caption).foregroundStyle(.secondary).lineSpacing(4).frame(minHeight: 52, alignment: .top)
                Text(note).font(.system(size: 8, weight: .semibold)).tracking(1).foregroundStyle(color)
            }.frame(maxWidth: .infinity, alignment: .leading).card()
        }.buttonStyle(.plain)
    }
    private var settings: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(title: "Do seu jeito.", subtitle: "Uma conexão simples com o Mole que você já usa.")
            VStack(alignment: .leading, spacing: 16) {
                Label("Instalação do Mole", systemImage: "link").font(.headline)
                Text(model.executable ?? "Não encontrado").font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                Button("Selecionar executável…") { model.selectExecutable() }
                Text("Homebrew, ~/.local/bin e o CLI incluído pelo instalador são detectados automaticamente.").font(.caption).foregroundStyle(.secondary)
            }.card()
            VStack(alignment: .leading, spacing: 14) {
                Label("Feito para ficar no seu Mac", systemImage: "lock.shield").font(.headline)
                Text("Sem conta, anúncios ou telemetria. As consultas e operações são executadas localmente pelo CLI instalado.")
                Text("Toca Desk é uma interface independente e não é o aplicativo oficial Mole for Mac. O Mole e o SwiftTerm pertencem aos seus respectivos autores.").foregroundStyle(.secondary)
                Link("Conhecer o projeto Mole ↗", destination: URL(string: "https://github.com/tw93/mole")!)
                Link("SwiftTerm · licença MIT ↗", destination: URL(string: "https://github.com/migueldeicaza/SwiftTerm")!)
            }.font(.callout).card()
        }
    }
}

struct ToolView: View {
    @EnvironmentObject var model: AppModel
    let tool: Tool
    @State private var confirm = false
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            PageTitle(title: tool.title, subtitle: tool.description)
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: tool.symbol).font(.system(size: 40, weight: .light)).foregroundStyle(accent).padding(20).background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                Text(tool.mutable ? "Primeiro, veja o que pode mudar." : "Tudo à vista, em um só lugar.").font(.title2.bold())
                Text(tool.mutable ? "A prévia executa uma simulação do Mole. Revise os resultados e, quando estiver pronto, inicie a operação. A seleção e as confirmações acontecem na sessão integrada." : "Abra a sessão integrada para consultar as informações diretamente no Mole.").foregroundStyle(.secondary).lineSpacing(5)
                HStack(spacing: 14) {
                    if tool.mutable {
                        Button { model.session = Session(tool: tool, preview: true) } label: { Label("Visualizar prévia", systemImage: "eye").padding(5) }.buttonStyle(.borderedProminent)
                        Button("Iniciar operação…") { confirm = true }.buttonStyle(.bordered)
                    } else {
                        Button("Abrir \(tool.title.lowercased())") { model.session = Session(tool: tool, preview: false) }.buttonStyle(.borderedProminent)
                    }
                }.disabled(model.executable == nil)
            }.padding(32).frame(maxWidth: .infinity, alignment: .leading).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18))
            Notice(text: tool.mutable ? "A operação pode modificar ou excluir arquivos. O Mole poderá solicitar sua senha de administrador na sessão, apenas quando necessário." : "Esta ferramenta apenas consulta informações.", icon: tool.mutable ? "checkmark.shield" : "info.circle", color: accent)
            if model.executable == nil { Notice(text: "Conecte o Mole em Ajustes para continuar.", icon: "exclamationmark.triangle", color: .orange) }
        }.confirmationDialog("Iniciar \(tool.title.lowercased())?", isPresented: $confirm, titleVisibility: .visible) {
            Button("Iniciar operação", role: .destructive) { model.session = Session(tool: tool, preview: false) }
            Button("Cancelar", role: .cancel) {}
        } message: { Text("Esta ação pode alterar ou excluir arquivos. Recomendamos revisar a prévia antes de continuar. Confirme as seleções solicitadas pelo Mole na sessão.") }
    }
}

struct DiskView: View {
    @EnvironmentObject var model: AppModel
    @State private var query = ""
    var entries: [DiskReport.Entry] { (model.report?.entries ?? []).filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }.sorted { $0.size > $1.size } }
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PageTitle(title: "Espaço para o que importa.", subtitle: "Explore suas pastas e descubra onde seu armazenamento está sendo usado.")
            HStack {
                Button { chooseFolder() } label: { Label("Escolher pasta", systemImage: "folder.badge.plus") }.buttonStyle(.borderedProminent)
                Button("Analisar Downloads") { Task { await model.scan(NSHomeDirectory() + "/Downloads") } }
                Spacer()
                if model.scanning { ProgressView().controlSize(.small); Text("Analisando…").foregroundStyle(.secondary) }
            }.disabled(model.scanning || model.executable == nil)
            if let error = model.scanError { Notice(text: error, icon: "exclamationmark.triangle", color: .orange) }
            if let report = model.report {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { VStack(alignment: .leading, spacing: 6) { Text(bytes(report.total_size)).font(.largeTitle.bold()); Text(report.path).font(.caption).foregroundStyle(.secondary).textSelection(.enabled) }; Spacer(); Text("\(report.entries.count) itens").foregroundStyle(.secondary) }
                    if report.scan_status != "complete" { Notice(text: "A leitura pode ser parcial. Pastas sem permissão ou ignoradas pelo Mole podem não estar incluídas no total.", icon: "info.circle", color: .orange) }
                    TextField("Filtrar por nome", text: $query).textFieldStyle(.roundedBorder)
                    ForEach(entries) { entry in
                        HStack(spacing: 14) {
                            Image(systemName: entry.is_dir ? "folder.fill" : "doc.fill").foregroundStyle(entry.is_dir ? Color.blue.opacity(0.75) : .gray).font(.title3)
                            VStack(alignment: .leading, spacing: 7) {
                                HStack { Text(entry.name).lineLimit(1); if entry.scan_status == "partial" || entry.scan_status == "unavailable" { Text("Leitura parcial").font(.caption2).foregroundStyle(.orange) } }
                                GeometryReader { geo in Capsule().fill(accent.opacity(0.7)).frame(width: geo.size.width * min(1, max(0, entry.size / max(1, report.total_size)))) }.frame(height: 4).background(.quaternary, in: Capsule())
                            }
                            Text(entry.scan_status == "unavailable" ? "Indisponível" : bytes(entry.size)).font(.callout).monospacedDigit().frame(width: 95, alignment: .trailing)
                            Button { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: entry.path)]) } label: { Image(systemName: "arrow.up.forward.square") }.help("Mostrar no Finder")
                            if entry.is_dir { Button { Task { await model.scan(entry.path) } } label: { Image(systemName: "chevron.right") }.disabled(model.scanning).help("Explorar pasta") }
                        }.padding(.vertical, 8)
                    }
                    if entries.isEmpty { Text("Nenhum item encontrado.").foregroundStyle(.secondary).padding(.vertical) }
                }.card()
            } else if !model.scanning {
                VStack(spacing: 16) {
                    Image(systemName: "internaldrive").font(.system(size: 55, weight: .ultraLight)).foregroundStyle(accent)
                    Text("Vamos olhar com calma.").font(.title2.bold())
                    Text("Escolha uma pasta para começar. A análise não remove arquivos.").foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity).padding(.vertical, 75).card()
            }
        }
    }
    func chooseFolder() {
        let panel = NSOpenPanel(); panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.prompt = "Analisar"
        if panel.runModal() == .OK, let path = panel.url?.path { Task { await model.scan(path) } }
    }
}

struct MetricCard: View {
    let title: String; let icon: String; let value: String; let detail: String; let percent: Double?; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack { Text(title).font(.system(size: 9, weight: .semibold)).tracking(1.2); Spacer(); Image(systemName: icon).foregroundStyle(color) }.foregroundStyle(.secondary)
            Text(value).font(.system(size: 29, weight: .semibold, design: .rounded))
            GeometryReader { geo in Capsule().fill(color.opacity(0.7)).frame(width: geo.size.width * min(1, max(0, (percent ?? 0) / 100))) }.frame(height: 4).background(.quaternary, in: Capsule())
            Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
struct PageTitle: View {
    let title: String; let subtitle: String
    var body: some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(.system(size: 31, weight: .bold, design: .rounded)); Text(subtitle).foregroundStyle(.secondary).lineSpacing(4) } }
}
struct Notice: View {
    let text: String; let icon: String; let color: Color
    var body: some View { Label { Text(text).font(.callout).lineSpacing(3) } icon: { Image(systemName: icon).foregroundStyle(color) }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12)) }
}
private extension View {
    func card() -> some View { padding(20).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.055))) }
}
