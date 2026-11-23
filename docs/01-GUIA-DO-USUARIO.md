# Hero Saga para Mac — Guia do usuário

Este guia explica como instalar e usar o **Hero Saga para Mac**, o programa que permite jogar o cliente Windows do Hero Saga em computadores Mac.

## O que você precisa

| Item | Requisito |
|---|---|
| Mac | Qualquer Mac com macOS 13 (Ventura) ou mais novo |
| Processador | Apple Silicon (M1, M2, M3, M4) ou Intel |
| Espaço livre | ~0,5 GB para o programa + o tamanho do jogo (~8 GB) |
| Jogo | A pasta do Hero Saga baixada do site oficial (a que tem `Hero.exe`) |
| Internet | Só para jogar (o programa não baixa nada sozinho) |

> Macs Apple Silicon usam o **Rosetta 2** da Apple. Se ele não estiver instalado, o macOS pede na primeira vez. É só aceitar.

## 1. Baixar e instalar

1. Baixe o arquivo `HeroSagaParaMac-1.0.dmg` na página de *Releases* do repositório.
2. Dê dois cliques no `.dmg`. Vai abrir uma janela com o app e um atalho para a pasta **Aplicativos**.
3. **Arraste "Hero Saga para Mac" para a pasta Aplicativos.**
4. Ejete o disco "Hero Saga para Mac" (botão de ejetar no Finder).

## 2. Abrir pela primeira vez (aviso do macOS)

O app ainda não tem assinatura paga da Apple, então o macOS mostra um aviso na primeira vez.

1. Abra **Aplicativos** e dê dois cliques em **Hero Saga para Mac**.
2. Se aparecer *"não pode ser aberto porque a Apple não pode verificá-lo"*, clique em **OK**.
3. Vá em **Ajustes do Sistema > Privacidade e Segurança**, role até o fim e clique em **Abrir Mesmo Assim**. Confirme com sua senha ou Touch ID.
4. Nas próximas vezes ele abre direto.

Se mesmo assim não abrir, rode no **Terminal**:

```
xattr -dr com.apple.quarantine "/Applications/Hero Saga para Mac.app"
```

## 3. Configurar

1. **Pasta do jogo:** clique em **Escolher pasta…** e selecione a pasta do Hero Saga. Se ela estiver em `Downloads/Hero Saga v1.7`, o app encontra sozinho.
2. **Qualidade gráfica:** escolha um preset. O marcado com **★** é o recomendado para o seu Mac.

| Preset | Para quem | O que faz |
|---|---|---|
| **Desempenho** | M1 básico, Macs Intel | 1024×768, sprites/texturas baixas, efeitos mínimos, sem clima, aura, neblina e lightmap |
| **Equilíbrio** | M1 Pro/Max, M2 | 1280×800, qualidade média, aura e tremor ligados |
| **Qualidade** | M3, M4 e superiores | 1440×900, qualidade alta, todos os efeitos |
| **Personalizado** | Quem quer ajustar | Abre as opções avançadas |

3. **Opções avançadas** (opcional): resolução, tela cheia, qualidade de sprites e texturas, limite de FPS, efeitos mínimos, aura, tremor de tela, clima, neblina, lightmap, filtro trilinear e V-Sync. Mudar qualquer uma troca o preset para *Personalizado*.

## 4. Jogar

1. Clique em **Jogar**.
2. **Na primeira vez** o app leva cerca de 1 minuto preparando o "ambiente Windows". Isso só acontece uma vez.
3. O jogo abre. Faça login normalmente.

### Abrir o jogo direto
Marque **"Abrir o jogo direto nas próximas vezes"**. Daí em diante, clicar no ícone abre o jogo sem mostrar a janela de opções. Para ver as opções de novo, **segure a tecla Option (⌥) enquanto abre o app**.

Dica: clique com o botão direito no ícone do Dock > **Opções > Manter no Dock**.

## 5. Outros botões

- **Atualizar jogo:** abre o atualizador oficial do Hero Saga (`Atualizador Hero Saga.exe`).
- **Reparar:** apaga e recria o ambiente Windows do app. Use se o jogo parar de abrir. Seus personagens e configurações do jogo não são afetados.

## Problemas comuns

| Problema | Solução |
|---|---|
| "Recusado pelo servidor" | O jogo foi fechado à força e a sessão ficou presa no servidor. Feche tudo e espere ~5 minutos. **Sempre saia pelo menu do jogo.** |
| O jogo engasga ao andar | Use o preset **Desempenho** ou limite o FPS em 60. Os engasgos diminuem depois de alguns minutos na mesma área. |
| Ping alto | O ping depende da sua internet, não do programa. Prefira Wi-Fi 5 GHz ou cabo, e evite internet compartilhada por celular ou PC. |
| "O Hero Saga já está aberto" | Já existe um jogo rodando. Feche-o antes de abrir outro. |
| Preso em tela cheia | **Cmd+Tab** troca de app, **Cmd+Q** fecha o jogo. |
| O jogo não abre | Clique em **Reparar** e tente de novo. O log fica em `~/Library/Logs/HeroSagaMac.log`. |

## Desinstalar

1. Apague **Hero Saga para Mac** da pasta Aplicativos.
2. (Opcional) Apague a pasta `~/Library/Application Support/HeroSagaMac` (ambiente Windows e configurações do app).

A pasta do jogo não é tocada.
