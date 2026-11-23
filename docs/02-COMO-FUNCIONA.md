# Hero Saga para Mac: como o programa funciona

Documento técnico para a staff e para quem quiser auditar o projeto.

## Visão geral

O Hero Saga é um cliente **Windows de 32 bits (DirectX 9)**. O macOS não executa programas Windows, então o app combina duas peças:

1. **Launcher próprio** (`Sources/HeroSagaMac.swift`, ~450 linhas de Swift/SwiftUI): é a janela que o jogador vê. Ele configura e inicia o jogo.
2. **Motor de compatibilidade Wine** (pasta `engine/`): traduz as chamadas do Windows para o macOS. É o **WineCX 24.0.7**, a versão de código aberto do CrossOver (LGPL), redistribuída **sem nenhuma modificação**.

```
Jogador → Launcher (Swift) → Wine (WineCX) → Hero.exe (cliente original, intocado)
                                   │
                    Windows → macOS │ DirectX 9 → OpenGL → Metal
                    Intel x86 → ARM (Rosetta 2, só em Apple Silicon)
```

O app **não contém o jogo**, **não modifica o `Hero.exe`** nem nenhum arquivo `.dll`/`.hrf` do jogo, e **não interage com o anti-cheat**. Ele só cria um ambiente Windows e escreve dois arquivos de configuração que o próprio jogo já usa.

## Estrutura do app

```
Hero Saga para Mac.app/
└── Contents/
    ├── MacOS/HeroSagaMac          launcher (universal: arm64 + x86_64)
    ├── Info.plist
    └── Resources/
        ├── AppIcon.icns
        ├── LICENSES.txt, LGPL-2.1.txt
        └── engine/
            ├── wswine.bundle/     WineCX 24.0.7 (Sikarugir), sem mono/gecko
            └── *.dylib            bibliotecas de suporte (Gcenx Wine Staging 11.21)
```

Dados criados no Mac do jogador:

| Caminho | Conteúdo |
|---|---|
| `~/Library/Application Support/HeroSagaMac/config.json` | Pasta do jogo, preset e opções escolhidas |
| `~/Library/Application Support/HeroSagaMac/prefix/` | "Garrafa" Wine (um `C:\` virtual) |
| `~/Library/Logs/HeroSagaMac.log` | Saída do Wine, para diagnóstico |

## O que acontece ao clicar em "Jogar"

1. **Verificações:** a pasta tem `Hero.exe`, o jogo ainda não está aberto, e o Rosetta está instalado (em Apple Silicon).
2. **Preparação do ambiente (só na 1ª vez):**
   - `wine wineboot -i`: cria a garrafa Windows 10.
   - Cria três chaves de registro vazias:
     - `HKCU\Software\Gravity Soft\RenewSetup`
     - `HKLM\Software\Gravity Soft\RenewSetup` (visão 32 bits)
     - `HKLM\Software\Gravity Soft\Ragnarok` (visão 32 bits)

     **Por quê:** sem elas o `Hero.exe` abre o `Setup.exe` (ferramenta .NET de configuração) toda vez e fica esperando. No Windows elas são criadas pelo próprio Setup. Descobrimos isso rastreando o acesso ao registro com o log do Wine.
3. **Aplicação das opções**, escritas nos arquivos de configuração do próprio jogo:
   - `savedata/OptionInfo.lua`: `RENDERSYSTEM=2` (DirectX 9), resolução, tela cheia, `SPRITEMODE`, `TEXTUREMODE`, `Trilinear`, e os comandos `/mineffect`, `/aura`, `/fog`, `/lightmap`, `/quake`.
   - `savedata/HeroOptions.ini`: `weather_rain`, `weather_clouds`, `shake`, `vsync`, `fps_limit`.
   - Na primeira execução é salva uma cópia `OptionInfo.lua.original`.
4. **Execução:** `wine Hero.exe` dentro da pasta do jogo, com estas variáveis:

| Variável | Valor | Motivo |
|---|---|---|
| `WINEPREFIX` | pasta da garrafa | Ambiente isolado do app |
| `WINEMSYNC` | `1` | Sincronização via Mach (msync): menos uso de CPU, maior ganho de FPS |
| `WINEDEBUG` | `-all` | Desliga logs do Wine (logs pesados chegaram a travar o jogo) |
| `WINEDLLOVERRIDES` | `mscoree,mshtml=` | Não instala Mono/Gecko, desnecessários |
| `DYLD_FALLBACK_LIBRARY_PATH` | pasta `engine/` | Para o Wine achar FreeType, GnuTLS etc. |

5. Quando o jogo fecha, o launcher volta ao estado "pronto" (ou se encerra, no modo "abrir direto").

## Por que DirectX 9 (`RENDERSYSTEM=2`)

O cliente oferece três renderizadores. Resultados no MacBook Air M1:

| Valor | Renderizador | Resultado no Mac |
|---|---|---|
| 1 | Legado | ~20 FPS |
| **2** | **DirectX 9** | **50–75 FPS (escolhido)** |
| 3 | DirectX 12 | Trava (passa por vkd3d → Vulkan → MoltenVK → Metal) |

## Detecção do Mac e presets

O launcher lê `machdep.cpu.brand_string`, `hw.memsize` e `hw.optional.arm64` (`sysctl`) e a resolução da tela:

| Mac detectado | Preset recomendado |
|---|---|
| Intel (qualquer) | Desempenho (vídeo integrado Intel é fraco) |
| M1 | Desempenho |
| M1 Pro/Max/Ultra, M2 | Equilíbrio |
| M3, M4+ com 8 GB | Equilíbrio |
| M3, M4+ com 16 GB ou mais | Qualidade |

## Como compilar (reprodutível)

Requisito: Command Line Tools da Apple (`xcode-select --install`).

```
git clone <repositório>
cd HeroSagaMac
./build.sh
```

O `build.sh`:
1. Roda `tools/fetch-engine.sh`, que baixa o WineCX e as bibliotecas **das fontes oficiais** e confere o **SHA-256** de cada arquivo.
2. Compila o launcher para arm64 e x86_64 (`swiftc`) e junta os dois (`lipo`).
3. Monta o `.app`, assina ad-hoc (`codesign -s -`) e gera o `.dmg` com o arquivo `.sha256` ao lado.

`tools/verify-engine.sh "/Applications/Hero Saga para Mac.app"` baixa o motor oficial de novo e compara **arquivo por arquivo** com o que está no app.

## Limitações conhecidas

- **Desempenho:** cada quadro passa por três traduções (Windows→macOS, x86→ARM, DirectX 9→OpenGL→Metal). No M1 o jogo fica em 50–75 FPS parado, com quedas ao andar por áreas novas.
- **Sem assinatura Apple:** sem conta Apple Developer (US$ 99/ano) o app não é notarizado, então o macOS mostra um aviso na primeira abertura.
- **Sessão presa:** fechar o jogo à força deixa a conta "online" no servidor por alguns minutos ("Recusado pelo servidor").
- **Testado** em MacBook Air M1 (8 GB, macOS 27). Outros Macs devem funcionar, mas ainda não foram testados.

## Licenças

- Launcher: código próprio deste repositório.
- Wine/WineCX: LGPL 2.1+ (texto em `LGPL-2.1.txt`; fonte em codeweavers.com/crossover/source e github.com/Sikarugir-App/Engines).
- Bibliotecas de suporte: licenças originais (ver `LICENSES.txt`).
- Nenhum arquivo do CrossOver pago (CodeWeavers) é distribuído.
