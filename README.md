# Toca Desk

**Uma interface nativa para acompanhar e cuidar do Mac com as ferramentas do [Mole CLI](https://github.com/tw93/Mole).**

Toca Desk reúne informações do sistema, exploração de armazenamento e acesso às rotinas de manutenção do Mole em uma janela para macOS, com interface em português. A proposta é facilitar a descoberta das ferramentas e a revisão de cada operação: você consulta o estado do computador, identifica pastas que ocupam espaço e inicia uma tarefa mantendo acesso às prévias e confirmações do mecanismo original.

O aplicativo é escrito em Swift, com SwiftUI e AppKit. As consultas estruturadas do Mole alimentam o painel e o explorador; o SwiftTerm oferece sessões interativas dentro da janela para as ferramentas que ainda usam menus de terminal. Todo o processamento da interface acontece localmente, sem servidor web, cadastro ou telemetria própria.

**Projeto comunitário independente:** Toca Desk não é o Mole oficial nem o aplicativo Mole for Mac, e não é afiliado, patrocinado ou endossado por tw93 ou pelo projeto Mole. O CLI é desenvolvido e mantido por seus autores; esta interface acrescenta uma camada de apresentação. O nome e o ícone da interface são próprios. Consulte [créditos e licenças](THIRD_PARTY_NOTICES.md).

## Baixar e instalar

### [⬇ Baixar o instalador completo para macOS](https://github.com/ferreiralisson/toca-desk/releases/latest/download/TocaDesk-Installer.pkg)

**Requer Mac com Apple Silicon (M1 ou posterior) e macOS 14+.** Inclui Toca Desk e Mole CLI; não é necessário compilar, instalar Homebrew ou ter internet durante a instalação.

1. Baixe o arquivo `.pkg` pelo link acima.
2. Feche o Toca Desk, caso esteja aberto, e abra o instalador.
3. Siga as etapas do macOS e depois abra **Toca Desk** na pasta Aplicativos.

**Esta versão ainda não possui assinatura Developer ID nem notarização Apple.** O macOS pode bloquear sua abertura. Os detalhes da versão, código-fonte e hashes de verificação estão na [página de downloads](https://github.com/ferreiralisson/toca-desk/releases/latest).

## Funcionalidades atuais

- **Visão geral:** saúde do sistema, CPU, memória, disco e processos obtidos pelo Mole, com atualização manual, atalho ⌘R e horário da última leitura.
- **Armazenamento:** exploração por pasta, ordenação por tamanho, filtro por nome, navegação em subpastas e abertura no Finder. Resultados parciais são identificados.
- **Manutenção:** acesso a limpeza, desinstalação, otimização, artefatos de projetos e instaladores, com prévia `--dry-run` e confirmação antes de iniciar operações modificadoras.
- **Monitor e histórico:** sessões integradas para consultar as ferramentas do CLI.
- **Integração flexível:** detecção do Mole via Homebrew em Intel/Apple Silicon, `~/.local/bin`, instalação dedicada do pacote ou seleção manual do executável.
- **Experiência nativa:** tema claro/escuro do sistema, navegação por teclado e rótulos acessíveis.

A versão atual é **0.1.3**, integrada ao **Mole CLI 1.51.0**. O painel e o explorador são gráficos; as demais ferramentas ainda apresentam a interface textual do Mole dentro do aplicativo. Mensagens do CLI podem aparecer em inglês. O [documento de evolução gráfica](docs/EXPERIENCIA-GRAFICA.md) descreve propostas futuras, não recursos já disponíveis.

## Requisitos

- macOS 14 ou posterior.
- Para compilar: Xcode com **Swift 6.0 ou posterior**, ferramentas de linha de comando selecionadas e licença do Xcode aceita. Embora o manifesto principal use Swift tools 5.9, as dependências fixadas exigem Swift 6.0.
- Internet na primeira compilação para resolver as dependências Swift. As versões e revisões estão em `Package.resolved`.
- Python 3 para executar os testes do instalador.
- Para usar o aplicativo avulso: Mole CLI instalado, com suporte a `status --json` e `analyze --json`. Consulte as [instruções oficiais do Mole](https://github.com/tw93/Mole#readme).

O instalador completo é exclusivo para **Apple Silicon (arm64)**. O aplicativo avulso é compilado para a arquitetura do Mac que executa o build; não é um binário universal. A distribuição completa foi validada em Apple Silicon; a variante Intel precisa de validação própria.

## Obter e executar o código

```sh
git clone https://github.com/ferreiralisson/toca-desk.git
cd toca-desk
swift --version
swift build --build-system native
swift run --build-system native TocaDesk
```

Abra `Package.swift` no Xcode para editar. O projeto usa o sistema de compilação nativo do Swift nos scripts existentes para evitar depender do compilador Metal opcional. Toolchains recentes podem emitir um aviso de depreciação de `--build-system native`; ele não impede a compilação na versão validada (Swift 6.4).

## Gerar o executável e o aplicativo

### Executável de release

```sh
swift build --build-system native -c release
BIN_DIR="$(swift build --build-system native -c release --show-bin-path)"
"$BIN_DIR/TocaDesk"
```

O executável fica em `$BIN_DIR/TocaDesk`. Para abrir pelo Finder e incluir ícone, recursos e avisos de licença, gere o pacote `.app`:

```sh
./scripts/build-app.sh
open "dist/Toca Desk.app"
```

O script desenha os ícones, compila em release, monta `dist/Toca Desk.app` e aplica uma assinatura local ad hoc. Você pode copiar esse aplicativo para `/Applications`. **O `.app` avulso não inclui o Mole CLI**; instale-o separadamente e selecione o caminho em Ajustes se a detecção automática não o encontrar.

### Imagem de disco do aplicativo

```sh
./scripts/build-app.sh
./scripts/package-dmg.sh
```

Saída: `dist/TocaDesk.dmg`. A imagem contém o aplicativo e um atalho para Aplicativos. Também depende de um Mole CLI instalado separadamente. O script de DMG reaproveita o `.app` existente; reconstrua-o antes de empacotar mudanças.

### Instalador completo offline

Em um Mac Apple Silicon:

```sh
./scripts/build-installer.sh
```

Saídas:

- `dist/TocaDesk-Installer.pkg`: instala Toca Desk 0.1.3 e Mole CLI 1.51.0.
- `dist/TocaDesk-Installer.sha256`: checksum do pacote gerado.
- `dist/TocaDesk-Installer-files.txt`: relação de arquivos do payload.

O script verifica os hashes de `vendor/mole`, reconstrói o aplicativo e gera o instalador. **A instalação final funciona sem Homebrew e sem internet**; a compilação inicial da interface ainda pode baixar dependências Swift.

Para instalar, feche o aplicativo e abra o `.pkg` no Finder. O instalador solicita autorização de administrador e grava:

| Componente | Destino |
| --- | --- |
| Aplicativo | `/Applications/Toca Desk.app` |
| CLI dedicado | `/Library/Application Support/TocaDesk/CLI/mo` |
| Fonte correspondente do CLI e instruções | `/Library/Application Support/TocaDesk/Sources` |
| Licença original do CLI | `/Library/Application Support/TocaDesk/CLI/LICENSE` |

Os atalhos `mo` e `mole` são criados em `/usr/local/bin` somente se os destinos estiverem livres; arquivos e links existentes são preservados. O aplicativo prioriza a configuração manual e instalações existentes antes de usar o CLI dedicado. Atualize a cópia integrada com uma nova versão do instalador.

O aplicativo usa assinatura ad hoc; o `.pkg` não tem assinatura Developer ID Installer e os artefatos não são notarizados pela Apple. O Gatekeeper pode impedir a abertura em outros Macs. Distribuição assinada e notarizada exige credenciais próprias da Apple, que não pertencem ao repositório.

## Segurança e limites de operação

Nenhuma limpeza começa ao abrir o aplicativo. Uma prévia não autoriza permanentemente uma execução: arquivos podem mudar entre as etapas e as seleções devem ser revisadas no Mole. As operações usam um catálogo fechado de comandos e passam argumentos separadamente ao processo, sem interpolar entradas em shell.

As senhas solicitadas pelo CLI são digitadas no terminal integrado, sem armazenamento pela interface. Não há `sudo` global nem confirmação automática. As permissões de privacidade do macOS continuam válidas; pastas inacessíveis podem exigir ajustes em Privacidade e Segurança.

Uma sessão ativa impede sair pelo menu. Use “Interromper” para enviar Ctrl+C e espere o encerramento. Interromper não desfaz mudanças já realizadas. O caminho do executável é a preferência persistida pela interface; o histórico de operações pertence ao Mole.

## Testes

```sh
swift test --build-system native
python3 scripts/test-installer.py
(cd vendor/mole && shasum -a 256 -c pinned.sha256)
```

Os testes Swift verificam prévias, leitura de JSON incompleto, argumentos, falhas e timeout. Os testes do instalador usam diretórios temporários para validar instalação nova, preservação de atalhos e links, diretórios redirecionados e ausência do CLI, sem instalar no sistema. Eles não substituem uma validação manual do aplicativo e do instalador em um Mac de teste.

## Organização e arquivos versionados

| Caminho | Conteúdo |
| --- | --- |
| `Sources/TocaDesk/` | Interface, modelos, consultas ao CLI e sessões de terminal |
| `Tests/TocaDeskTests/` | Testes automatizados da interface com o CLI |
| `scripts/` | Build, ícone original, DMG e testes de empacotamento |
| `packaging/` | Definição, recursos e scripts do instalador |
| `vendor/mole/` | Fonte e binários oficiais fixados, hashes e procedência |
| `LICENSE`, `LICENSES/`, `THIRD_PARTY_NOTICES.md` | Licença do projeto e avisos de terceiros |
| `docs/` | Documentação de evolução e limitações |
| `Package.swift`, `Package.resolved` | Manifesto e versões resolvidas das dependências |

`.gitignore` exclui `.build/`, `.swiftpm/`, `dist/`, ícones gerados em `Assets/`, caches, configurações pessoais de editores, arquivos de ambiente, certificados, chaves e registros locais. Os ícones são reconstruídos pelo script; os arquivos oficiais em `vendor/mole` são mantidos porque são insumos necessários ao instalador e à disponibilidade da fonte correspondente. Executáveis e instaladores gerados não devem entrar nos commits.

## Licença, contribuição e reconhecimento

Copyright © 2026 Alisson Ferreira da Silva e colaboradores.

Toca Desk é software livre sob a **GNU General Public License versão 3 (`GPL-3.0-only`)**. Você pode estudar, usar, modificar e redistribuir o projeto nos termos de [LICENSE](LICENSE). Ao distribuir versões modificadas ou binários, preserve os avisos e disponibilize a fonte correspondente conforme a GPL. O software é fornecido sem garantia.

O [Mole CLI](https://github.com/tw93/Mole), de tw93 e colaboradores, é o mecanismo de análise e manutenção e conserva sua GPL v3. O [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm), de Miguel de Icaza e colaboradores, fornece o terminal sob licença MIT. Os créditos e textos aplicáveis estão em [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). A licença não concede direitos sobre o nome ou o logotipo do Mole; veja a [política de marca original](https://github.com/tw93/Mole/blob/main/TRADEMARK.md).

Contribuições são bem-vindas. Leia [CONTRIBUTING.md](CONTRIBUTING.md) para preparar o ambiente, validar mudanças e enviar um pull request. Ao publicar binários em Releases, disponibilize também a fonte exata da interface, dependências correspondentes, scripts de compilação e fonte do CLI; mantenha os avisos incluídos no aplicativo e no instalador.
