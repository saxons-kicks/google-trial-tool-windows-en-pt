# Google AI Trial Tool

Conteúdo republicado, origem: grupo QQ 797481450
Esta versão pode causar banimento de conta e envolve chamadas de ferramentas, use com cautela.


Injeta no processo do Google One via Frida para chamar a API `BillingClient`, descobrir e ativar avaliações gratuitas ocultas de $0.

## Pré-requisitos

| Componente | Descrição |
|---|---|
| **Emulador MuMu** | Iniciado, com conta Google conectada e forma de pagamento vinculada |
| **adb** | No `PATH` ou configurado na variável de ambiente `ADB_PATH` |
| **frida** (host) | `pip install frida-tools`, versão ≥ 16 |
| **frida-server** (dispositivo) | Enviado para `/data/local/tmp/frida-server` no dispositivo e com permissão de execução |
| **module.apk** (dispositivo) | APK contendo a biblioteca `BillingClient`, enviado para `/data/local/tmp/module.apk` |
| **Google One** | Instalado no dispositivo (`com.google.android.apps.subscriptions.red`) |

## Preparação do dispositivo

> **Nota**: Como há mais de um emulador listado no `adb devices` (`127.0.0.1:16384` e `emulator-5554`), os comandos `adb` abaixo usam `-s 127.0.0.1:16384` para apontar diretamente para o MuMu e evitar o erro `more than one device/emulator`.

```powershell
# Conectar ao MuMu
adb connect 127.0.0.1:16384

# Enviar o frida-server (a partir de C:\Users\Mateus\Downloads\frida)
adb -s 127.0.0.1:16384 push "C:\Users\Mateus\Downloads\frida\frida-server" /data/local/tmp/frida-server
adb -s 127.0.0.1:16384 shell "chmod 755 /data/local/tmp/frida-server"

# Enviar o module.apk (APK contendo com.android.billingclient)
adb -s 127.0.0.1:16384 push "C:\Users\Mateus\Downloads\frida\module.apk" /data/local/tmp/module.apk
```

## Uso

### Windows (PowerShell)

> Caso a execução de scripts esteja bloqueada no seu PowerShell, libere na sessão atual com:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

```powershell
# Listar todas as avaliações disponíveis para a conta atual (apontando para a porta 16384)
.\auto-trial.ps1 --port 16384 --list

# Ativar avaliação gratuita de 3 meses do Pro (5TB, $19.99/mês)
.\auto-trial.ps1 --port 16384 --product pro --dur 3mo

# Ativar avaliação gratuita de 12 meses da variante Pro (5TB, $19.99/mês) ★Recomendado
.\auto-trial.ps1 --port 16384 --product pro12 --dur 12mo

# Ativar avaliação gratuita de 12 meses do Ultra 20x (30TB, $199.99/mês)
.\auto-trial.ps1 --port 16384 --product 20x --dur 12mo

# Ativar avaliação gratuita de 6 meses do Ultra 5x (20TB, $99.99/mês)
.\auto-trial.ps1 --port 16384 --product 5x --dur 6mo

# Selecionar automaticamente a avaliação mais longa (padrão: plano mais alto)
.\auto-trial.ps1 --port 16384
```

### Linux / macOS (Bash)

```bash
# Listar todas as avaliações disponíveis para a conta atual
./auto-trial.sh --list

# Ativar avaliação gratuita de 12 meses da variante Pro (5TB, $19.99/mês) ★Recomendado
./auto-trial.sh --product pro12 --dur 12mo
```

### Parâmetros

| Parâmetro | Descrição | Padrão |
|---|---|---|
| `--list` | Apenas lista as avaliações, sem ativar | (modo de ativação) |
| `--product` | `pro` / `pro12` / `5x` / `20x` / `auto` / ID completo `g1.*` | `auto` |
| `--dur` | `1mo` / `3mo` / `6mo` / `12mo` / `longest` | `longest` |
| `--port` | Porta ADB do MuMu | Detecção automática |
| `--adb` | Caminho do `adb` | Detecção automática |

### Variáveis de ambiente

