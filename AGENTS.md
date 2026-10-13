# Toca Desk: desenvolvimento no Xcode

Este projeto é um aplicativo macOS SwiftUI/AppKit com Swift Package Manager.
Abra `Package.swift` no Xcode; produto e esquema: `TocaDesk`.
Mantenha compatibilidade com macOS 14 e com as dependências de `Package.resolved`.

## Skills e ferramentas

- Para SwiftUI, use as skills instaladas `swiftui-specialist` (Apple) e
  `swiftui-expert-skill`. Consulte somente as referências pertinentes à mudança.
- Para migrações solicitadas de testes, use `modernize-tests` (Apple).
  Não migre a suíte automaticamente só porque a skill está instalada.
- O MCP `xcode` usa o `xcrun mcpbridge` oficial da Apple. O Xcode deve estar aberto.
  Comece por `XcodeListWindows` e selecione a janela deste pacote antes de chamar
  ferramentas de build, testes, diagnósticos ou previews.
- Preserve o Swift Package Manager e os scripts de distribuição deste projeto.
  Se o MCP estiver indisponível, use os comandos documentados no README.
- APIs de versões posteriores do macOS exigem verificação de disponibilidade e
  alternativa funcional para macOS 14. Não adote Liquid Glass sem solicitação.

## Validação e distribuição

- Testes: `swift test --build-system native`.
- Instalador: `./scripts/build-installer.sh` (Apple Silicon).
- `VERSION` é compartilhado pelo aplicativo e pelo instalador.
- Um push na `main` inicia uma publicação automática; faça push somente quando
  a tarefa autorizar a publicação das alterações.
- Operações de manutenção que alteram arquivos devem preservar prévias e
  confirmações do Mole e ser testadas em diretórios descartáveis.
- Configurações locais, caches e exportações de skills ficam em `.codex/`,
  `.swiftpm/`, `.build/` e `dist/`, conforme `.gitignore`.
