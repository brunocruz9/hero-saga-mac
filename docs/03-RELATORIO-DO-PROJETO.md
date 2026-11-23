# Relatório do projeto: Hero Saga no Mac

**Responsável:** Bruno
**Data:** 23/11/2026
**Máquina de teste:** MacBook Air M1, 8 GB RAM, macOS 27.2.1
**Objetivo:** rodar o cliente Windows do Hero Saga v1.7 no Mac de forma leve, sem Steam, e criar um programa para outros jogadores de Mac.

## Resumo

O cliente do Hero Saga roda no Mac pelo **Wine**, uma camada de compatibilidade de código aberto. Criamos o **Hero Saga para Mac**, um app com interface própria que embute o Wine, configura o jogo sozinho de acordo com o Mac de cada jogador e abre o jogo com um clique. Resultado no M1: **jogável a 50–75 FPS** no preset *Desempenho*. O executável e os arquivos do jogo não são alterados.

## Linha do tempo

### 1. Tentativa anterior (antes deste projeto)
Um tutorial com **CrossOver + Steam** não funcionou. O CrossOver estava instalado em versão de teste (14 dias, expira por volta de 03/12/2026) com duas garrafas "Steam" sobrando.

### 2. Diagnóstico do jogo
- `Hero.exe`: executável Windows **32 bits**, DirectX 9/12, com proteção própria ("guard").
- `Setup.exe`: ferramenta de configuração em .NET.
- `Atualizador Hero Saga.exe`: atualizador 64 bits.
- `savedata/OptionInfo.lua`: configurações vindas de um PC Windows (placa NVIDIA, 1920×1080).

### 3. Primeiro teste no CrossOver (garrafa nova, sem Steam)
- **Problema:** o jogo abria o `Setup.exe` e ficava parado esperando.
- **Causa encontrada** (rastreando o registro com log do Wine): o `Hero.exe` procura `HKLM\Software\Gravity Soft\RenewSetup` e `...\Ragnarok`. Sem essas chaves ele chama o Setup.
- **Correção:** criar as chaves vazias. O jogo passou a abrir direto. Também ajustamos a resolução para 1280×720 em janela (backup do original: `OptionInfo.lua.windows-original`).

### 4. Travamento após o login
- **Problema:** depois do login o jogo congelava.
- **Causas:** (a) o log de diagnóstico pesado que eu estava usando e (b) o jogo estava em **DirectX 12** (`RENDERSYSTEM=3`), que no Mac passa por várias camadas (vkd3d → Vulkan → MoltenVK → Metal).
- **Correção:** `RENDERSYSTEM=2` (DirectX 9), sem logs.

### 5. "Recusado pelo servidor"
- Aconteceu depois de cada fechamento forçado do jogo.
- **Causa:** a sessão anterior continuava ativa no servidor. **Não era o anti-cheat.**
- **Solução:** esperar ~5–10 minutos. Recomendação: sempre sair pelo menu do jogo.

### 6. Troca para Wine gratuito (o CrossOver é pago)
| Motor | Resultado (FPS no M1) |
|---|---|
| Wine Staging 11.21 (Gcenx) | 5–20, engasgando (descartado) |
| CrossOver 26.3 (teste) | 13–60, 45–50 parado |
| CrossOver + DXVK | Tela preta (descartado) |
| CrossOver + renderizador legado (`RENDERSYSTEM=1`) | ~20 (descartado) |
| Wine Staging + Vulkan (MoltenVK) | Não abriu (descartado) |
| **WineCX 24.0.7 (open-source do CrossOver) + msync** | **50+ parado, ~17 andando** |
| **WineCX + configurações mínimas** | **50–75, sem quedas fortes (adotado)** |

O ganho do CrossOver vinha do **msync** (sincronização otimizada para macOS), que também existe no WineCX gratuito.

### 7. Configurações mínimas (preset "Desempenho")
1024×768 em tela cheia, sprites e texturas em qualidade baixa, sem filtro trilinear, efeitos mínimos, sem aura, neblina, lightmap, tremor e clima, V-Sync desligado, limite de 60 FPS.

### 8. Ping
Medido do Mac até o servidor: ~120 ms com 12% de perda de pacotes. A causa é a rede (o Mac estava em internet compartilhada, `192.168.137.x`), não o programa.

### 9. Criação do "Hero Saga para Mac"
- App nativo em Swift/SwiftUI, universal (Apple Silicon + Intel), 121 MB em `.dmg`.
- Detecta o Mac e recomenda um preset (Desempenho / Equilíbrio / Qualidade), com opções avançadas.
- Botões **Jogar**, **Atualizar jogo** e **Reparar**, e opção **"Abrir o jogo direto"**.
- Aplica automaticamente todas as correções acima.
- Motor Wine baixado das fontes oficiais com conferência de SHA-256, sem modificações.
- Bugs corrigidos durante os testes: o app travava ao abrir as opções avançadas (resoluções com a mesma largura) e o preset "Personalizado" não abria as opções.

## O que o programa faz e não faz

**Faz:**
- cria um ambiente Windows isolado em `~/Library/Application Support/HeroSagaMac`;
- cria três chaves de registro vazias dentro desse ambiente;
- edita `savedata/OptionInfo.lua` e `savedata/HeroOptions.ini` com as opções escolhidas;
- executa `Hero.exe` e `Atualizador Hero Saga.exe`.

**Não faz:**
- não inclui nem redistribui o jogo;
- não modifica `Hero.exe`, DLLs ou `hero.hrf`;
- não burla, esconde ou desativa a proteção do jogo;
- não coleta dados nem se conecta a nenhum servidor por conta própria.

## Pendências e recomendações

1. **Aprovação da staff** para divulgar o programa aos jogadores.
2. **Assinatura Apple Developer** (US$ 99/ano) para tirar o aviso de segurança do macOS, se a staff quiser uma experiência mais profissional.
3. **Testes em outros Macs** (M2/M3/M4 e Intel) para calibrar os presets.
4. **Link oficial de download do cliente:** com ele, o app poderia baixar o jogo sozinho.
5. Eventual otimização do lado do servidor/cliente: o modo DirectX 12 do cliente trava no Mac, então o DirectX 9 precisa continuar disponível.

## Documentos relacionados
- `01-GUIA-DO-USUARIO.md`: passo a passo para jogadores.
- `02-COMO-FUNCIONA.md`: detalhes técnicos.
- `04-SEGURANCA.md`: verificações de segurança e antivírus.
