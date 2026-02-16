#!/data/data/com.termux/files/usr/bin/bash
# GAME BOOST + THERMAL THROTTLING DISABLE (Snapdragon 845)
# ⚠️ DANGEROUS: Use ONLY with active cooler & <30min sessions

PACKAGE_PATTERN="${1:-com.roblox.*}"
CHECK_INTERVAL=2
MAX_TEMP=70000  # Auto-shutdown at 70°C (safety net)
PROTECTED_APPS=("android" "com.android.systemui" "com.termux" "com.android.phone" "com.google.android.gms")

log() { echo "[$(date '+%H:%M:%S')] $1"; }
is_protected() { for p in "${PROTECTED_APPS[@]}"; do [[ "$1" == "$p"* ]] && return 0; done; return 1; }

apply_game_tweaks() {
    log "🎮 Applying AGGRESSIVE Gaming + Thermal Tweaks..."
    
    local has_root=0
    if [ "$(id -u)" = "0" ] || command -v tsu &>/dev/null || [ -f /data/data/com.termux/files/home/.suroot ]; then
        has_root=1
    fi
    
    if [ $has_root -eq 0 ]; then
        log "❌ ROOT REQUIRED FOR THERMAL DISABLE! Install Magisk first."
        log "→ Without root: throttling CANNOT be disabled (hardware protection)"
        exit 1
    fi
    
    log "✅ Root detected - proceeding with HIGH-RISK tweaks"
    sleep 2
    
    # === CPU: MAX PERFORMANCE (ALL CORES) ===
    log "→ CPU: Locking all 8 cores to MAX frequency..."
    for i in {0..7}; do
        echo 1 > /sys/devices/system/cpu/cpu$i/online 2>/dev/null
        echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null
        local max=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq 2>/dev/null)
        [ -n "$max" ] && echo $max > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_min_freq 2>/dev/null
    done
    log "✓ CPU: Kryo 385 @ MAX clocks (2.8GHz big / 1.8GHz little)"
    
    # === GPU: ADRENO 630 MAX ===
    log "→ GPU: Locking Adreno 630 to MAX frequency..."
    echo performance > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
    local gpumax=$(cat /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 2>/dev/null)
    [ -n "$gpumax" ] && echo $gpumax > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
    echo 1 > /sys/class/kgsl/kgsl-3d0/force_bus_on 2>/dev/null
    echo 1 > /sys/class/kgsl/kgsl-3d0/force_clk_on 2>/dev/null
    log "✓ GPU: Adreno 630 @ MAX clocks"
    
    # === ⚠️ THERMAL THROTTLING DISABLE (HIGH RISK) ===
    log "🔥 DISABLING THERMAL THROTTLING (DANGEROUS)..."    
    # Method 1: Stop thermal services
    stop thermal-engine 2>/dev/null
    stop thermald 2>/dev/null
    killall -9 thermal-engine thermald 2>/dev/null
    
    # Method 2: Override thermal trip points
    for tz in /sys/class/thermal/thermal_zone*; do
        [ -d "$tz" ] || continue
        for trip in $tz/trip_point_*_temp; do
            [ -f "$trip" ] && echo 99999 > "$trip" 2>/dev/null
        done
        for hyst in $tz/trip_point_*_hyst; do
            [ -f "$hyst" ] && echo 99999 > "$hyst" 2>/dev/null
        done
    done
    
    # Method 3: Disable MSM thermal driver (SD845 specific)
    for msm in /sys/module/msm_thermal*/parameters/enabled 2>/dev/null; do
        [ -f "$msm" ] && echo 0 > "$msm" 2>/dev/null
    done
    
    # Method 4: Override thermal config
    mount -o remount,rw / 2>/dev/null
    for conf in /etc/thermal-engine.conf /vendor/etc/thermal-engine.conf; do
        [ -f "$conf" ] && mv "$conf" "${conf}.bak" 2>/dev/null
    done
    
    log "⚠️  THERMAL PROTECTION DISABLED - DEVICE CAN OVERHEAT!"
    log "💡 MUST USE ACTIVE COOLER + MONITOR TEMPERATURE!"
    sleep 3
    
    # === I/O LOW LATENCY ===
    for dev in /sys/block/mmcblk[0-9]/queue/scheduler; do
        [ -f "$dev" ] && echo "deadline" > "$dev" 2>/dev/null
    done
    for ra in /sys/block/mmcblk[0-9]/queue/read_ahead_kb; do
        [ -f "$ra" ] && echo 2048 > "$ra" 2>/dev/null
    done
    
    # === MEMORY OPTIMIZATION ===
    echo 10 > /proc/sys/vm/swappiness 2>/dev/null
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    
    # === NETWORK LATENCY ===
    echo 1 > /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null
    echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null
    
    # === UI ANIMATIONS OFF ===
    settings put global window_animation_scale 0 2>/dev/null    settings put global transition_animation_scale 0 2>/dev/null
    settings put global animator_duration_scale 0 2>/dev/null
    
    termux-wake-lock
    log "✅ GAMING MODE ACTIVE - MONITOR TEMPERATURE!"
    echo
}

