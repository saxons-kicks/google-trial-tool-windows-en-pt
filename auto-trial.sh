#!/usr/bin/env bash
# auto-trial.sh — Ativação automatizada de avaliações gratuitas do Google One / Gemini Advanced
#
# Uso:
#   ./auto-trial.sh --list                        # exibe todas as avaliações disponíveis
#   ./auto-trial.sh --product 20x --dur 12mo      # Ultra 20x, avaliação de 12 meses
#   ./auto-trial.sh --product 5x --dur 6mo        # Ultra 5x, avaliação de 6 meses
#   ./auto-trial.sh --product pro --dur 3mo        # Pro 5TB, avaliação de 3 meses
#   ./auto-trial.sh --product pro12 --dur 12mo     # Variante Pro 5TB, avaliação de 12 meses
#   ./auto-trial.sh --product 20x                  # Ultra 20x, maior duração disponível
#   ./auto-trial.sh --port 16416 --list            # especifica a porta ADB do MuMu
#
# Produtos: pro = g1.play.2tb.ai ($19.99), pro12 = g1.2tb.ai.subs_variant ($19.99, até 12 meses de avaliação),
#           5x = g1.play.20tb ($99.99), 20x = g1.play.ai.pro ($199.99), auto = melhor correspondência
# Durações: 1mo, 3mo, 6mo, 12mo, longest (padrão)
#
# A janela de pagamento é aberta, mas NÃO confirmada automaticamente — confirme manualmente (senha necessária).
#
# Requisitos: adb (incluso no MuMu), frida CLI, frida-server no dispositivo, module.apk no dispositivo

set -euo pipefail

# ===== Caminhos =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRIDA_SCRIPT="${FRIDA_SCRIPT:-$SCRIPT_DIR/frida-auto-trial.js}"
FRIDA_DEVICE_PORT=27042
FRIDA_LOCAL_PORT=27043
GOOGLE_ONE_PKG="com.google.android.apps.subscriptions.red"

# Caminhos no dispositivo (sobrescreva via variáveis de ambiente se a estrutura for diferente)
MODULE_APK_DEVICE="${MODULE_APK_DEVICE:-/data/local/tmp/module.apk}"
FRIDA_SERVER_PATH="${FRIDA_SERVER_PATH:-/data/local/tmp/frida-server}"

# ===== Padrões =====
MODE="activate"
TARGET="auto"
DURATION="longest"
DEVICE_PORT=""

# ===== Detectar ADB automaticamente =====
find_adb() {
    # 1. Variável de ambiente explícita
    if [[ -n "${ADB_PATH:-}" ]] && [[ -x "$ADB_PATH" ]]; then
        echo "$ADB_PATH"; return
    fi
    # 2. PATH
    if command -v adb >/dev/null 2>&1; then
        command -v adb; return
    fi
    # 3. Locais conhecidos do adb — testa cada um diretamente
    #    glob/find falham em caminhos traduzidos de C:/; -x em caminhos completos funciona
    local candidates=(
        # MuMu — pacote aninhado (MuMuPlayer.app/Contents/MacOS/MuMuEmulator.app/…)
        "/Applications/MuMuPlayer.app/Contents/MacOS/MuMuEmulator.app/Contents/MacOS/tools/adb"
        "$HOME/Applications/MuMuPlayer.app/Contents/MacOS/MuMuEmulator.app/Contents/MacOS/tools/adb"
        "/Applications/MuMuPlayer.app/Contents/MacOS/MuMuEmulator.app/Contents/MacOS/tools/adb"
        # MuMu — pacote plano (tools diretamente sob MuMuPlayer.app)
        "/Applications/MuMuPlayer.app/Contents/MacOS/tools/adb"
        "$HOME/Applications/MuMuPlayer.app/Contents/MacOS/tools/adb"
        "/Applications/MuMuPlayer.app/Contents/MacOS/tools/adb"
        # MuMu Pro / nomes alternativos
        "/Applications/MuMuPlayerPro.app/Contents/MacOS/MuMuEmulator.app/Contents/MacOS/tools/adb"
        "/Applications/MuMu Player.app/Contents/MacOS/MuMuEmulator.app/Contents/MacOS/tools/adb"
        "/Applications/MuMuPlayerPro.app/Contents/MacOS/tools/adb"
        "/Applications/MuMu Player.app/Contents/MacOS/tools/adb"
        # Android SDK
        "$HOME/Library/Android/sdk/platform-tools/adb"
        "/usr/local/share/android-sdk/platform-tools/adb"
        "$HOME/Android/Sdk/platform-tools/adb"
        "${LOCALAPPDATA:-_}/Android/Sdk/platform-tools/adb.exe"
        "${PROGRAMFILES:-_}/Android/android-sdk/platform-tools/adb.exe"
    )
    for c in "${candidates[@]}"; do
        [[ -x "$c" ]] && { echo "$c"; return; }
    done
    return 1
}
ADB="$(find_adb)" || { echo "[-] adb não encontrado. Instale o Android SDK ou defina ADB_PATH"; exit 1; }