| Variável | Descrição |
|---|---|
| `ADB_PATH` | Caminho do executável `adb` |
| `FRIDA_SCRIPT` | Caminho do `frida-auto-trial.js` (padrão: mesmo diretório) |
| `FRIDA_SERVER_PATH` | Caminho do `frida-server` no dispositivo (padrão: `/data/local/tmp/frida-server`) |
| `MODULE_APK_DEVICE` | Caminho do `module.apk` no dispositivo (padrão: `/data/local/tmp/module.apk`) |

## Tabela de IDs de produtos

| Apelido | ID do Produto | Armazenamento | Mensalidade | Avaliação |
|---|---|---|---|---|
| **pro12** ★ | `g1.2tb.ai.subs_variant` | 5TB | $19.99 | 6/12 meses |
| **pro** | `g1.play.2tb.ai` | 5TB | $19.99 | 3 meses |
| **5x** | `g1.play.20tb` | 20TB | $99.99 | 1/3/6/12 meses |
| **20x** | `g1.play.ai.pro` | 30TB | $199.99 | 1/3/6/12 meses |
| — | `g1.2tb.ai` | 5TB | $19.99 | Nenhuma |
| — | `g1.ai.pro` | 30TB | $199.99 | Nenhuma |
| — | `g1.30tb` | 30TB | $149.99 | Nenhuma |

O botão "Fazer upgrade" na interface do app usa os IDs sem avaliação (`g1.2tb.ai`, etc.).

> **Atenção**: Até 2026-11-19, as avaliações do Ultra 5x/20x foram encerradas (as ofertas foram removidas). O Pro possui dois IDs de produto:
> - `g1.2tb.ai.subs_variant` (apelido `pro12`): até **12 meses** grátis, recomendado usar como prioridade
> - `g1.play.2tb.ai` (apelido `pro`): 3 meses grátis
>
> Nota: O Frida ≥ 17 possui mudanças incompatíveis (a ponte Java no 17 precisa ser carregada explicitamente); recomenda-se usar o Frida **16.7.19**.

## Métodos apenas via Web — inviáveis

Após testes, nenhuma das abordagens via Web abaixo consegue contornar a validação no servidor do Google Play:

1. **URL estática**: `rpctoken`, `_gfid` e o blob de pagamentos são vinculados à sessão e expiram imediatamente
2. **Script no Console alterando o parâmetro `ear`**: O `ear` gerado pela página (25 posições) coloca o produto em `ear[13]` e a assinatura de integridade em `ear[24]`. A assinatura é vinculada ao produto original; ao trocar o produto, mantendo ou removendo a assinatura, o servidor retorna 400
3. **Extensão do Chrome com RPC Hook**: A solução da comunidade interceptava no nível do payload RPC `Ngbm`, mas o repositório correspondente já retornou 404

> **Conclusão**: A avaliação oculta (`g1.play.2tb.ai`) não é exibida em nenhuma página, e a versão Web não consegue gerar uma sessão de checkout válida correspondente. O único método confiável é iniciar pelo dispositivo injetando a API `BillingClient` via Frida.

## Observações importantes

- O script apenas abre a janela de pagamento do Google Play; é necessário confirmar manualmente (digitando a senha)
- A assinatura é renovada automaticamente após o término da avaliação; lembre-se de cancelar antes
- A conta deve ter uma forma de pagamento vinculada e não possuir assinatura ativa; caso contrário, a avaliação não ficará disponível
- `launchBillingFlow` retornando `code=0` pode consumir a elegibilidade da avaliação mesmo que a janela não apareça
- Faça todo o processo no emulador e recomenda-se vincular um cartão com saldo baixo como margem de segurança

## Descrição dos arquivos

- `auto-trial.ps1` — Inicializador em PowerShell (Windows); detecta o dispositivo automaticamente, gerencia o `frida-server`, injeta o script e monitora o resultado
- `auto-trial.sh` — Inicializador em Shell (Linux/macOS); detecta o dispositivo automaticamente, gerencia o `frida-server`, injeta o script e monitora o resultado
- `frida-auto-trial.js` — Script de injeção Frida; carrega o `BillingClient` via `DexClassLoader` para consultar e ativar avaliações



Grupo de compartilhamento: t.me/muihbb
