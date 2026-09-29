# Componentes de terceiros

Toca Desk é uma interface independente desenvolvida por Alisson Ferreira da Silva e colaboradores. Não é produto oficial, afiliado, patrocinado ou endossado por tw93, pelo projeto Mole ou pelo Mole for Mac.

## Mole CLI 1.51.0

- Projeto e autoria: [tw93/Mole e seus colaboradores](https://github.com/tw93/Mole).
- Licença: GNU GPL versão 3; texto original dentro de `vendor/mole/source-V1.51.0.tar.gz`.
- Procedência e hashes: [vendor/mole/README.md](vendor/mole/README.md).
- O aplicativo avulso executa um CLI instalado separadamente. O instalador completo **inclui** o CLI oficial, os binários darwin-arm64, a licença e o arquivo de código-fonte da mesma versão, sem modificar o código do CLI.
- Nome e logotipo do Mole pertencem ao projeto original. Consulte sua [política de marca](https://github.com/tw93/Mole/blob/main/TRADEMARK.md). A GPL cobre código, não concede direitos de marca.

## SwiftTerm 1.20.0

[SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) fornece o terminal integrado e é distribuído sob MIT. O aviso completo é reproduzido abaixo e em `LICENSES/SwiftTerm-MIT.txt`.

Copyright (c) 2019-2026 Miguel de Icaza (https://github.com/migueldeicaza)
Copyright (c) 2017-2019, The xterm.js authors (https://github.com/xtermjs/xterm.js)
Copyright (c) 2014-2016, SourceLair Private Company (https://www.sourcelair.com)
Copyright (c) 2012-2013, Christopher Jeffrey (https://github.com/chjj/)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## swift-argument-parser 1.8.2

[swift-argument-parser](https://github.com/apple/swift-argument-parser), dos autores do projeto Swift, é uma dependência transitiva resolvida pelo Swift Package Manager para ferramentas do SwiftTerm. Licença Apache 2.0, preservada em `LICENSES/swift-argument-parser-Apache-2.0.txt`. Isso não significa que todo produto dessa dependência esteja ligado ao executável da interface.

## Código e arte própria

O código da interface, scripts e documentação deste repositório são disponibilizados sob GNU GPL versão 3 (`GPL-3.0-only`), conforme `LICENSE`. O ícone é desenhado por `scripts/create-icon.swift`, sem importar o logotipo do Mole. Os componentes de terceiros conservam suas licenças e créditos.