# ===== Analisar argumentos =====
while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)        MODE="list"; shift ;;
        --product)     TARGET="$2"; shift 2 ;;
        --dur|--duration) DURATION="$2"; shift 2 ;;
        --port)        DEVICE_PORT="$2"; shift 2 ;;
        --adb)         ADB="$2"; shift 2 ;;
        --script)      FRIDA_SCRIPT="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "Opção desconhecida: $1"; exit 1 ;;
    esac
done

# ===== Resolver apelidos dos produtos =====
case "$TARGET" in
    20x|20X|ultra20x) TARGET="g1.play.ai.pro" ;;
    5x|5X|ultra5x)    TARGET="g1.play.20tb" ;;
    pro|Pro|PRO)      TARGET="g1.play.2tb.ai" ;;
    pro12|Pro12|PRO12) TARGET="g1.2tb.ai.subs_variant" ;;
    auto|g1.*)        ;; # manter como está
    *) echo "Produto desconhecido: $TARGET (use pro, 5x, 20x, pro12 ou um ID de produto g1.*)"; exit 1 ;;
esac

# ===== Auxiliares =====
log()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
err()  { echo "[-] $*" >&2; }
die()  { err "$*"; exit 1; }

# ===== 1. Encontrar dispositivo MuMu =====
detect_device() {
    if [[ -n "$DEVICE_PORT" ]]; then
        DEVICE="127.0.0.1:$DEVICE_PORT"
        log "Usando dispositivo especificado $DEVICE"
        "$ADB" connect "$DEVICE" >/dev/null 2>&1 || true
        return
    fi

    log "Procurando dispositivos MuMu..."
    # Portas do MuMu: 16384, 16416, 16448, 16480, ...
    for port in 16384 16416 16448 16480 16512; do
        if "$ADB" connect "127.0.0.1:$port" 2>/dev/null | grep -q "connected"; then
            DEVICE="127.0.0.1:$port"
            ok "Dispositivo encontrado em $DEVICE"
            return
        fi
    done

    # Alternativa: verificar dispositivos já conectados
    local dev
    dev=$("$ADB" devices 2>/dev/null | grep -v "^List" | grep "device$" | head -1 | awk '{print $1}')
    if [[ -n "$dev" ]]; then
        DEVICE="$dev"
        ok "Usando dispositivo conectado $DEVICE"
        return
    fi

    die "Nenhum dispositivo MuMu encontrado. Inicie o emulador ou use --port <PORTA>"
}