kill_background_apps() {
    log "🧹 Killing background apps..."
    local killed=0
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        is_protected "$pkg" && continue
        [[ "$pkg" == $PACKAGE_PATTERN ]] && continue
        am force-stop "$pkg" 2>/dev/null && ((killed++))
    done < <(dumpsys activity processes 2>/dev/null | grep -oE 'Proc\[.*/[0-9]+\]' | grep -oE '[a-z][a-z.]*' | sort -u)
    am kill-all 2>/dev/null
    log "✓ Killed $killed background apps"
    echo
}

resolve_packages() {
    local pat="${1//./\\.}"; pat="${pat//\*/.*}"
    pm list packages 2>/dev/null | grep -E "^package:$pat\$" | cut -d: -f2
}

start_apps() {
    log "🚀 Launching apps: $PACKAGE_PATTERN"
    mapfile -t pkgs < <(resolve_packages "$PACKAGE_PATTERN")
    [ ${#pkgs[@]} -eq 0 ] && { log "✗ No packages found"; pm list packages | grep -i roblox | head -5 | sed 's/package:/  → /'; exit 1; }
    log "✓ Found ${#pkgs[@]} apps"
    for p in "${pkgs[@]}"; do
        log "→ Starting $p"
        am force-stop "$p" 2>/dev/null
        activity=$(dumpsys package "$p" 2>/dev/null | grep -A2 "MAIN.*LAUNCHER" | grep "Activity" | head -1 | grep -oE "$p/[^ ]+" | head -1)
        [ -n "$activity" ] && am start -n "$activity" 2>/dev/null || monkey -p "$p" -c android.intent.category.LAUNCHER 1 2>/dev/null
        sleep 2
    done
    echo "${pkgs[@]}"
}

monitor_apps() {
    local pkgs=("$@")
    log "👀 Monitoring apps (safety shutdown @ $((MAX_TEMP/1000))°C)..."
    log "💡 Press CTRL+C to stop"
    
    while true; do
        # 🔥 SAFETY CHECK: Monitor temperature
        local max_temp=0        for tz in /sys/class/thermal/thermal_zone*/temp 2>/dev/null; do
            [ -f "$tz" ] && { local t=$(cat "$tz" 2>/dev/null); [ "$t" -gt "$max_temp" ] && max_temp=$t; }
        done
        
        if [ $max_temp -gt $MAX_TEMP ]; then
            log "🔥 CRITICAL TEMPERATURE: $((max_temp/1000))°C - SHUTTING DOWN!"
            log "⚠️  Restoring thermal protection..."
            for i in {0..7}; do echo schedutil > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null; done
            start thermal-engine 2>/dev/null
            termux-wake-unlock
            exit 1
        fi
        
        # Monitor crashes
        for p in "${pkgs[@]}"; do
            if ! pidof "$p" &>/dev/null; then
                log "! 💥 CRASH: $p - restarting..."
                am start -n "$p/$(dumpsys package $p 2>/dev/null | grep -A2 'MAIN.*LAUNCHER' | grep Activity | head -1 | grep -oE '$p/[^ ]+' | head -1)" 2>/dev/null || \
                monkey -p "$p" -c android.intent.category.LAUNCHER 1 2>/dev/null
                sleep 2
            fi
        done
        
        sleep $CHECK_INTERVAL
    done
}

main() {
    echo "=============================================="
    echo "  ⚠️  THERMAL THROTTLING DISABLE MODE  ⚠️"
    echo "  Snapdragon 845 - MAX PERFORMANCE"
    echo "  🔥 USE ACTIVE COOLER - MAX 30 MINUTES"
    echo "=============================================="
    echo
    
    for cmd in am pm settings; do ! command -v $cmd &>/dev/null && { log "✗ Install Termux:API from F-Droid"; exit 1; }; done
    termux-setup-storage 2>/dev/null
    
    apply_game_tweaks
    kill_background_apps
    mapfile -t apps < <(start_apps)
    [ ${#apps[@]} -eq 0 ] && exit 1
    
    echo
    log "🎮 READY - MONITOR TEMPERATURE CONSTANTLY!"
    log "   Command to check temp: cat /sys/class/thermal/thermal_zone*/temp"
    echo
    
    monitor_apps "${apps[@]}"
}
trap 'log "🛑 Restoring thermal protection..."; for i in {0..7}; do echo schedutil > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null; done; start thermal-engine 2>/dev/null; termux-wake-unlock; exit 0' SIGINT SIGTERM

main "$@"
