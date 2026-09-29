# Mole CLI fixado em V1.51.0

Estes arquivos são dependências de distribuição, não caches pessoais. São versionados para reconstruir o instalador sem baixar o CLI e para manter sua fonte correspondente junto aos binários.

| Arquivo | Origem / finalidade |
| --- | --- |
| `source-V1.51.0.tar.gz` | [Código-fonte oficial da tag V1.51.0](https://github.com/tw93/Mole/archive/refs/tags/V1.51.0.tar.gz), incluindo LICENSE, TRADEMARK.md, Makefile, go.mod e go.sum |
| `binaries-darwin-arm64.tar.gz` | [Binários oficiais da release V1.51.0](https://github.com/tw93/Mole/releases/download/V1.51.0/binaries-darwin-arm64.tar.gz) |
| `SHA256SUMS` | [Hashes publicados na release](https://github.com/tw93/Mole/releases/download/V1.51.0/SHA256SUMS) |
| `pinned.sha256` | Hashes fixados dos dois arquivos usados neste projeto |

Verificação local:

```sh
(cd vendor/mole && shasum -a 256 -c pinned.sha256)
```

Os hashes verificam integridade em relação aos valores fixados; não substituem a conferência da origem numa atualização. Atualize fonte e binários juntos, revise as licenças e os scripts de empacotamento e execute os testes antes de mudar a versão.

A fonte do CLI pode ser extraída com `tar -xzf source-V1.51.0.tar.gz`. No diretório extraído, consulte `go.mod` para a versão do Go e execute `make build` para gerar os binários locais (com download das dependências Go). Os scripts de shell permanecem no arquivo fonte. Este repositório não altera o CLI.
