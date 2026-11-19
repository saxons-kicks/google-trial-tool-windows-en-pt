# auto-trial.ps1 — Ativação em um comando da avaliação gratuita Google AI Ultra
# Blog: https://blog.caowo.de/
# Loja de chaves: https://faka.cdkey.si/
#
# Uso:
#   .\auto-trial.ps1 --list                        # exibe todas as avaliações disponíveis
#   .\auto-trial.ps1 --product 20x --dur 12mo      # Ultra 20x, avaliação de 12 meses
#   .\auto-trial.ps1 --product 5x --dur 6mo        # Ultra 5x, avaliação de 6 meses
#   .\auto-trial.ps1 --product pro --dur 3mo        # Pro 5TB, avaliação de 3 meses
#   .\auto-trial.ps1 --product pro12 --dur 12mo     # Variante Pro 5TB, avaliação de 12 meses
#   .\auto-trial.ps1 --product 20x                  # Ultra 20x, maior duração disponível
#   .\auto-trial.ps1 --port 16416 --list            # especifica a porta ADB do MuMu
#
# Produtos: pro = g1.play.2tb.ai ($19.99), pro12 = g1.2tb.ai.subs_variant ($19.99, até 12 meses de avaliação),
#           5x = g1.play.20tb ($99.99), 20x = g1.play.ai.pro ($199.99), auto = melhor correspondência
# Durações: 1mo, 3mo, 6mo, 12mo, longest (padrão)
#
# A janela de pagamento é aberta, mas NÃO confirmada automaticamente — confirme manualmente (senha necessária).
#
# Requisitos: adb (incluso no MuMu), frida CLI, frida-server no dispositivo, module.apk no dispositivo

$ErrorActionPreference = "Stop"
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ===== Caminhos =====
$SCRIPT_DIR = $PSScriptRoot
$FRIDA_SCRIPT = if ($env:FRIDA_SCRIPT) { $env:FRIDA_SCRIPT } else { Join-Path $SCRIPT_DIR "frida-auto-trial.js" }
$FRIDA_DEVICE_PORT = 27042
$FRIDA_LOCAL_PORT = 27043
$GOOGLE_ONE_PKG = "com.google.android.apps.subscriptions.red"

# Caminhos no dispositivo (sobrescreva via variáveis de ambiente se a estrutura for diferente)
$MODULE_APK_DEVICE = if ($env:MODULE_APK_DEVICE) { $env:MODULE_APK_DEVICE } else { "/data/local/tmp/module.apk" }
$FRIDA_SERVER_PATH = if ($env:FRIDA_SERVER_PATH) { $env:FRIDA_SERVER_PATH } else { "/data/local/tmp/frida-server" }

# ===== Padrões =====
$MODE = "activate"
$TARGET = "auto"
$DURATION = "longest"
$DEVICE_PORT = ""
$ADB_OVERRIDE = ""

