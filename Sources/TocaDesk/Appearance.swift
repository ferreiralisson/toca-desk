import SwiftUI

// Preferences describe appearance only; destructive operations never depend on them.
enum InterfaceStyle: String, CaseIterable, Identifiable {
    case liquidGlass, classic
    var id: String { rawValue }
    var title: LocalizedStringKey {
        switch self {
        case .liquidGlass: return "Liquid Glass"
        case .classic: return "Clássico"
        }
    }
    func usesGlass(supported: Bool, reduceTransparency: Bool, increaseContrast: Bool) -> Bool {
        self == .liquidGlass && supported && !reduceTransparency && !increaseContrast
    }
}

enum AppearancePreference {
    static let style = "interfaceStyle"
    static let tint = "glassAccentTint"
}

private struct InterfaceStyleKey: EnvironmentKey {
    static let defaultValue = InterfaceStyle.liquidGlass
}
private struct GlassTintKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var interfaceStyle: InterfaceStyle {
        get { self[InterfaceStyleKey.self] }
        set { self[InterfaceStyleKey.self] = newValue }
    }
    var glassAccentTint: Bool {
        get { self[GlassTintKey.self] }
        set { self[GlassTintKey.self] = newValue }
    }
}

enum TocaTheme {
    static let accent = Color(red: 0.20, green: 0.72, blue: 0.56)
}

struct GlassControlGroup<Content: View>: View {
    @Environment(\.interfaceStyle) private var style
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(macOS 26, *),
           style.usesGlass(supported: true, reduceTransparency: reduceTransparency, increaseContrast: contrast == .increased) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
    }
}

struct NativeActionButton<Content: View>: View {
    @Environment(\.interfaceStyle) private var style
    @Environment(\.glassAccentTint) private var accentTint
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var prominent = false
    let action: () -> Void
    @ViewBuilder let label: () -> Content

    var body: some View {
        if #available(macOS 26, *),
           style.usesGlass(supported: true, reduceTransparency: reduceTransparency, increaseContrast: contrast == .increased) {
            if prominent {
                Button(action: action, label: label)
                    .buttonStyle(.glassProminent)
                    .tint(accentTint ? TocaTheme.accent : Color.accentColor)
                    .buttonBorderShape(.capsule)
            } else {
                Button(action: action, label: label).buttonStyle(.glass)
                    .buttonBorderShape(.capsule).tint(.clear)
            }
        } else if prominent {
            Button(action: action, label: label).buttonStyle(.borderedProminent)
        } else {
            Button(action: action, label: label).buttonStyle(.bordered)
        }
    }
}

struct ConnectionBadge: View {
    @Environment(\.interfaceStyle) private var style
    @Environment(\.glassAccentTint) private var accentTint
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    let connected: Bool

    var body: some View {
        ConnectionBadgeLabel(connected: connected)
            .modifier(ConnectionBadgeSurface(style: style, accentTint: accentTint,
                reduceTransparency: reduceTransparency, increaseContrast: contrast == .increased))
    }
}
private struct ConnectionBadgeLabel: View {
    let connected: Bool
    var body: some View {
        Label(connected ? "Mole conectado" : "Mole não encontrado",
              systemImage: connected ? "checkmark.circle" : "exclamationmark.circle")
            .font(.callout)
            .foregroundStyle(connected ? Color.primary : Color.orange)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .accessibilityLabel(connected ? "Mole CLI conectado" : "Mole CLI não encontrado")
    }
}
private struct ConnectionBadgeSurface: ViewModifier {
    let style: InterfaceStyle
    let accentTint: Bool
    let reduceTransparency: Bool
    let increaseContrast: Bool
    func body(content: Content) -> some View {
        if #available(macOS 26, *),
           style.usesGlass(supported: true, reduceTransparency: reduceTransparency, increaseContrast: increaseContrast) {
            content.glassEffect(accentTint ? .regular.tint(TocaTheme.accent.opacity(0.15)) : .regular, in: .capsule)
        } else {
            content.background(Color(nsColor: .controlBackgroundColor), in: Capsule())
                .overlay(Capsule().strokeBorder(.secondary.opacity(increaseContrast ? 0.5 : 0.16)))
        }
    }
}

struct ContentCard: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    var padding: CGFloat = 22
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.primary.opacity(contrast == .increased ? 0.3 : 0.07)))
    }
}
extension View {
    func tocaCard(padding: CGFloat = 22) -> some View { modifier(ContentCard(padding: padding)) }
}
