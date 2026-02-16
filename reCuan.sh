#!/data/data/com.termux/files/usr/bin/bash
# ROBLOX MONITOR + PERFORMANCE BOOSTER
# Simpan sebagai roblox_monitor.sh | Encoding: UTF-8 tanpa BOM | Line Ending: LF

PACKAGE_PATTERN="${1:-com.roblox.*}"
CHECK_INTERVAL=3
YESC_API_KEY="GANTI_DENGAN_API_KEY_ANDA"
PROTECTED_APPS=("android" "com.android.systemui" "com.termux" "com.android.phone" "com.google.android.gms")

log() {
    echo "[$(date '+%T')] $1"
}

is_protected() {
    local pkg="$1"
    for p in "${PROTECTED_APPS[@]}"; do
        if [[ "$pkg" == "$p"* ]]; then
            return 0
        fi
    done
    return 1
}

apply_performance_tweaks() {
    if [ "$(id -u)" != "0" ]; then
        log "PERINGATAN: Root tidak terdeteksi. Lewati tweak performa."
        return
    fi
    
    log "Menerapkan tweak performa CPU..."
    for i in {0..7}; do
        echo 1 > "/sys/devices/system/cpu/cpu$i/online" 2>/dev/null
        echo performance > "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor" 2>/dev/null
    done
    
    log "Menonaktifkan thermal throttling..."
    stop thermal-engine 2>/dev/null
    stop thermald 2>/dev/null
    killall -9 thermal-engine thermald 2>/dev/null
    for tz in /sys/class/thermal/thermal_zone*/trip_point_*_temp; do
        [ -f "$tz" ] && echo 99999 > "$tz" 2>/dev/null
    done
    
    log "Optimasi I/O dan memori..."
    for dev in /sys/block/mmcblk[0-9]/queue/scheduler; do
        [ -f "$dev" ] && echo "deadline" > "$dev" 2>/dev/null
    done
    echo 10 > /proc/sys/vm/swappiness 2>/dev/null
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
        log "Menonaktifkan animasi UI..."
    settings put global window_animation_scale 0 2>/dev/null
    settings put global transition_animation_scale 0 2>/dev/null
    settings put global animator_duration_scale 0 2>/dev/null
    
    termux-wake-lock
    log "Tweak performa aktif"
}

kill_background_apps() {
    log "Membersihkan aplikasi latar belakang..."
    dumpsys activity processes 2>/dev/null | grep -oE 'Proc\[.*/[0-9]+\]' | grep -oE '[a-z][a-z.]*' | sort -u | while read pkg; do
        is_protected "$pkg" && continue
        [[ "$pkg" == $PACKAGE_PATTERN ]] && continue
        am force-stop "$pkg" 2>/dev/null
    done
    am kill-all 2>/dev/null
    log "Pembersihan latar belakang selesai"
}

resolve_packages() {
    local pattern="$1"
    local escaped_pattern="${pattern//./\\.}"
    escaped_pattern="${escaped_pattern//\*/.*}"
    pm list packages 2>/dev/null | grep -E "^package:$escaped_pattern\$" | cut -d: -f2
}