# ===== 2. Configurar Frida =====
setup_frida() {
    # Garantir que o adbd esteja rodando como root no MuMu
    local shell_uid
    shell_uid=$("$ADB" -s "$DEVICE" shell "id -u" 2>/dev/null | tr -d '\r\n' || echo "")
    if [[ "$shell_uid" != "0" ]]; then
        log "Elevando adbd para root..."
        "$ADB" -s "$DEVICE" root >/dev/null 2>&1 || true
        sleep 2
        "$ADB" connect "$DEVICE" >/dev/null 2>&1 || true
    fi

    log "Configurando redirecionamento de porta do Frida ($FRIDA_LOCAL_PORT → $FRIDA_DEVICE_PORT)..."
    "$ADB" -s "$DEVICE" forward "tcp:$FRIDA_LOCAL_PORT" "tcp:$FRIDA_DEVICE_PORT" 2>/dev/null || true

    # Verificar se o frida-server está rodando e se está como root
    local fs_pid
    fs_pid=$("$ADB" -s "$DEVICE" shell "pidof frida-server" 2>/dev/null | tr -d '\r\n' || echo "")
    if [[ -n "$fs_pid" ]]; then
        local fs_user
        fs_user=$("$ADB" -s "$DEVICE" shell "ps -o USER= -p $fs_pid" 2>/dev/null | tr -d '\r\n ' || echo "")
        if [[ -n "$fs_user" && "$fs_user" != "root" ]]; then
            log "frida-server rodando como '$fs_user' (sem root); reiniciando como root..."
            "$ADB" -s "$DEVICE" shell "kill -9 $fs_pid" >/dev/null 2>&1 || true
            sleep 1
            fs_pid=""
        fi
    fi

    if [[ -z "$fs_pid" ]]; then
        # Se frida-server não existir no dispositivo, envia automaticamente se presente na pasta local
        if ! "$ADB" -s "$DEVICE" shell "test -f $FRIDA_SERVER_PATH" 2>/dev/null; then
            if [[ ! -f "$SCRIPT_DIR/frida-server" && -f "$SCRIPT_DIR/frida-server.zip" ]]; then
                log "Extraindo frida-server.zip..."
                unzip -o "$SCRIPT_DIR/frida-server.zip" -d "$SCRIPT_DIR" >/dev/null 2>&1 || true
            fi
            if [[ -f "$SCRIPT_DIR/frida-server" ]]; then
                log "frida-server não encontrado no dispositivo. Enviando $SCRIPT_DIR/frida-server para $FRIDA_SERVER_PATH..."
                "$ADB" -s "$DEVICE" push "$SCRIPT_DIR/frida-server" "$FRIDA_SERVER_PATH" >/dev/null 2>&1 || true
                "$ADB" -s "$DEVICE" shell "chmod 755 $FRIDA_SERVER_PATH" >/dev/null 2>&1 || true
            fi
        fi

        log "Iniciando frida-server como root..."
        "$ADB" -s "$DEVICE" shell "chmod 755 $FRIDA_SERVER_PATH; $FRIDA_SERVER_PATH -D >/dev/null 2>&1 &"
        sleep 2
        fs_pid=$("$ADB" -s "$DEVICE" shell "pidof frida-server" 2>/dev/null | tr -d '\r\n' || echo "")
        [[ -n "$fs_pid" ]] || die "Não foi possível iniciar o frida-server em $FRIDA_SERVER_PATH"
    fi
    ok "frida-server em execução como root (PID $fs_pid)"

    # Verificar module.apk (envia automaticamente se presente na pasta local)
    if ! "$ADB" -s "$DEVICE" shell "test -f $MODULE_APK_DEVICE" 2>/dev/null; then
        if [[ -f "$SCRIPT_DIR/module.apk" ]]; then
            log "module.apk não encontrado no dispositivo. Enviando $SCRIPT_DIR/module.apk para $MODULE_APK_DEVICE..."
            "$ADB" -s "$DEVICE" push "$SCRIPT_DIR/module.apk" "$MODULE_APK_DEVICE" >/dev/null 2>&1 || true
        fi
    fi

    if ! "$ADB" -s "$DEVICE" shell "ls $MODULE_APK_DEVICE" >/dev/null 2>&1; then
        die "module.apk não encontrado em $MODULE_APK_DEVICE no dispositivo. Envie-o primeiro:\n  \"\$ADB\" -s $DEVICE push module.apk $MODULE_APK_DEVICE"
    fi
    ok "module.apk presente"
}

# ===== 3. Obter PID do Google One =====
get_pid() {
    # Forçar reinicialização do Google One para um estado limpo de Activity
    # Todas as mensagens de status vão para stderr — apenas o PID vai para stdout
    log "Reiniciando Google One para estado limpo..." >&2
    "$ADB" -s "$DEVICE" shell "am force-stop $GOOGLE_ONE_PKG" 2>/dev/null || true
    sleep 1
    "$ADB" -s "$DEVICE" shell "monkey -p $GOOGLE_ONE_PKG 1" >/dev/null 2>&1
    sleep 3
    local pid
    pid=$("$ADB" -s "$DEVICE" shell "pidof $GOOGLE_ONE_PKG" 2>/dev/null || echo "")
    [[ -n "$pid" ]] || die "Não foi possível iniciar o Google One"
    # pidof pode retornar múltiplos PIDs; pega o primeiro
    pid=$(echo "$pid" | tr -s ' ' '\n' | head -1 | tr -d '\r\n')
    ok "PID do Google One: $pid" >&2
    echo "$pid"
}