# ===== Auxiliares =====
function Write-Log($msg) { Write-Host "[*] $msg" }
function Write-Ok($msg)  { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Err($msg) { Write-Host "[-] $msg" -ForegroundColor Red }
function Stop-WithError($msg) { Write-Err $msg; exit 1 }

function Show-Help {
    $lines = Get-Content $PSCommandPath
    foreach ($line in $lines) {
        if ($line -match '^# ?(.*)$') {
            Write-Host $Matches[1]
        } elseif ([string]::IsNullOrWhiteSpace($line)) {
            break
        }
    }
    exit 0
}

# ===== Analisar argumentos =====
$i = 0
while ($i -lt $args.Count) {
    $arg = $args[$i]
    switch -Regex ($arg) {
        '^(-list|--list)$' {
            $MODE = "list"
            $i++
        }
        '^(-product|--product)$' {
            if ($i + 1 -ge $args.Count) { Stop-WithError "Faltando valor para $arg" }
            $TARGET = $args[$i + 1]
            $i += 2
        }
        '^(-dur|--dur|-duration|--duration)$' {
            if ($i + 1 -ge $args.Count) { Stop-WithError "Faltando valor para $arg" }
            $DURATION = $args[$i + 1]
            $i += 2
        }
        '^(-port|--port)$' {
            if ($i + 1 -ge $args.Count) { Stop-WithError "Faltando valor para $arg" }
            $DEVICE_PORT = $args[$i + 1]
            $i += 2
        }
        '^(-adb|--adb)$' {
            if ($i + 1 -ge $args.Count) { Stop-WithError "Faltando valor para $arg" }
            $ADB_OVERRIDE = $args[$i + 1]
            $i += 2
        }
        '^(-script|--script)$' {
            if ($i + 1 -ge $args.Count) { Stop-WithError "Faltando valor para $arg" }
            $FRIDA_SCRIPT = $args[$i + 1]
            $i += 2
        }
        '^(-h|--help|-help)$' {
            Show-Help
        }
        default {
            Stop-WithError "Opção desconhecida: $arg"
        }
    }
}

# ===== Detectar ADB automaticamente =====
function Find-Adb {
    if ($ADB_OVERRIDE) {
        if (Test-Path -LiteralPath $ADB_OVERRIDE -PathType Leaf) { return $ADB_OVERRIDE }
        Stop-WithError "adb especificado não encontrado: $ADB_OVERRIDE"
    }
    # 1. Variável de ambiente explícita
    if ($env:ADB_PATH -and (Test-Path -LiteralPath $env:ADB_PATH -PathType Leaf)) {
        return $env:ADB_PATH
    }
    # 2. PATH
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    # 3. Locais conhecidos do adb no Windows (MuMu e Android SDK)
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:PROGRAMFILES\Android\android-sdk\platform-tools\adb.exe",
        "$env:ProgramFiles\Netease\MuMuPlayer-12.0\shell\adb.exe",
        "$env:ProgramFiles\Netease\MuMu Player 12\shell\adb.exe",
        "$env:ProgramFiles\Netease\MuMuPlayerGlobal-12.0\shell\adb.exe",
        "$env:ProgramFiles\Netease\MuMuPlayer\shell\adb.exe",
        "${env:ProgramFiles(x86)}\Netease\MuMuPlayer-12.0\shell\adb.exe",
        "${env:ProgramFiles(x86)}\Netease\MuMuPlayer\shell\adb.exe",
        "C:\Program Files\Netease\MuMuPlayer-12.0\shell\adb.exe",
        "C:\Program Files\Netease\MuMu Player 12\shell\adb.exe",
        "C:\Program Files\Netease\MuMuPlayerGlobal-12.0\shell\adb.exe",
        "D:\Program Files\Netease\MuMuPlayer-12.0\shell\adb.exe",
        "D:\Program Files\Netease\MuMu Player 12\shell\adb.exe",
        "D:\Program Files\Netease\MuMuPlayerGlobal-12.0\shell\adb.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) {
            return $c
        }
    }
    return $null
}

$ADB = Find-Adb
if (-not $ADB) {
    Stop-WithError "adb não encontrado. Instale o Android SDK / MuMu ou defina a variável de ambiente ADB_PATH"
}

# ===== Resolver apelidos dos produtos =====
switch -Regex ($TARGET) {
    '^(20x|ultra20x)$' { $TARGET = "g1.play.ai.pro" }
    '^(5x|ultra5x)$'   { $TARGET = "g1.play.20tb" }
    '^pro$'            { $TARGET = "g1.play.2tb.ai" }
    '^pro12$'          { $TARGET = "g1.2tb.ai.subs_variant" }
    '^(auto|g1\..*)$'  { } # manter como está
    default {
        Stop-WithError "Produto desconhecido: $TARGET (use pro, 5x, 20x, pro12 ou um ID de produto g1.*)"
    }
}

$script:DEVICE = ""

# ===== 1. Encontrar dispositivo MuMu =====
function Find-Device {
    if ($DEVICE_PORT) {
        $script:DEVICE = "127.0.0.1:$DEVICE_PORT"
        Write-Log "Usando dispositivo especificado $script:DEVICE"
        try { & $ADB connect $script:DEVICE *>$null } catch {}
        return
    }

    Write-Log "Procurando dispositivos MuMu..."
    # Portas do MuMu: 16384, 16416, 16448, 16480, 16512, 7555
    foreach ($port in @(16384, 16416, 16448, 16480, 16512, 7555)) {
        $out = try { & $ADB connect "127.0.0.1:$port" 2>$null } catch { "" }
        if (($out -join "`n") -match "connected") {
            $script:DEVICE = "127.0.0.1:$port"
            Write-Ok "Dispositivo encontrado em $script:DEVICE"
            return
        }
    }

    # Alternativa: verificar dispositivos já conectados
    $devs = try { & $ADB devices 2>$null } catch { @() }
    foreach ($line in $devs) {
        if ($line -notmatch "^List" -and $line -match "^(\S+)\s+device\s*$") {
            $script:DEVICE = $Matches[1]
            Write-Ok "Usando dispositivo conectado $script:DEVICE"
            return
        }
    }

    Stop-WithError "Nenhum dispositivo MuMu encontrado. Inicie o emulador ou use --port <PORTA>"
}

