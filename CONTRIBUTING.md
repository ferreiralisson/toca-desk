# Como contribuir

Contribuições de código, documentação, acessibilidade, traduções e relatos de bugs são bem-vindas.

## Preparar uma mudança

1. Faça um fork e clone o repositório em um Mac com macOS 14+ e Swift 6.0 ou posterior.
2. Crie uma branch para uma alteração com escopo claro.
3. Siga as instruções do README para compilar e executar.
4. Execute `swift test --build-system native` e `python3 scripts/test-installer.py`.
5. Se alterar empacotamento, gere o aplicativo e o instalador e confira seus conteúdos.
6. Abra um pull request explicando o problema, a solução e como foi validada. Para mudanças visuais, inclua imagens sem dados pessoais.

Ao relatar problemas, informe a versão do macOS, arquitetura do Mac, versão do aplicativo e versão/origem do Mole CLI. Remova nomes pessoais, caminhos privados, senhas e tokens dos registros.

## Cuidados de implementação

- Preserve prévias, confirmações, cancelamento e proteções do Mole.
- Passe argumentos separadamente aos processos; não monte comandos com interpolação de entrada do usuário.
- Teste operações que modificam arquivos somente em diretórios descartáveis.
- Não envie caches, executáveis gerados, certificados ou configurações pessoais. Consulte `.gitignore`.
- Mantenha `Package.resolved` e documente alterações de dependências.
- Ao atualizar `vendor/mole`, use artefatos da mesma versão oficial, confira os hashes e mantenha fonte correspondente, licença e procedência.
- Diferencie recursos implementados de propostas em `docs/`.

## Licença e créditos

Ao enviar uma contribuição, você concorda em disponibilizá-la sob GNU GPL versão 3 (`GPL-3.0-only`), a licença deste projeto, e confirma que tem o direito de fazê-lo. Os direitos autorais de cada contribuição permanecem com seus autores.

Preserve os avisos de terceiros. A licença não transfere marcas nem implica endosso do projeto Mole. Mudanças específicas do CLI podem ser propostas ao [projeto original](https://github.com/tw93/Mole), seguindo suas próprias diretrizes.