# ===== 4. Aplicar configurações e executar script Frida =====
run_frida() {
    local pid="$1"
    local tmp_script
    tmp_script="/tmp/.frida-run-$$.js"

    # Aplicar configuração no script
    sed \
        -e "s|^var MODE = .*|var MODE = \"$MODE\";|" \
        -e "s|^var TARGET_PRODUCT = .*|var TARGET_PRODUCT = \"$TARGET\";|" \
        -e "s|^var PREFER_DURATION = .*|var PREFER_DURATION = \"$DURATION\";|" \
        -e "s|^var MODULE_APK = .*|var MODULE_APK = \"$MODULE_APK_DEVICE\";|" \
        "$FRIDA_SCRIPT" > "$tmp_script"

    log "Injetando (modo=$MODE alvo=$TARGET duração=$DURATION)..."

    # Limpar logcat ANTES da injeção para não perder saídas iniciais
    "$ADB" -s "$DEVICE" logcat -c 2>/dev/null || true

    # Executar frida em segundo plano mantendo stdin aberto para o REPL não encerrar imediatamente
    tail -f /dev/null | frida -H "127.0.0.1:$FRIDA_LOCAL_PORT" -p "$pid" -l "$tmp_script" -q -t 120 \
        >/dev/null 2>&1 &
    FRIDA_PID=$!

    # Consultar logcat em loop em vez de pipe contínuo (evita travamento indefinido)
    log "Aguardando resultados..."
    local elapsed=0
    local max_wait=60
    local got_terminal=false
    local seen_lines=0

    while [[ $elapsed -lt $max_wait ]]; do
        sleep 2
        elapsed=$((elapsed + 2))

        # Ler todas as mensagens do AutoTrial até o momento
        local output
        output=$("$ADB" -s "$DEVICE" logcat -d -s "AutoTrial:*" 2>/dev/null \
            | sed 's/^.*AutoTrial *: //')

        [[ -z "$output" ]] && continue

        # Pular linhas já impressas
        local total_lines
        total_lines=$(echo "$output" | wc -l)
        if [[ $total_lines -le $seen_lines ]]; then continue; fi
        local new_output
        new_output=$(echo "$output" | tail -n +"$((seen_lines + 1))")
        seen_lines=$total_lines

        # Processar apenas linhas novas
        while IFS= read -r msg; do
            case "$msg" in
                "=== AUTO_TRIAL_START"*)  log "Script iniciado" ;;
                "BillingClient connected") ok "BillingClient conectado" ;;
                "Products found:"*)       log "$msg" ;;
                PRODUCT*)                 echo ""; echo "  $msg" ;;
                "  ["*)                   echo "    $msg" ;;
                "  TRIAL "*)              ok "$msg" ;;
                TRIALS_FOUND*)            echo ""; log "$msg" ;;
                SELECTED*)                ok "$msg" ;;
                "Waiting for Activity"*)  log "Estabilizando Activity..." ;;
                BILLING_FLOW_LAUNCHED*)
                    ok "Janela de pagamento aberta — confirme manualmente (Ctrl-C ao concluir)"
                    got_terminal=true ;;
                "=== TRIAL_ACTIVATED ===")
                    echo ""; ok "AVALIAÇÃO ATIVADA COM SUCESSO"
                    echo ""; echo "  Renova automaticamente após a avaliação. Cancele antes do vencimento."
                    echo ""; got_terminal=true ;;
                "=== USER_CANCELLED ===")
                    err "Cancelado pelo usuário"; got_terminal=true ;;
                "=== ITEM_ALREADY_OWNED ===")
                    err "Já possui assinatura"; got_terminal=true ;;
                "=== PURCHASE_FAILED"*)
                    err "$msg"; got_terminal=true ;;
                "=== LIST_COMPLETE ===")
                    echo ""; ok "Listagem concluída"; got_terminal=true ;;
                "=== NO_TRIALS ===")
                    err "Nenhuma oferta de avaliação encontrada"; got_terminal=true ;;
                "=== SELECT_FAILED ==="|\
                "=== NO_ACTIVITY ==="|\
                "=== CONNECT_FAILED"*|\
                "=== LAUNCH_ERROR"*)
                    err "$msg"; got_terminal=true ;;
            esac
        done <<< "$new_output"

        $got_terminal && break
    done

    if ! $got_terminal; then
        err "Tempo esgotado após ${max_wait}s — verifique o logcat manualmente: adb logcat -d -s AutoTrial:*"
    fi

    rm -f "$tmp_script"
}

# ===== Limpeza =====
cleanup() {
    [[ -n "${FRIDA_PID:-}" ]] && kill "$FRIDA_PID" 2>/dev/null || true
}
trap cleanup EXIT

# ===== Principal =====
main() {
    echo "=== Google AI Ultra Trial Tool ==="
    echo "Blog: https://blog.caowo.de/"
    echo "Loja de chaves: https://faka.cdkey.si/"
    echo ""

    detect_device
    setup_frida
    local pid
    pid=$(get_pid)

    [[ ! -f "$FRIDA_SCRIPT" ]] && die "Script Frida não encontrado: $FRIDA_SCRIPT"

    echo ""
    run_frida "$pid"
}

main