# ===== Detectar Frida CLI automaticamente =====
function Find-Frida {
    if ($env:FRIDA_BIN -and (Test-Path -LiteralPath $env:FRIDA_BIN -PathType Leaf)) {
        return $env:FRIDA_BIN
    }
    $candidates = @()
    $cmd = Get-Command frida -All -ErrorAction SilentlyContinue
    if ($cmd) {
        $candidates += ($cmd | ForEach-Object { $_.Source })
    }
    $pyDirs = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Python\Python*\Scripts\frida.exe", "$env:LOCALAPPDATA\Python\pythoncore-*\Scripts\frida.exe" -ErrorAction SilentlyContinue
    if ($pyDirs) {
        $candidates += ($pyDirs | ForEach-Object { $_.FullName })
    }
    $candidates = $candidates | Select-Object -Unique
    # Priorizar Frida 16.x (compatível com frida-server 16.x e com ponte Java embutida)
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) {
            $ver = try { (& $c --version 2>$null) -join "" } catch { "" }
            if ($ver.Trim() -match '^16\.') {
                return $c
            }
        }
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) {
            return $c
        }
    }
    return $null
}

# ===== 2. Configurar Frida =====
function Initialize-Frida {
    # Garantir que o adbd esteja rodando como root no MuMu
    $shell_uid = try { (& $ADB -s $script:DEVICE shell "id -u" 2>$null) -join "" } catch { "" }
    if ($shell_uid.Trim() -ne "0") {
        Write-Log "Elevando adbd para root..."
        try { & $ADB -s $script:DEVICE root *>$null } catch {}
        Start-Sleep -Seconds 2
        try { & $ADB connect $script:DEVICE *>$null } catch {}
    }

    Write-Log "Configurando redirecionamento de porta do Frida ($FRIDA_LOCAL_PORT → $FRIDA_DEVICE_PORT)..."
    try { & $ADB -s $script:DEVICE forward "tcp:$FRIDA_LOCAL_PORT" "tcp:$FRIDA_DEVICE_PORT" 2>$null | Out-Null } catch {}

    # Verificar se o frida-server está rodando e se está como root
    $fs_pid = try { (& $ADB -s $script:DEVICE shell "pidof frida-server" 2>$null) -join "" } catch { "" }
    $fs_pid = $fs_pid.Trim()

    if ($fs_pid) {
        $fs_user = try { (& $ADB -s $script:DEVICE shell "ps -o USER= -p $fs_pid" 2>$null) -join "" } catch { "" }
        if ($fs_user.Trim() -and $fs_user.Trim() -ne "root") {
            Write-Log "frida-server rodando como '$($fs_user.Trim())' (sem root); reiniciando como root..."
            try { & $ADB -s $script:DEVICE shell "kill -9 $fs_pid" 2>$null | Out-Null } catch {}
            Start-Sleep -Seconds 1
            $fs_pid = ""
        }
    }

    if (-not $fs_pid) {
        Write-Log "Iniciando frida-server como root..."
        try { & $ADB -s $script:DEVICE shell "chmod 755 $FRIDA_SERVER_PATH; $FRIDA_SERVER_PATH -D >/dev/null 2>&1 &" 2>$null | Out-Null } catch {}
        Start-Sleep -Seconds 2
        $fs_pid = try { (& $ADB -s $script:DEVICE shell "pidof frida-server" 2>$null) -join "" } catch { "" }
        $fs_pid = $fs_pid.Trim()
        if (-not $fs_pid) {
            Stop-WithError "Não foi possível iniciar o frida-server em $FRIDA_SERVER_PATH"
        }
    }
    Write-Ok "frida-server em execução como root (PID $fs_pid)"

    # Verificar module.apk
    try { & $ADB -s $script:DEVICE shell "ls $MODULE_APK_DEVICE" *>$null } catch {}
    if ($LASTEXITCODE -ne 0) {
        Stop-WithError "module.apk não encontrado em $MODULE_APK_DEVICE no dispositivo. Envie-o primeiro:`n  adb -s $script:DEVICE push module.apk $MODULE_APK_DEVICE"
    }
    Write-Ok "module.apk presente"
}

