# Google AI / Google One Trial Tool 🚀

Ferramenta automatizada para consulta e ativação de avaliações gratuitas ocultas ($0 / R$ 0,00) do **Google One** e **Gemini Advanced** através de injeção na API oficial `BillingClient` do Google Play via Frida.

---

## 📌 Sumário
1. [Como funciona](#-como-funciona)
2. [Arquivos inclusos no projeto](#-arquivos-inclusos-no-projeto)
3. [Pré-requisitos](#-pré-requisitos)
4. [Início Rápido (Quick Start)](#-início-rápido-quick-start)
5. [Tutorial Passo a Passo: Como escolher conforme o `--list`](#-tutorial-passo-a-passo-como-escolher-conforme-o---list)
6. [Tabela de Produtos e Apelidos](#-tabela-de-produtos-e-apelidos)
7. [Confirmação e Cancelamento (Evitar cobrança futura)](#-confirmação-e-cancelamento-evitar-cobrança-futura)
8. [Configuração Manual e Outros Emuladores](#-configuração-manual-e-outros-emuladores)
9. [Solução de Problemas (FAQ)](#-solução-de-problemas-faq)

---

## 💡 Como funciona

Os servidores da Google Play Store possuem ofertas promocionais de avaliação gratuita (ex.: 12 meses, 6 meses ou 3 meses grátis) vinculadas a certos IDs de produto do Google One. No entanto, o aplicativo do Google One e a interface web convencional exibem apenas planos com cobrança imediata ou períodos reduzidos de teste.

Esta ferramenta:
1. Conecta-se ao emulador Android onde o Google One e a Play Store estão configurados.
2. Utiliza o **Frida** para carregar a biblioteca `BillingClient` oficial (fornecida pelo `module.apk`).
3. Consulta diretamente os servidores de faturamento da Google Play para descobrir todas as ofertas de $0 elegíveis para a conta logada.
4. Ao selecionar uma oferta, dispara a janela nativa oficial do Google Play no emulador com valor **R$ 0,00**, permitindo que você assine de forma legítima e segura.

> [!NOTE]
> O script **não** realiza compras automáticas às escuras: ele apenas abre a tela oficial do Google Play. Você confirma manualmente com a senha ou biometria da sua conta Google dentro do emulador.

---

## 📦 Arquivos inclusos no projeto

| Arquivo | Função |
|---|---|
| `module.apk` | APK contendo a biblioteca oficial `com.android.billingclient`, necessária para a comunicação com a Play Store. |
| `frida-server.zip` | Binário compactado do servidor Frida (versão 16.7.19 x86_64 para emuladores Android). Os scripts descompactam e enviam automaticamente ao emulador se necessário. |
| `frida-auto-trial.js` | Script de hook em JavaScript que faz a ponte com o `BillingClient` e inicia o fluxo de assinatura. |
| `auto-trial.ps1` | Script principal para **Windows** (PowerShell) com detecção automática do emulador, envio dos arquivos e execução. |
| `auto-trial.sh` | Script principal para **Linux / macOS** (Bash) com detecção automática do emulador e execução. |

---

## 📋 Pré-requisitos

Antes de executar a ferramenta, certifique-se de cumprir os seguintes requisitos:

### 1. Emulador Android com Root
- **Recomendado**: [MuMu Player 12](https://www.mumuplayer.com/) (ou LDPlayer 9 / BlueStacks / Nox / Celular físico com root).
- **Habilitar Root**: Nas configurações do emulador, certifique-se de que a opção de **Root (Permissão de Superusuário)** está ativada.

### 2. Conta Google e Aplicativos no Emulador
- **Google Play Store**: Conecte uma conta Google.
- **Forma de Pagamento**: A conta precisa ter uma forma de pagamento válida cadastrada na Play Store (cartão de crédito/débito). Mesmo para ofertas de $0,00, a Google Play exige um método cadastrado para autorização.
  > [!TIP]
  > Para sua segurança, utilize um cartão virtual com limite baixo ou bloqueado temporariamente após o teste.
- **Sem assinatura ativa**: A conta **não** deve possuir uma assinatura ativa do Google One no momento (promoções de avaliação são destinadas a novos assinantes ou contas sem plano ativo).
- **Google One Instalado**: Instale o aplicativo **Google One** diretamente pela Play Store dentro do emulador e abra-o uma vez para autenticar sua conta.

### 3. Dependências no Computador (Host)
- **Python**: Instale o Python (3.9 a 3.12).
- **Frida CLI**: Instale as ferramentas do Frida versão 16.x no terminal do seu computador:
  ```bash
  pip install "frida==16.7.19" "frida-tools<14.0.0"
  ```
  *(Recomenda-se a versão 16.7.19 para total compatibilidade com o binário `frida-server` incluso).*
- **ADB (Android Debug Bridge)**: Já vem embutido em emuladores como o MuMu Player. Se não estiver no seu `PATH`, o script tentará localizar os caminhos comuns automaticamente.

---

## 🚀 Início Rápido (Quick Start)

Com o emulador aberto, o root ativado e o app Google One instalado:

### No Windows (PowerShell)
Abra o PowerShell na pasta deste projeto:
```powershell
# Libera a execução de scripts locais nesta sessão do PowerShell (se necessário)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 1º Passo essencial: Listar as avaliações gratuitas disponíveis para a sua conta
.\auto-trial.ps1 --list
```

### No Linux / macOS (Bash)
Abra o terminal na pasta deste projeto:
```bash
chmod +x auto-trial.sh

# 1º Passo essencial: Listar as avaliações gratuitas disponíveis para a sua conta
./auto-trial.sh --list
```

> [!IMPORTANT]
> Os scripts detectam automaticamente se o `frida-server` e o `module.apk` já estão no emulador. Se não estiverem, os arquivos incluídos na pasta do projeto serão transferidos automaticamente para `/data/local/tmp/`!

---

## 🎓 Tutorial Passo a Passo: Como escolher conforme o `--list`

Cada conta Google e região geográfica possui elegibilidades diferentes. Por isso, **nunca tente ativar antes de rodar o `--list`**.

### Passo 1: Executar a listagem
Execute no terminal:
```powershell
.\auto-trial.ps1 --list
```

### Passo 2: Analisar a saída do terminal
O script irá inspecionar as ofertas e imprimir um relatório detalhado. Veja um exemplo real de retorno:

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

### Passo 3: Como interpretar as informações
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

### Passo 4: Executar o comando de ativação correspondente

Com base no que a sua conta retornou no Passo 2, escolha a opção adequada:

#### Opção A: Se apareceu o teste de 12 meses (`g1.2tb.ai.subs_variant`) ★RECOMENDADO★
```powershell
.\auto-trial.ps1 --product pro12 --dur 12mo
```

#### Opção B: Se apareceu o teste de 3 meses (`g1.play.2tb.ai`)
```powershell
.\auto-trial.ps1 --product pro --dur 3mo
```

#### Opção C: Se apareceu um plano Ultra (5x ou 20x)
```powershell
# Exemplo para 20x de 12 meses:
.\auto-trial.ps1 --product 20x --dur 12mo

# Exemplo para 5x de 6 meses:
.\auto-trial.ps1 --product 5x --dur 6mo
```

#### Opção D: Modo automático (pega a maior duração disponível)
Se quiser que o script escolha sozinho a melhor oferta com o maior tempo de gratuidade:
```powershell
.\auto-trial.ps1
```

---

## 🏷️ Tabela de Produtos e Apelidos

| Apelido | ID do Produto Google | Benefícios | Valor Normal | Ofertas Comuns |
|---|---|---|---|---|
| **`pro12`** ★ | `g1.2tb.ai.subs_variant` | Gemini Advanced + Armazenamento em Nuvem | $19.99/mês (R$ 96,99) | **12 meses** ou **6 meses** |
| **`pro`** | `g1.play.2tb.ai` | Gemini Advanced + Armazenamento em Nuvem | $19.99/mês (R$ 96,99) | **3 meses** |
| **`5x`** | `g1.play.20tb` | 20TB de Armazenamento | $99.99/mês | 1, 3 ou 6 meses |
| **`20x`** | `g1.play.ai.pro` | 30TB de Armazenamento + AI Pro | $199.99/mês | 1, 3 ou 12 meses |

---

## 🛡️ Confirmação e Cancelamento (Evitar cobrança futura)

### Na hora da ativação:
1. Quando você rodar o comando com `--product`, o aplicativo Google One no emulador abrirá automaticamente a tela do Google Play Billing.
2. **Confirme na tela do emulador**:
   - O valor para cobrança imediata deve constar como **R$ 0,00** (ou $0.00).
   - O Google Play indicará expressamente a data em que o teste expira e quando ocorreria a primeira cobrança.
3. Clique em **Assinar** (digite a senha da conta Google se solicitado).
4. O terminal confirmará: `[+] AVALIAÇÃO ATIVADA COM SUCESSO`.

### Para não ser cobrado após o fim do teste:
Você pode cancelar a renovação automática a qualquer momento sem perder o período já resgatado:
1. No emulador ou no seu smartphone Android, abra a **Google Play Store**.
2. Clique na sua foto de perfil no canto superior direito -> **Pagamentos e assinaturas** -> **Assinaturas**.
3. Selecione a assinatura do **Google One**.
4. Toque em **Cancelar assinatura** e confirme.
5. **Pronto!** O benefício do Google One / Gemini Advanced permanecerá ativo até o último dia do período gratuito concedido.

---

## ⚙️ Configuração Manual e Outros Emuladores

Caso você use outro emulador ou tenha mais de uma instância aberta, use os parâmetros abaixo:

### Parâmetros disponíveis

| Parâmetro | Descrição | Exemplo |
|---|---|---|
| `--list` | Apenas lista os planos elegíveis sem ativar nada | `.\auto-trial.ps1 --list` |
| `--product` | Especifica o plano (`pro12`, `pro`, `5x`, `20x` ou ID completo) | `.\auto-trial.ps1 --product pro12` |
| `--dur` | Duração desejada (`1mo`, `3mo`, `6mo`, `12mo`, `longest`) | `.\auto-trial.ps1 --dur 12mo` |
| `--port` | Especifica a porta do ADB do emulador | `.\auto-trial.ps1 --port 16384` |
| `--adb` | Caminho personalizado para o binário `adb.exe` | `.\auto-trial.ps1 --adb C:\adb\adb.exe` |

### Portas comuns de emuladores
- **MuMu Player 12**: `16384` (primeira instância), `16416` (segunda instância), `16448` (terceira instância).
- **LDPlayer**: `5555`.
- **NoxPlayer**: `62001`.
- **BlueStacks**: `5555`.

### Envio manual de arquivos (Opcional)
Se preferir descompactar e enviar os binários manualmente para o dispositivo via ADB:
```bash
# 1. Descompactar o frida-server (se ainda não tiver feito)
# No Windows PowerShell:
Expand-Archive -Path frida-server.zip -DestinationPath . -Force
# No Linux / macOS:
unzip -o frida-server.zip

# 2. Enviar o frida-server e conceder permissão de execução
adb push frida-server /data/local/tmp/frida-server
adb shell "chmod 755 /data/local/tmp/frida-server"

# 3. Enviar o módulo auxiliar BillingClient
adb push module.apk /data/local/tmp/module.apk
```

---

## ❓ Solução de Problemas (FAQ)

### 1. `more than one device/emulator`
- **Causa**: Você tem mais de um emulador ou celular conectado via ADB ao mesmo tempo.
- **Solução**: Use o parâmetro `--port <PORTA>` (ex.: `.\auto-trial.ps1 --port 16384 --list`) para direcionar o comando exatamente para o emulador desejado.

### 2. `Não foi possível iniciar o frida-server em /data/local/tmp/frida-server`
- **Causa**: O emulador não está com permissão de Root habilitada ou o arquivo está sem permissão de execução.
- **Solução**: Ative o Root nas configurações do emulador, reinicie-o e execute novamente. Se necessário, execute manualmente: `adb shell "chmod 755 /data/local/tmp/frida-server"`.

### 3. `=== NO_TRIALS ===` ou `TRIALS_FOUND 0`
- **Causa**: A conta Google atual não possui ofertas de teste gratuito ativas ou já usufruiu da promoção anteriormente.
- **Solução**: Crie ou conecte outra conta Google no emulador que nunca tenha assinado o Google One antes e repita o `--list`.

### 4. `=== ITEM_ALREADY_OWNED ===`
- **Causa**: A conta Google conectada já possui uma assinatura do Google One em vigor.
- **Solução**: É necessário utilizar uma conta sem assinatura ativa para resgatar avaliações gratuitas.

### 5. `frida CLI não encontrado`
- **Causa**: O pacote do Frida não está instalado no Python do seu sistema.
- **Solução**: Execute no prompt/terminal:
  ```bash
  pip install "frida==16.7.19" "frida-tools<14.0.0"
  ```
