# Toca Desk: evolução para uma experiência gráfica

Análise do projeto e do código-fonte do Mole V1.51.0, em 28/09/2026.

## Diagnóstico

O aplicativo atual é híbrido: o painel e a exploração de pastas são gráficos, mas a maioria das ferramentas abre um terminal incorporado. A observação do usuário está correta. Uma janela com botões que abre um menu textual ainda exige entender os comandos, as teclas e as mensagens do CLI.

A referência de experiência é a organização por tarefas de cuidado do Mac, como a apresentada pelo [CleanMyMac](https://macpaw.com/cleanmymac). A proposta é manter identidade própria e concentrar a interação em resultados compreensíveis e escolhas explícitas. Não faz parte dessa referência prometer detecção de malware, duplicatas, atualização de aplicativos ou outras funções que o Toca Desk não implementa.

## O que encontramos no código

| Área | Situação atual | Integração disponível no Mole V1.51.0 | Próximo passo |
|---|---|---|---|
| Visão geral | Gráfica, atualização manual | `status --json` | Atualização periódica com pausa em segundo plano e indicação de dados antigos |
| Monitor | Terminal incorporado | `status --watch --interval 2s`, JSON por linha | Gráficos e processos nativos, sem sessão textual |
| Armazenamento | Lista gráfica por tamanho | `analyze --json <pasta>` | Navegação de retorno, categorias, mapa de tamanhos e estados de leitura parcial |
| Aplicativos | Terminal incorporado | `uninstall --list` emite JSON quando stdout é um pipe | Lista nativa com ícones, busca, origem e seleção; remoção precisa de fluxo próprio de execução |
| Histórico | Terminal incorporado | `history --json` | Linha do tempo e detalhes de resultados |
| Limpeza | Prévia e execução em terminal | `clean --dry-run`; sem plano de seleção em JSON | Criar uma interface estruturada de plano e execução antes de permitir seleção por item |
| Projetos e instaladores | Seleção por teclado | Rotinas internas de descoberta, seleção e validação | Expor candidatos e operações por identificadores, preservando as verificações existentes |
| Otimização | Terminal incorporado | `optimize --dry-run`; mensagens textuais | Expor tarefas independentes, efeitos, requisitos e resultados |

A camada que abre o terminal está em `Sources/TocaDesk/TerminalSession.swift`. `ToolView`, em `ContentView.swift`, conecta os botões a essa sessão. `Models.swift` já demonstra o caminho correto para leitura estruturada, com consultas separadas de apresentação.

Um detalhe decisivo: a versão analisada rejeita explicitamente `mo clean --select`, `--categories` e `--exclude`. Portanto, uma tela com opções “cache do navegador” e “logs” não poderia simplesmente chamar `mo clean` e alegar que só executou essas escolhas. A ferramenta também não fornece um contrato geral de progresso por item.

A listagem de aplicativos é uma oportunidade melhor do que a implementação atual aproveita: `uninstall --list` já fornece nome, identificador de bundle, origem, nome aceito para desinstalação, caminho e tamanho. Isso viabiliza o catálogo visual sem extrair texto de uma tela ANSI. A desinstalação propriamente dita ainda exige revisão e confirmação e não se torna uma API segura apenas porque aceita nomes.

## Experiência proposta

O fluxo principal será **Analisar → Revisar → Executar → Ver resultado**.

1. **Analisar:** botão principal “Analisar meu Mac”. Mostrar a etapa atual e quantos locais foram verificados. Não inventar percentual quando o total não é conhecido. Consultas não removem arquivos.
2. **Revisar:** categorias com nome, descrição, tamanho medido, quantidade de itens e seleção. Um painel lateral mostra caminhos, consequências e motivos para itens bloqueados. Arquivos pessoais não vêm selecionados por padrão.
3. **Executar:** botão com a ação concreta e o total selecionado, por exemplo “Remover 12 itens · 840 MB”. A confirmação apresenta a mesma lista revisada. Itens que mudaram desde a análise precisam de nova revisão.
4. **Resultado:** distinguir removidos, ignorados e falhas. Informar estimativa de tamanho dos itens processados separadamente da variação medida do espaço livre. APFS, arquivos compartilhados e atividades de outros apps podem fazer esses valores diferirem.

A navegação pode ficar em: Visão geral, Limpeza, Aplicativos, Armazenamento, Manutenção e Histórico. “Projetos” e “Instaladores” passam a ser categorias de limpeza com contexto próprio, em vez de nomes de comandos.

### Tela de revisão de limpeza

- Cabeçalho: “Análise concluída”, horário e indicação de resultados parciais.
- Coluna de categorias: caches, logs, instaladores e artefatos de desenvolvimento.
- Lista central: checkbox, nome, localização, tamanho e efeito da remoção.
- Detalhes: motivo da sugestão, possibilidade de reconstrução e botão “Mostrar no Finder”.
- Rodapé fixo: quantidade selecionada, tamanho estimado e botão da ação.
- Permissões insuficientes aparecem junto à categoria afetada e oferecem orientação contextual.

### Tela de aplicativos

Ícones reais do macOS, nome, tamanho, origem e busca. Ao selecionar um aplicativo, listar os arquivos associados e explicar quais não serão tocados por serem compartilhados. A confirmação usa a identidade do aplicativo e seus caminhos, não apenas o nome exibido. Aplicativos abertos exigem tratamento explícito antes da remoção.

### Monitor e histórico

Gráficos de CPU e memória, tabela de processos e leitura de bateria, com estados “não disponível” quando não houver sensor. Histórico com status completo/parcial/falha, data, itens e espaço estimado. O terminal deixa o fluxo comum; detalhes técnicos podem ser oferecidos como log opcional.

## Arquitetura recomendada

Manter SwiftUI e substituir o acoplamento aos menus por uma camada de operações tipadas. A interface descreve a intenção; um executor local implementa as capacidades suportadas e informa resultados estruturados.

```text
Telas SwiftUI
    ↓ operações e seleções por identificador
Serviço de aplicação: análises, planos, execução e histórico
    ├── adaptador JSON do Mole: status, análise, inventário e histórico
    ├── adaptador de manutenção: plano e aplicação com validações
    └── APIs do macOS: ícones, Finder e Lixeira quando compatível
```

Para leitura, usar imediatamente as saídas JSON existentes. Para ações seletivas, a recomendação é manter uma extensão versionada do Mole, idealmente contribuída ao projeto original, que exponha descoberta e execução estruturadas. É preciso revisar cada rotina: algumas limpam diretórios; outras chamam gerenciadores de pacotes ou serviços e não podem ser tratadas como uma simples lista de arquivos.

Não é adequado simular teclas em um terminal oculto ou interpretar frases em inglês para decidir o que apagar. Atualizações do Mole, nomes de arquivos incomuns e mudanças de idioma tornam esse mecanismo frágil.

Um plano de operação deve conter: versão do protocolo e do mecanismo, identificador, horário, categoria, itens elegíveis, tamanhos conhecidos, motivos de bloqueio, efeito da ação e permissões necessárias. Cada item precisa de identidade verificável. A execução aceita apenas seleções pertencentes ao plano e revalida caminho, identidade e regras antes de agir. A interface nunca envia um comando shell arbitrário.

O progresso deve ser emitido como eventos estruturados: descoberta, planejamento, item iniciado, item concluído, item ignorado, falha e resumo. O cancelamento deve impedir novas ações e aguardar a etapa atual chegar a um ponto seguro; não deve ser descrito como desfazer ações já realizadas.

A cópia de CLI incluída no instalador permite fixar uma versão conhecida. Enquanto a interface aceitar CLIs externos, deve verificar as capacidades disponíveis e desabilitar ações incompatíveis. Ter um caminho executável não garante suporte a um protocolo futuro.

Permissões elevadas devem ficar restritas às operações que realmente precisam delas. Uma senha não deve ser capturada por um campo SwiftUI genérico nem passada em argumentos. O desenho de um serviço privilegiado com autorização nativa precisa ser uma etapa explícita da implementação; esconder um prompt de sudo não resolve esse requisito.

## Sequência de implementação

1. **Telas gráficas apoiadas no JSON existente:** catálogo de aplicativos, histórico nativo e monitor; ampliar a navegação do armazenamento. Validar modelos com a versão instalada e dados ausentes.
2. **Contrato de limpeza:** implementar e testar descoberta, planos, seleção e resultados, começando por um escopo pequeno e verificável. Conservar as proteções do Mole. Não oferecer uma seleção que o mecanismo não sabe respeitar.
3. **Fluxo visual completo:** análise, revisão, execução, cancelamento e resumo, com acessibilidade por teclado e VoiceOver.
4. **Expandir manutenção:** projetos, instaladores, desinstalação com associados e tarefas que exigem autorização. Só habilitar cada função quando sua execução corresponder à revisão exibida.
5. **Distribuição:** instalador atualizado, testes em Mac sem Mole/Homebrew e assinatura/notarização para distribuição pública.

## Critérios de conclusão

- As tarefas comuns não abrem um terminal nem exigem setas, Enter ou respostas textuais do CLI.
- Selecionar um item nunca autoriza remover outros itens não apresentados.
- Resultados parciais, recusas de permissão e tamanhos desconhecidos ficam visíveis.
- Percentuais e espaço recuperado se baseiam em medições identificadas.
- Cancelamento, falhas e retomada têm estados explícitos.
- Testes cobrem nomes com espaços e caracteres especiais, links simbólicos, mudanças entre análise e execução, itens protegidos, volumes externos e falhas de permissão.
- Operações destrutivas são testadas primeiro em árvores descartáveis, sem usar os arquivos pessoais do usuário.

## Escopo desta entrega

Esta entrega conclui o instalador combinado e a análise da evolução gráfica. A mudança completa de experiência descrita acima **ainda não foi implementada** no aplicativo 0.1.2. O pacote atual mantém as sessões integradas nas ferramentas interativas.

Referências técnicas: [Mole V1.51.0](https://github.com/tw93/Mole/tree/V1.51.0), em especial `bin/clean.sh`, `bin/uninstall.sh`, `bin/installer.sh`, `bin/purge.sh` e `bin/history.sh`. A avaliação foi feita na fonte da versão fixada, não apenas na documentação de `main`.