# ===== 3. Obter PID do Google One =====
function Get-GoogleOnePid {
    Write-Log "Reiniciando Google One para estado limpo..."
    try { & $ADB -s $script:DEVICE shell "am force-stop $GOOGLE_ONE_PKG" 2>$null | Out-Null } catch {}
    Start-Sleep -Seconds 1
    try { & $ADB -s $script:DEVICE shell "monkey -p $GOOGLE_ONE_PKG 1" *>$null } catch {}
    Start-Sleep -Seconds 3

    $raw_pid = try { (& $ADB -s $script:DEVICE shell "pidof $GOOGLE_ONE_PKG" 2>$null) -join " " } catch { "" }
    $raw_pid = $raw_pid.Trim()
    if (-not $raw_pid) {
        Stop-WithError "Não foi possível iniciar o Google One"
    }
    # pidof pode retornar múltiplos PIDs; pega o primeiro
    $g1_pid = ($raw_pid -split '\s+')[0]
    Write-Ok "PID do Google One: $g1_pid"
    return $g1_pid
}

# ===== 4. Aplicar configurações e executar script Frida =====
function Invoke-Frida($g1_pid) {
    $tmp_script = Join-Path ([System.IO.Path]::GetTempPath()) ".frida-run-$PID.js"
    $frida_proc = $null

    try {
        # Aplicar configuração no script
        $content = Get-Content -LiteralPath $FRIDA_SCRIPT -Raw -Encoding UTF8
        $content = $content -replace '(?m)^var MODE = .*', "var MODE = `"$MODE`";"
        $content = $content -replace '(?m)^var TARGET_PRODUCT = .*', "var TARGET_PRODUCT = `"$TARGET`";"
        $content = $content -replace '(?m)^var PREFER_DURATION = .*', "var PREFER_DURATION = `"$DURATION`";"
        $content = $content -replace '(?m)^var MODULE_APK = .*', "var MODULE_APK = `"$MODULE_APK_DEVICE`";"
        [System.IO.File]::WriteAllText($tmp_script, $content, (New-Object System.Text.UTF8Encoding($false)))

        Write-Log "Injetando (modo=$MODE alvo=$TARGET duração=$DURATION)..."

        # Limpar logcat ANTES da injeção para não perder saídas iniciais
        try { & $ADB -s $script:DEVICE logcat -c 2>$null | Out-Null } catch {}

        # Verificar se frida CLI existe
        $fridaBin = Find-Frida
        if (-not $fridaBin) {
            Stop-WithError "frida CLI não encontrado. Instale com: pip install frida==16.7.19 `"frida-tools<14.0.0`""
        }

        # Executar frida em segundo plano mantendo stdin aberto para o REPL não encerrar imediatamente
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $fridaBin
        $psi.Arguments = "-H 127.0.0.1:$FRIDA_LOCAL_PORT -p $g1_pid -l `"$tmp_script`" -q -t 120"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $frida_proc = [System.Diagnostics.Process]::Start($psi)

        # Consultar logcat em loop
        Write-Log "Aguardando resultados..."
        $elapsed = 0
        $max_wait = 60
        $got_terminal = $false
        $seen_lines = 0

        while ($elapsed -lt $max_wait) {
            Start-Sleep -Seconds 2
            $elapsed += 2

            if ($frida_proc.HasExited -and $seen_lines -eq 0) {
                $frida_out = ($frida_proc.StandardOutput.ReadToEnd() + "`n" + $frida_proc.StandardError.ReadToEnd()).Trim()
                if ($frida_out) {
                    Write-Err "Frida encerrou com erro:`n$frida_out"
                    $got_terminal = $true
                    break
                }
            }

            $raw_lines = try { & $ADB -s $script:DEVICE logcat -d -s "AutoTrial:*" 2>$null } catch { @() }
            if (-not $raw_lines) { continue }

            $lines = @()
            foreach ($line in $raw_lines) {
                if ($line -match 'AutoTrial\s*: (.*)$') {
                    $lines += $Matches[1].TrimEnd("`r")
                }
            }

            $total_lines = $lines.Count
            if ($total_lines -le $seen_lines) { continue }

            $new_lines = $lines[$seen_lines..($total_lines - 1)]
            $seen_lines = $total_lines

            foreach ($msg in $new_lines) {
                if ($msg -like "=== AUTO_TRIAL_START*") { Write-Log "Script iniciado" }
                elseif ($msg -eq "BillingClient connected") { Write-Ok "BillingClient conectado" }
                elseif ($msg -like "Products found:*") { Write-Log $msg }
                elseif ($msg -like "PRODUCT*") { Write-Host ""; Write-Host "  $msg" }
                elseif ($msg.StartsWith("  [")) { Write-Host "    $msg" }
                elseif ($msg -like "  TRIAL *") { Write-Ok $msg }
                elseif ($msg -like "TRIALS_FOUND*") { Write-Host ""; Write-Log $msg }
                elseif ($msg -like "SELECTED*") { Write-Ok $msg }
                elseif ($msg -like "Waiting for Activity*") { Write-Log "Estabilizando Activity..." }
                elseif ($msg -like "BILLING_FLOW_LAUNCHED*") {
                    Write-Ok "Janela de pagamento aberta — confirme manualmente (Ctrl-C ao concluir)"
                    $got_terminal = $true
                }
                elseif ($msg -eq "=== TRIAL_ACTIVATED ===") {
                    Write-Host ""
                    Write-Ok "AVALIAÇÃO ATIVADA COM SUCESSO"
                    Write-Host ""
                    Write-Host "  Renova automaticamente após a avaliação. Cancele antes do vencimento."
                    Write-Host ""
                    $got_terminal = $true
                }
                elseif ($msg -eq "=== USER_CANCELLED ===") {
                    Write-Err "Cancelado pelo usuário"
                    $got_terminal = $true
                }
                elseif ($msg -eq "=== ITEM_ALREADY_OWNED ===") {
                    Write-Err "Já possui assinatura"
                    $got_terminal = $true
                }
                elseif ($msg -like "=== PURCHASE_FAILED*") {
                    Write-Err $msg
                    $got_terminal = $true
                }
                elseif ($msg -eq "=== LIST_COMPLETE ===") {
                    Write-Host ""
                    Write-Ok "Listagem concluída"
                    $got_terminal = $true
                }
                elseif ($msg -eq "=== NO_TRIALS ===") {
                    Write-Err "Nenhuma oferta de avaliação encontrada"
                    $got_terminal = $true
                }
                elseif ($msg -eq "=== SELECT_FAILED ===" -or $msg -eq "=== NO_ACTIVITY ===" -or $msg -like "=== CONNECT_FAILED*" -or $msg -like "=== LAUNCH_ERROR*") {
                    Write-Err $msg
                    $got_terminal = $true
                }
            }

            if ($got_terminal) { break }
        }

        if (-not $got_terminal) {
            Write-Err "Tempo esgotado após ${max_wait}s — verifique o logcat manualmente: adb logcat -d -s AutoTrial:*"
        }
    } finally {
        if ($frida_proc -and -not $frida_proc.HasExited) {
            try { Stop-Process -Id $frida_proc.Id -Force -ErrorAction SilentlyContinue } catch {}
        }
        if (Test-Path -LiteralPath $tmp_script) {
            Remove-Item -LiteralPath $tmp_script -Force -ErrorAction SilentlyContinue
        }
    }
}

# ===== Principal =====
Write-Host "=== Google AI Ultra Trial Tool ==="
Write-Host "Blog: https://blog.caowo.de/"
Write-Host "Loja de chaves: https://faka.cdkey.si/"
Write-Host ""

if (-not (Test-Path -LiteralPath $FRIDA_SCRIPT -PathType Leaf)) {
    Stop-WithError "Script Frida não encontrado: $FRIDA_SCRIPT"
}

Find-Device
Initialize-Frida
$g1_pid = Get-GoogleOnePid

Write-Host ""
Invoke-Frida $g1_pid
