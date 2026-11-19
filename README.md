# Google AI / Google One Trial Tool (Windows Edition) 🚀

> **Language / Idioma:** [English 🇬🇧/🇺🇸](#english) | [Português (Brasil) 🇧🇷](#português-brasil)

---

<a name="english"></a>
# English 🇬🇧/🇺🇸

Automated tool designed to discover and activate hidden $0.00 free trials (such as 12 months, 6 months, or 3 months) for **Google One** and **Gemini Advanced** by hooking the official Google Play `BillingClient` API via Frida.

## 📌 Table of Contents
1. [How It Works](#how-it-works-en)
2. [Included Files](#included-files-en)
3. [Prerequisites](#prerequisites-en)
4. [Quick Start (Windows)](#quick-start-en)
5. [Step-by-Step Tutorial: How to choose based on `--list`](#step-by-step-tutorial-en)
6. [Product Table & Aliases](#product-table-en)
7. [Confirmation & How to Cancel (Avoid Future Charges)](#confirmation-and-cancellation-en)
8. [Manual Setup & Other Emulators](#manual-setup-en)
9. [Troubleshooting (FAQ)](#troubleshooting-en)

---

<a name="how-it-works-en"></a>
### 💡 How It Works

Google Play Store servers host promotional free trial offers (e.g., 12-month, 6-month, or 3-month trials) tied to specific Google One subscription product IDs. However, the standard Google One app and web interfaces only display full-price options or shorter trials.

This tool:
1. Connects to the Android emulator where your Google account and Google One app are configured.
2. Uses **Frida** to load the official `BillingClient` library (provided by `module.apk`).
3. Queries Google Play billing servers directly to detect all active $0 trial offers eligible for your logged-in Google account.
4. When an offer is chosen, triggers the official Google Play native bottom sheet showing **$0.00**, allowing you to subscribe safely and legitimately.

> [!NOTE]
> The script **never** makes hidden purchases: it strictly launches the official Google Play dialog. You confirm the transaction yourself using your Google password or biometrics inside the emulator.

---

<a name="included-files-en"></a>
### 📦 Included Files

| File | Purpose |
|---|---|
| `module.apk` | Contains the official `com.android.billingclient` library needed for Play Store billing queries. |
| `frida-server.zip` | Pre-packaged Frida server binary (v16.7.19 x86_64 for Android emulators). Automatically extracted and pushed to the emulator by the script. |
| `frida-auto-trial.js` | JavaScript Frida hook that bridges the `BillingClient` and executes `launchBillingFlow`. |
| `auto-trial.ps1` | Primary script for **Windows** (PowerShell): auto-detects emulator, extracts/pushes files, and monitors execution. |
| `auto-trial.sh` | Shell script for Linux / macOS environments. |

---

<a name="prerequisites-en"></a>
### 📋 Prerequisites

Before running the tool, make sure the following requirements are met:

#### 1. Android Emulator with Root Enabled
- **Recommended**: [MuMu Player 12](https://www.mumuplayer.com/) (or LDPlayer 9 / BlueStacks / Nox / Rooted physical phone).
- **Enable Root**: In the emulator settings, ensure **Root / Superuser Access** is turned **ON**.

#### 2. Google Account & Apps on the Emulator
- **Google Play Store**: Log in with your Google account.
- **Payment Method**: Your Google account must have a valid payment method attached (credit/debit card). Google Play requires this to authorize any subscription, even for $0.00 trials.
  > [!TIP]
  > For security and peace of mind, use a virtual card with a low balance or temporary limit.
- **No Active Google One Subscription**: The account must **not** have an active Google One subscription (free trial promos are intended for new subscribers or accounts without active plans).
- **Google One App Installed**: Install the official **Google One** app from the Play Store inside the emulator and open it at least once to sync your account.

#### 3. PC (Host) Requirements
- **Python**: Python 3.9 - 3.12 installed on your machine.
- **Frida CLI**: Install Frida 16.x tools in your Windows terminal:
  ```powershell
  pip install "frida==16.7.19" "frida-tools<14.0.0"
  ```
  *(Frida 16.7.19 is recommended for full compatibility with the bundled `frida-server`).*
- **ADB (Android Debug Bridge)**: Included with MuMu Player 12 and other emulators. The script automatically searches common paths.

---

<a name="quick-start-en"></a>
### 🚀 Quick Start (Windows)

With the emulator open, Root enabled, and Google One installed:

Open PowerShell inside this project folder:
```powershell
# Allow local script execution for the current session (if needed)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Step 1: List all free trials available for your account
.\auto-trial.ps1 --list
```

> [!IMPORTANT]
> The script will automatically extract `frida-server.zip` and push both `frida-server` and `module.apk` to `/data/local/tmp/` on your emulator if they are not already there!

---

<a name="step-by-step-tutorial-en"></a>
### 🎓 Step-by-Step Tutorial: How to choose based on `--list`

Every Google account and country has different promotional eligibility. Therefore, **always run `--list` first before trying to activate**.

#### Step 1: Run the list command
```powershell
.\auto-trial.ps1 --list
```

#### Step 2: Read the terminal output
The script queries Google Play and prints the available products and trials. Here is an example of real output:

```text
[*] Looking for MuMu devices...
[+] Device found at 127.0.0.1:16384
[+] frida-server running as root (PID 3142)
[+] module.apk present
[+] Google One PID: 4520
[*] Script started
[+] BillingClient connected
[*] Products found: 4

  PRODUCT g1.2tb.ai.subs_variant — Google One (AI Premium)
    [0] Phase0: $0.00 × P1Y (1 cycles) ★FREE★ id=free-trial-1y tags=[ai_promo]
    [1] Phase1: $19.99 × P1M (recurring)

  PRODUCT g1.play.2tb.ai — Google One (AI Premium)
    [0] Phase0: $0.00 × P3M (1 cycles) ★FREE★ id=free-trial-3m
    [1] Phase1: $19.99 × P1M (recurring)

[*] TRIALS_FOUND 2
[+] TRIAL g1.2tb.ai.subs_variant / free-trial-1y — 12 months free
[+] TRIAL g1.play.2tb.ai / free-trial-3m — 3 months free

[+] List complete
```

#### Step 3: How to interpret the results
Look closely at the lines starting with `[+] TRIAL`:

1. **Identify the Product ID**:
   - `g1.2tb.ai.subs_variant`: Extended trial variant for AI Premium (Gemini Advanced + 2TB/5TB). Alias: **`pro12`**.
   - `g1.play.2tb.ai`: Standard AI Premium trial. Alias: **`pro`**.
   - `g1.play.20tb`: Ultra 20TB Plan. Alias: **`5x`**.
   - `g1.play.ai.pro`: Ultra 30TB Plan. Alias: **`20x`**.

2. **Identify the Trial Period**:
   - `P1Y` = **12 months** (1 year) free. Parameter: `--dur 12mo`.
   - `P6M` = **6 months** free. Parameter: `--dur 6mo`.
   - `P3M` = **3 months** free. Parameter: `--dur 3mo`.
   - `P1M` = **1 month** free. Parameter: `--dur 1mo`.

#### Step 4: Run the matching activation command

Based on what `--list` showed for your account:

- **Scenario A: 12-month trial found (`g1.2tb.ai.subs_variant`) ★RECOMMENDED★**
  ```powershell
  .\auto-trial.ps1 --product pro12 --dur 12mo
  ```

- **Scenario B: 3-month trial found (`g1.play.2tb.ai`)**
  ```powershell
  .\auto-trial.ps1 --product pro --dur 3mo
  ```

- **Scenario C: Ultra plan found (5x or 20x)**
  ```powershell
  .\auto-trial.ps1 --product 20x --dur 12mo
  ```

- **Scenario D: Auto-select (picks the longest trial available)**
  ```powershell
  .\auto-trial.ps1
  ```

---

<a name="product-table-en"></a>
### 🏷️ Product Table & Aliases

| Alias | Google Product ID | Features | Standard Price | Common Trial Lengths |
|---|---|---|---|---|
| **`pro12`** ★ | `g1.2tb.ai.subs_variant` | Gemini Advanced + Cloud Storage | $19.99/mo | **12 months** or **6 months** |
| **`pro`** | `g1.play.2tb.ai` | Gemini Advanced + Cloud Storage | $19.99/mo | **3 months** |
| **`5x`** | `g1.play.20tb` | 20TB Cloud Storage | $99.99/mo | 1, 3, or 6 months |
| **`20x`** | `g1.play.ai.pro` | 30TB Cloud Storage + AI Pro | $199.99/mo | 1, 3, or 12 months |

---

<a name="confirmation-and-cancellation-en"></a>
### 🛡️ Confirmation & How to Cancel (Avoid Future Charges)

#### When Activating:
1. After running the command with `--product`, the Google One app inside your emulator opens the official Google Play bottom sheet.
2. **Verify on the emulator screen**:
   - The immediate charge must be **$0.00** (or your local equivalent).
   - Google Play will explicitly show the date when the trial ends and the first charge would take place.
3. Tap **Subscribe** (type your Google password if prompted).
4. The terminal will log: `[+] TRIAL ACTIVATED SUCCESSFULLY`.

#### How to Cancel to Avoid Automatic Renewal:
Google Play subscriptions renew automatically after the trial ends. You can cancel renewal immediately without losing access:
1. Open the **Google Play Store** app on your phone or emulator.
2. Tap your profile picture in the top-right corner -> **Payments & subscriptions** -> **Subscriptions**.
3. Select **Google One**.
4. Tap **Cancel subscription** and confirm.
5. **Done!** Your Google One and Gemini Advanced benefits stay active until the end of the trial period.

---

<a name="manual-setup-en"></a>
### ⚙️ Manual Setup & Other Emulators

#### Available Parameters

| Parameter | Description | Example |
|---|---|---|
| `--list` | Lists all trial offers without activating | `.\auto-trial.ps1 --list` |
| `--product` | Specifies plan (`pro12`, `pro`, `5x`, `20x`, or full ID) | `.\auto-trial.ps1 --product pro12` |
| `--dur` | Trial duration (`1mo`, `3mo`, `6mo`, `12mo`, `longest`) | `.\auto-trial.ps1 --dur 12mo` |
| `--port` | Sets the emulator's ADB port | `.\auto-trial.ps1 --port 16384` |
| `--adb` | Custom path to `adb.exe` | `.\auto-trial.ps1 --adb "C:\adb\adb.exe"` |

#### Common Emulator Ports
- **MuMu Player 12**: `16384` (Instance 1), `16416` (Instance 2), `16448` (Instance 3).
- **LDPlayer**: `5555`.
- **NoxPlayer**: `62001`.
- **BlueStacks**: `5555`.

#### Manual File Push (Optional)
```powershell
# 1. Extract frida-server
Expand-Archive -Path frida-server.zip -DestinationPath . -Force

# 2. Push frida-server and set executable permissions
adb push frida-server /data/local/tmp/frida-server
adb shell "chmod 755 /data/local/tmp/frida-server"

# 3. Push BillingClient helper APK
adb push module.apk /data/local/tmp/module.apk
```

---

<a name="troubleshooting-en"></a>
### ❓ Troubleshooting (FAQ)

1. **`more than one device/emulator`**
   - Provide the specific port: `.\auto-trial.ps1 --port 16384 --list`
2. **`Failed to start frida-server`**
   - Ensure Root is enabled in emulator settings and restart the emulator.
3. **`=== NO_TRIALS ===` or `TRIALS_FOUND 0`**
   - The account is not eligible for active trial promos or has already used one. Try with a different Google account.
4. **`=== ITEM_ALREADY_OWNED ===`**
   - The account currently has an active Google One subscription.
5. **`frida CLI not found`**
   - Install via: `pip install "frida==16.7.19" "frida-tools<14.0.0"`

---

<br/>

---

<a name="português-brasil"></a>
# Português (Brasil) 🇧🇷

Ferramenta automatizada para consulta e ativação de avaliações gratuitas ocultas ($0 / R$ 0,00) do **Google One** e **Gemini Advanced** através de injeção na API oficial `BillingClient` do Google Play via Frida.

## 📌 Sumário
1. [Como funciona](#como-funciona-pt)
2. [Arquivos inclusos no projeto](#arquivos-inclusos-pt)
3. [Pré-requisitos](#pré-requisitos-pt)
4. [Início Rápido (Windows)](#início-rápido-pt)
5. [Tutorial Passo a Passo: Como escolher conforme o `--list`](#tutorial-passo-a-passo-pt)
6. [Tabela de Produtos e Apelidos](#tabela-produtos-pt)
7. [Confirmação e Cancelamento (Evitar cobrança futura)](#confirmação-cancelamento-pt)
8. [Configuração Manual e Outros Emuladores](#configuração-manual-pt)
9. [Solução de Problemas (FAQ)](#faq-pt)

---

<a name="como-funciona-pt"></a>
### 💡 Como funciona

Os servidores da Google Play Store possuem ofertas promocionais de avaliação gratuita (ex.: 12 meses, 6 meses ou 3 meses grátis) vinculadas a certos IDs de produto do Google One. No entanto, o aplicativo do Google One e a interface web convencional exibem apenas planos com cobrança imediata ou períodos reduzidos de teste.

Esta ferramenta:
1. Conecta-se ao emulador Android onde o Google One e a Play Store estão configurados.
2. Utiliza o **Frida** para carregar a biblioteca `BillingClient` oficial (fornecida pelo `module.apk`).
3. Consulta diretamente os servidores de faturamento da Google Play para descobrir todas as ofertas de $0 elegíveis para a conta logada.
4. Ao selecionar uma oferta, dispara a janela nativa oficial do Google Play no emulador com valor **R$ 0,00**, permitindo que você assine de forma legítima e segura.

> [!NOTE]
> O script **não** realiza compras automáticas às escuras: ele apenas abre a tela oficial do Google Play. Você confirma manualmente com a senha ou biometria da sua conta Google dentro do emulador.

---

<a name="arquivos-inclusos-pt"></a>
### 📦 Arquivos inclusos no projeto

| Arquivo | Função |
|---|---|
| `module.apk` | APK contendo a biblioteca oficial `com.android.billingclient`, necessária para a comunicação com a Play Store. |
| `frida-server.zip` | Binário compactado do servidor Frida (versão 16.7.19 x86_64 para emuladores Android). Os scripts descompactam e enviam automaticamente ao emulador se necessário. |
| `frida-auto-trial.js` | Script de hook em JavaScript que faz a ponte com o `BillingClient` e inicia o fluxo de assinatura. |
| `auto-trial.ps1` | Script principal para **Windows** (PowerShell) com detecção automática do emulador, envio dos arquivos e execução. |
| `auto-trial.sh` | Script para **Linux / macOS** (Bash). |

---

<a name="pré-requisitos-pt"></a>
### 📋 Pré-requisitos

Antes de executar a ferramenta, certifique-se de cumprir os seguintes requisitos:

#### 1. Emulador Android com Root
- **Recomendado**: [MuMu Player 12](https://www.mumuplayer.com/) (ou LDPlayer 9 / BlueStacks / Nox / Celular físico com root).
- **Habilitar Root**: Nas configurações do emulador, certifique-se de que a opção de **Root (Permissão de Superusuário)** está ativada.

#### 2. Conta Google e Aplicativos no Emulador
- **Google Play Store**: Conecte uma conta Google.
- **Forma de Pagamento**: A conta precisa ter uma forma de pagamento válida cadastrada na Play Store (cartão de crédito/débito). Mesmo para ofertas de $0,00, a Google Play exige um método cadastrado para autorização.
  > [!TIP]
  > Para sua segurança, utilize um cartão virtual com limite baixo ou bloqueado temporariamente após o teste.
- **Sem assinatura ativa**: A conta **não** deve possuir uma assinatura ativa do Google One no momento (promoções de avaliação são destinadas a novos assinantes ou contas sem plano ativo).
- **Google One Instalado**: Instale o aplicativo **Google One** diretamente pela Play Store dentro do emulador e abra-o uma vez para autenticar sua conta.

#### 3. Dependências no Computador (Host)
- **Python**: Instale o Python (3.9 a 3.12).
- **Frida CLI**: Instale as ferramentas do Frida versão 16.x no terminal do seu computador:
  ```powershell
  pip install "frida==16.7.19" "frida-tools<14.0.0"
  ```
  *(Recomenda-se a versão 16.7.19 para total compatibilidade com o binário `frida-server` incluso).*
- **ADB (Android Debug Bridge)**: Já vem embutido em emuladores como o MuMu Player. Se não estiver no seu `PATH`, o script tentará localizar os caminhos comuns automaticamente.

---

<a name="início-rápido-pt"></a>
### 🚀 Início Rápido (Windows)

Com o emulador aberto, o root ativado e o app Google One instalado:

Abra o PowerShell na pasta deste projeto:
```powershell
# Libera a execução de scripts locais nesta sessão do PowerShell (se necessário)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 1º Passo essencial: Listar as avaliações gratuitas disponíveis para a sua conta
.\auto-trial.ps1 --list
```

> [!IMPORTANT]
> Os scripts detectam automaticamente se o `frida-server` e o `module.apk` já estão no emulador. Se não estiverem, os arquivos incluídos na pasta do projeto serão descompactados e transferidos automaticamente para `/data/local/tmp/`!

---

<a name="tutorial-passo-a-passo-pt"></a>
### 🎓 Tutorial Passo a Passo: Como escolher conforme o `--list`

Cada conta Google e região geográfica possui elegibilidades diferentes. Por isso, **nunca tente ativar antes de rodar o `--list`**.

#### Passo 1: Executar a listagem
Execute no terminal:
```powershell
.\auto-trial.ps1 --list
```

#### Passo 2: Analisar a saída do terminal
O script irá inspecionar as ofertas e imprimir um relatório detalhado. Exemplo de retorno:

```text
[*] Conectando ao emulador...
[+] frida-server em execução como root (PID 3142)
[+] module.apk presente
[+] PID do Google One: 4520
[*] Script iniciado
[+] BillingClient conectado
[*] Products found: 4

  PRODUCT g1.2tb.ai.subs_variant — Google One (AI Premium)
    [0] Fase0: R$ 0,00 × P1Y (1 ciclos) ★GRÁTIS★ id=free-trial-1y tags=[ai_promo]
    [1] Fase1: R$ 96,99 × P1M (recorrente)

  PRODUCT g1.play.2tb.ai — Google One (AI Premium)
    [0] Fase0: R$ 0,00 × P3M (1 ciclos) ★GRÁTIS★ id=free-trial-3m
    [1] Fase1: R$ 96,99 × P1M (recorrente)

[*] TRIALS_FOUND 2
[+] TRIAL g1.2tb.ai.subs_variant / free-trial-1y — 12 meses grátis
[+] TRIAL g1.play.2tb.ai / free-trial-3m — 3 meses grátis

[+] Listagem concluída
```

#### Passo 3: Como interpretar as informações
Observe atentamente as linhas marcadas com `[+] TRIAL`:

1. **Identifique o Produto (`PRODUCT`)**:
   - `g1.2tb.ai.subs_variant`: É a variante de teste estendido do plano AI Premium (Gemini Advanced + 2TB/5TB). Apelido: **`pro12`**.
   - `g1.play.2tb.ai`: É o plano AI Premium padrão com teste trimestral. Apelido: **`pro`**.
   - `g1.play.20tb`: Plano Ultra de 20TB. Apelido: **`5x`**.
   - `g1.play.ai.pro`: Plano Ultra de 30TB. Apelido: **`20x`**.

2. **Identifique a Duração do Teste Gratuito**:
   - `P1Y` = **12 meses** (1 ano) grátis. Parâmetro: `--dur 12mo`.
   - `P6M` = **6 meses** grátis. Parâmetro: `--dur 6mo`.
   - `P3M` = **3 meses** grátis. Parâmetro: `--dur 3mo`.
   - `P1M` = **1 mês** grátis. Parâmetro: `--dur 1mo`.

#### Passo 4: Executar o comando de ativação correspondente

Com base no que a sua conta retornou no Passo 2, escolha a opção adequada:

- **Opção A: Se apareceu o teste de 12 meses (`g1.2tb.ai.subs_variant`) ★RECOMENDADO★**
  ```powershell
  .\auto-trial.ps1 --product pro12 --dur 12mo
  ```

- **Opção B: Se apareceu o teste de 3 meses (`g1.play.2tb.ai`)**
  ```powershell
  .\auto-trial.ps1 --product pro --dur 3mo
  ```

- **Opção C: Se apareceu um plano Ultra (5x ou 20x)**
  ```powershell
  .\auto-trial.ps1 --product 20x --dur 12mo
  ```

- **Opção D: Modo automático (pega a maior duração disponível)**
  ```powershell
  .\auto-trial.ps1
  ```

---

<a name="tabela-produtos-pt"></a>
### 🏷️ Tabela de Produtos e Apelidos

| Apelido | ID do Produto Google | Benefícios | Valor Normal | Ofertas Comuns |
|---|---|---|---|---|
| **`pro12`** ★ | `g1.2tb.ai.subs_variant` | Gemini Advanced + Armazenamento em Nuvem | $19.99/mês (R$ 96,99) | **12 meses** ou **6 meses** |
| **`pro`** | `g1.play.2tb.ai` | Gemini Advanced + Armazenamento em Nuvem | $19.99/mês (R$ 96,99) | **3 meses** |
| **`5x`** | `g1.play.20tb` | 20TB de Armazenamento | $99.99/mês | 1, 3 ou 6 meses |
| **`20x`** | `g1.play.ai.pro` | 30TB de Armazenamento + AI Pro | $199.99/mês | 1, 3 ou 12 meses |

---

<a name="confirmação-cancelamento-pt"></a>
### 🛡️ Confirmação e Cancelamento (Evitar cobrança futura)

#### Na hora da ativação:
1. Quando você rodar o comando com `--product`, o aplicativo Google One no emulador abrirá automaticamente a tela do Google Play Billing.
2. **Confirme na tela do emulador**:
   - O valor para cobrança imediata deve constar como **R$ 0,00** (ou $0.00).
   - O Google Play indicará expressamente a data em que o teste expira e quando ocorreria a primeira cobrança.
3. Clique em **Assinar** (digite a senha da conta Google se solicitado).
4. O terminal confirmará: `[+] AVALIAÇÃO ATIVADA COM SUCESSO`.

#### Para não ser cobrado após o fim do teste:
Você pode cancelar a renovação automática a qualquer momento sem perder o período já resgatado:
1. No emulador ou no seu smartphone Android, abra a **Google Play Store**.
2. Clique na sua foto de perfil no canto superior direito -> **Pagamentos e assinaturas** -> **Assinaturas**.
3. Selecione a assinatura do **Google One**.
4. Toque em **Cancelar assinatura** e confirme.
5. **Pronto!** O benefício do Google One / Gemini Advanced permanecerá ativo até o último dia do período gratuito concedido.

---

<a name="configuração-manual-pt"></a>
### ⚙️ Configuração Manual e Outros Emuladores

#### Parâmetros disponíveis

| Parâmetro | Descrição | Exemplo |
|---|---|---|
| `--list` | Apenas lista os planos elegíveis sem ativar nada | `.\auto-trial.ps1 --list` |
| `--product` | Especifica o plano (`pro12`, `pro`, `5x`, `20x` ou ID completo) | `.\auto-trial.ps1 --product pro12` |
| `--dur` | Duração desejada (`1mo`, `3mo`, `6mo`, `12mo`, `longest`) | `.\auto-trial.ps1 --dur 12mo` |
| `--port` | Especifica a porta do ADB do emulador | `.\auto-trial.ps1 --port 16384` |
| `--adb` | Caminho personalizado para o binário `adb.exe` | `.\auto-trial.ps1 --adb "C:\adb\adb.exe"` |

#### Portas comuns de emuladores
- **MuMu Player 12**: `16384` (primeira instância), `16416` (segunda instância), `16448` (terceira instância).
- **LDPlayer**: `5555`.
- **NoxPlayer**: `62001`.
- **BlueStacks**: `5555`.

#### Envio manual de arquivos (Opcional)
```powershell
# 1. Descompactar o frida-server
Expand-Archive -Path frida-server.zip -DestinationPath . -Force

# 2. Enviar o frida-server e conceder permissão de execução
adb push frida-server /data/local/tmp/frida-server
adb shell "chmod 755 /data/local/tmp/frida-server"

# 3. Enviar o módulo auxiliar BillingClient
adb push module.apk /data/local/tmp/module.apk
```

---

<a name="faq-pt"></a>
### ❓ Solução de Problemas (FAQ)

1. **`more than one device/emulator`**
   - Utilize o parâmetro `--port <PORTA>` (ex.: `.\auto-trial.ps1 --port 16384 --list`).
2. **`Não foi possível iniciar o frida-server em /data/local/tmp/frida-server`**
   - Ative o Root nas configurações do emulador e reinicie-o.
3. **`=== NO_TRIALS ===` ou `TRIALS_FOUND 0`**
   - A conta Google atual não possui ofertas ativas ou já usufruiu da promoção. Crie ou conecte outra conta Google.
4. **`=== ITEM_ALREADY_OWNED ===`**
   - A conta Google conectada já possui uma assinatura do Google One em vigor.
5. **`frida CLI não encontrado`**
   - Instale via: `pip install "frida==16.7.19" "frida-tools<14.0.0"`
