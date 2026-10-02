#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess

version = Path('VERSION').read_text().strip()
repo = os.environ['GH_REPO']
base = f'https://github.com/{repo}'
notes = os.environ.get('RELEASE_NOTES', '').strip()
if not notes:
    import re
    tags = [tag for tag in subprocess.check_output(['git', 'tag', '--list', 'v*', '--sort=-version:refname'], text=True).splitlines() if re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+', tag)]
    revision = f'{tags[0]}..HEAD^' if tags else 'HEAD^'
    notes = subprocess.check_output(['git', 'log', '--format=- %s', revision], text=True).strip()
    notes = notes or '- Atualização de distribuição e empacotamento.'
body = f'''## Novidades — {version}

{notes}

## Baixar e instalar

### [⬇ Baixar instalador completo (.pkg)]({base}/releases/download/v{version}/TocaDesk-Installer.pkg)

Requer **Apple Silicon (M1 ou posterior) e macOS 14+**. Inclui Toca Desk {version} e Mole CLI 1.51.0. Funciona offline, sem Homebrew.

Feche o Toca Desk, abra o instalador e siga as etapas. Depois abra **Toca Desk** em Aplicativos. Para atualizar, instale este pacote sobre a versão anterior.

### Se a Apple não puder verificar o instalador

Esta versão não tem assinatura Developer ID nem notarização Apple. Caso confie na origem do download:

1. Tente abrir o `.pkg` e feche o aviso.
2. Abra **Ajustes do Sistema → Privacidade e Segurança**.
3. Na seção Segurança, clique em **Abrir Mesmo Assim** e confirme em **Abrir**.
4. Se o aplicativo apresentar o mesmo aviso, repita o procedimento para ele.

Não desative a proteção geral do Mac. Isso se aplica a software não verificado, não a alertas de malware detectado ou arquivo danificado. [Orientação da Apple](https://support.apple.com/pt-br/102445).

## Arquivos

- **TocaDesk-Installer.pkg:** instalador completo recomendado.
- **TocaDesk.dmg:** somente o aplicativo; requer Mole CLI instalado separadamente.
- **TocaDesk-source.tar.gz:** fonte da interface, fontes das dependências Swift, fonte do CLI e scripts de compilação.
- **SHA256SUMS.txt:** integridade dos três arquivos; baixe todos na mesma pasta e execute `shasum -a 256 -c SHA256SUMS.txt`.

Toca Desk é independente, sob GPL-3.0-only, sem afiliação ou endosso do Mole. [Licenças e créditos]({base}/blob/v{version}/THIRD_PARTY_NOTICES.md).
'''
Path('dist').mkdir(exist_ok=True)
Path('dist/RELEASE-NOTES.md').write_text(body)
