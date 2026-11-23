# Hero Saga para Mac

Launcher para jogar o cliente Windows do **Hero Saga** em Macs (Apple Silicon e Intel), usando o motor de compatibilidade **Wine** (WineCX 24, open-source). Sem Steam, sem CrossOver pago.

- Detecta o seu Mac e sugere a melhor configuração gráfica (presets **Desempenho / Equilíbrio / Qualidade** + opções avançadas)
- Aplica sozinho as correções necessárias para o jogo rodar no Mac
- Botões **Jogar**, **Atualizar jogo** e **Reparar**
- Não contém nem modifica o jogo

## Download

Baixe o `.dmg` na página de [**Releases**](../../releases) e siga o [Guia do usuário](docs/01-GUIA-DO-USUARIO.md).

## Documentação

| Documento | Para quem |
|---|---|
| [01 – Guia do usuário](docs/01-GUIA-DO-USUARIO.md) | Jogadores: instalação e uso passo a passo |
| [02 – Como funciona](docs/02-COMO-FUNCIONA.md) | Staff/técnicos: arquitetura e decisões |
| [03 – Relatório do projeto](docs/03-RELATORIO-DO-PROJETO.md) | Staff: tudo que foi feito e testado |
| [04 – Segurança](docs/04-SEGURANCA.md) | Todos: antivírus, hashes, auditoria |

## Compilar a partir do código

Requer as Command Line Tools da Apple (`xcode-select --install`).

```
./build.sh
```

O script baixa o motor Wine das fontes oficiais (conferindo SHA-256), compila o launcher (universal) e gera `build/HeroSagaParaMac-<versão>.dmg`.

## Licenças

Launcher: código deste repositório. Wine/WineCX: LGPL 2.1+. Bibliotecas de terceiros: ver [LICENSES.txt](LICENSES.txt). Hero Saga é propriedade de seus respectivos donos.