start_target_apps() {
    local -a packages=()
    while IFS= read -r pkg; do
        [ -n "$pkg" ] && packages+=("$pkg")
    done < <(resolve_packages "$PACKAGE_PATTERN")
    
    if [ ${#packages[@]} -eq 0 ]; then
        log "ERROR: Tidak ada paket ditemukan untuk pola '$PACKAGE_PATTERN'"
        pm list packages | grep -i roblox | head -5 | sed 's/package:/  Contoh: /'
        exit 1
    fi
    
    log "Memulai ${#packages[@]} aplikasi:"
    for pkg in "${packages[@]}"; do
        log "  - $pkg"
        am force-stop "$pkg" 2>/dev/null
        
        local activity
        activity=$(dumpsys package "$pkg" 2>/dev/null | grep -A2 "MAIN.*LAUNCHER" | grep "Activity" | head -1 | grep -oE "$pkg/[^ ]+" | head -1)
        
        if [ -n "$activity" ]; then
            am start -n "$activity" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER 2>/dev/null
        else            monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 2>/dev/null
        fi
        sleep 1.5
    done
    
    echo "${packages[@]}"
}

solve_captcha() {
    log "TERDETEKSI: Captcha terdeteksi. Memproses..."
    
    # PERINGATAN PENTING:
    # - Deteksi captcha via logcat TIDAK AKURAT untuk Roblox
    # - Ekstraksi sitekey memerlukan akses ke WebView (harus modifikasi APK atau Xposed)
    # - Inject token hasil solve TIDAK MUNGKIN via Termux tanpa akses root mendalam
    # - Script ini HANYA placeholder. Implementasi nyata memerlukan:
    #   * Custom module Xposed untuk hook WebView
    #   * Atau modifikasi APK Roblox (melanggar ToS)
    
    # Contoh alur API YesCaptcha (SESUAIKAN DENGAN KEBUTUHAN ANDA):
    # 1. Ekstrak sitekey dan URL (harus dari sumber eksternal)
    # 2. Kirim ke API:
    # curl -s -X POST "https://api.yescaptcha.com/createTask" \
    #   -H "Content-Type: application/json" \
    #   -d "{\"clientKey\":\"$YESC_API_KEY\",\"task\":{\"type\":\"RecaptchaV2TaskProxyless\",\"websiteURL\":\"https://www.roblox.com\",\"websiteKey\":\"SITEKEY_ANDA\"}}"
    # 3. Poll hasil
    # 4. Inject token (TIDAK MUNGKIN via Termux)
    
    log "PERINGATAN: Auto-solve captcha TIDAK BERFUNGSI penuh tanpa modifikasi aplikasi target."
    log "HANYA GUNAKAN UNTUK APLIKASI YANG ANDA KEMBANGKAN SENDIRI."
    return 0
}

monitor_apps() {
    local -a packages=("$@")
    log "Memantau ${#packages[@]} aplikasi. Tekan CTRL+C untuk berhenti."
    
    while true; do
        for pkg in "${packages[@]}"; do
            if ! pidof "$pkg" > /dev/null 2>&1; then
                log "KRITICAL: $pkg crash! Memulai ulang..."
                am start -n "$pkg/$(dumpsys package $pkg 2>/dev/null | grep -A2 'MAIN.*LAUNCHER' | grep Activity | head -1 | grep -oE '$pkg/[^ ]+' | head -1)" \
                    -a android.intent.action.MAIN -c android.intent.category.LAUNCHER 2>/dev/null || \
                monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 2>/dev/null
                sleep 2
            fi
        done
        
        # Deteksi captcha (placeholder - SESUAIKAN POLA LOG DENGAN APLIKASI ANDA)
        if logcat -d -t 100 2>/dev/null | grep -iq "captcha\|verify human\|challenge"; then            solve_captcha
        fi
        
        sleep $CHECK_INTERVAL
    done
}

cleanup_on_exit() {
    log "Mengembalikan pengaturan sistem..."
    if [ "$(id -u)" = "0" ]; then
        for i in {0..7}; do
            echo schedutil > "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor" 2>/dev/null
        done
        start thermal-engine 2>/dev/null
    fi
    termux-wake-unlock
    exit 0
}

main() {
    trap cleanup_on_exit INT TERM
    
    for cmd in am pm settings; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR: $cmd tidak ditemukan. Install Termux:API dari F-Droid."
            exit 1
        fi
    done
    
    termux-setup-storage 2>/dev/null
    
    apply_performance_tweaks
    kill_background_apps
    mapfile -t target_apps < <(start_target_apps)
    
    if [ ${#target_apps[@]} -eq 0 ]; then
        log "ERROR: Gagal memulai aplikasi target"
        exit 1
    fi
    
    monitor_apps "${target_apps[@]}"
}

main "$@"
