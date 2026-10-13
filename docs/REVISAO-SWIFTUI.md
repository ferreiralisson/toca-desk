# Revisão de SwiftUI e Liquid Glass

Revisão realizada em 12/10/2026 com as skills SwiftUI Specialist (Apple) e SwiftUI Expert, consulta à documentação pelo MCP oficial do Xcode e inspeção do aplicativo local.

## Resultado e mudanças

O Toca Desk já utilizava SwiftUI para as telas, sem WebView, Electron ou interface web. O uso de AppKit não tornava a interface não nativa. A revisão encontrou oportunidades de atualizar a navegação, tornar o estado mais granular e organizar as seções como views independentes.

- `NavigationSplitView`, `List` com seleção e `NavigationLink` substituem a sidebar construída manualmente.
- `@Observable`, `@State`, `@Environment` e `@Bindable` substituem o estado compartilhado via Combine/`ObservableObject`.
- Painel, métricas, processos, ajustes e linhas de armazenamento usam views próprias e entradas menores.
- A ordenação de pastas é preparada ao receber o relatório, em vez de ser repetida na construção de cada view. As identidades continuam baseadas em caminho e PID.
- Seletores de pasta e executável usam `fileImporter` do SwiftUI. Diretórios não são aceitos como executáveis.
- Cards de dados usam fundos legíveis; controles usam Liquid Glass nativo, com `GlassEffectContainer`, `glassEffect`, `.glass` e `.glassProminent`.
- Em Ajustes → Aparência é possível escolher Liquid Glass ou Clássico e ativar o tom verde nos destaques.
- As APIs de vidro são protegidas por `#available(macOS 26, *)`. macOS 14/15 recebem estilos clássicos. Reduzir Transparência e Aumentar Contraste também usam a alternativa sólida.
- Navegação segue os controles e o teclado do sistema. Botões apenas com ícone têm rótulos de acessibilidade; barras decorativas são ocultadas do VoiceOver.

## Integrações que permanecem

AppKit é utilizado pelo terminal SwiftTerm via `NSViewRepresentable`, para revelar arquivos no Finder e para controlar o ciclo de vida e impedir o encerramento durante uma operação. Essas integrações são apropriadas para um app macOS e não foram substituídas por simulações.

As ferramentas interativas continuam exibindo os menus do Mole em terminal integrado. Esta revisão não implementa um protocolo gráfico de seleção e execução no CLI. Prévias, confirmações, comandos permitidos e passagem literal de argumentos foram preservados.

## Validação

- Oito testes Swift passaram tanto no Swift Package Manager quanto no `RunAllTests` do MCP do Xcode, incluindo regras de fallback de Liquid Glass/acessibilidade e ordenação/limpeza do relatório de armazenamento.
- Build do esquema TocaDesk, incluindo alvos de teste, aprovado pelo `BuildProject` do MCP do Xcode 27.
- Aplicativo de release gerado por `scripts/build-app.sh`.
- Inspeção do aplicativo e alternância entre os estilos Liquid Glass e Clássico.
- Encerramento verificado pelo botão vermelho e por ⌘Q: o processo TocaDesk desapareceu em ambos os testes, sem sessão ativa. A proteção durante operações continua no código.

O build no Xcode usa o componente Metal e o plugin de build do SwiftTerm; ambos foram preparados no ambiente local. Os scripts Swift Package Manager continuam funcionando com o sistema de build nativo. A pipeline foi atualizada para um runner macOS 26 para disponibilizar o SDK necessário às APIs de vidro.

Os caminhos de fallback foram testados na lógica de seleção e verificados pelo compilador com deployment target macOS 14. A aparência em Macs executando macOS 14/15 ainda requer verificação visual nessas versões. Não foi feita auditoria completa com VoiceOver ou medição de performance com Instruments.

## Referências

- [Aplicar Liquid Glass em views SwiftUI](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer).
- [Acesso de agentes externos ao Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode).
