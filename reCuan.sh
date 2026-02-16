#!/data/data/com.termux/files/usr/bin/bash
# Auto App Manager with Wildcard Support (Snapdragon 845 Optimized)
# Created for Termux - Supports patterns like "com.roblox.*"

PACKAGE_PATTERN="${1:-com.roblox.*}"
CHECK_INTERVAL=3
PROTECTED_APPS=("android" "com.android.systemui" "com.termux" "com.android.phone" "com.google.android.gms")

log() { echo "[$(date '+%H:%M:%S')] $1"; }
is_protected() { for p in "${PROTECTED_APPS[@]}"; do [[ "$1" == "$p"* ]] && return 0; done; return 1; }

apply_tweaks() {
    log "Applying Snapdragon 845 optimizations..."
    [ -d /sys/block/zram0 ] && { echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null; echo 1073741824 > /sys/block/zram0/disksize 2>/dev/null; mkswap /dev/zram0 2>/dev/null && swapon /dev/zram0 2>/dev/null; }
    for cpu in /sys/devices/system/cpu/cpu[0-7]/cpufreq/scaling_governor 2>/dev/null; do [ -f "$cpu" ] && echo "interactive" > "$cpu" 2>/dev/null; done
    for dev in /sys/block/mmcblk[0-9]/queue/scheduler 2>/dev/null; do [ -f "$dev" ] && echo "deadline" > "$dev" 2>/dev/null; done
    echo 30 > /proc/sys/vm/swappiness 2>/dev/null
    termux-wake-lock
    log "✓ Tweaks applied"
}

kill_background() {
    log "Cleaning background apps..."
    local killed=0
    for pkg in $(dumpsys activity processes 2>/dev/null | grep -oE 'Proc\[.*/[0-9]+\]' | grep -oE '[a-z][a-z.]*' | sort -u); do
        is_protected "$pkg" && continue
        [[ "$pkg" == $PACKAGE_PATTERN ]] && continue
        am force-stop "$pkg" 2>/dev/null && { ((killed++)); log "  → Stopped: $pkg"; }
    done
    log "✓ Cleaned $killed background apps"
}

resolve_packages() {
    local pat="${1//./\\.}"; pat="${pat//\*/.*}"
    pm list packages 2>/dev/null | grep -E "^package:$pat\$" | cut -d: -f2
}

start_apps() {
    mapfile -t pkgs < <(resolve_packages "$PACKAGE_PATTERN")
    [ ${#pkgs[@]} -eq 0 ] && { log "✗ No packages found for '$PACKAGE_PATTERN'"; pm list packages | grep -i roblox | head -5 | sed 's/package:/  - /'; exit 1; }
    log "Found ${#pkgs[@]} packages:"
    for p in "${pkgs[@]}"; do log "  - $p"; done
    for p in "${pkgs[@]}"; do
        am force-stop "$p" 2>/dev/null
        activity=$(dumpsys package "$p" 2>/dev/null | grep -A2 "MAIN.*LAUNCHER" | grep "Activity" | head -1 | grep -oE "$p/[^ ]+" | head -1)
        [ -n "$activity" ] && am start -n "$activity" 2>/dev/null || monkey -p "$p" -c android.intent.category.LAUNCHER 1 2>/dev/null
        sleep 1.5
    done
    echo "${pkgs[@]}"
}

monitor_apps() {
    local pkgs=("$@")
    log "Monitoring ${#pkgs[@]} apps (pattern: $PACKAGE_PATTERN)..."
    log "Press CTRL+C to stop"
    while true; do
        for p in "${pkgs[@]}"; do
            if ! pidof "$p" &>/dev/null; then
                log "! CRASH: $p → restarting..."
                am start -n "$p/$(dumpsys package $p 2>/dev/null | grep -A2 'MAIN.*LAUNCHER' | grep Activity | head -1 | grep -oE '$p/[^ ]+' | head -1)" 2>/dev/null || \
                monkey -p "$p" -c android.intent.category.LAUNCHER 1 2>/dev/null
                sleep 2
                pidof "$p" &>/dev/null && log "  ✓ Restarted" || log "  ✗ Failed"
            fi
        done
        sleep $CHECK_INTERVAL
    done
}

main() {
    log "========================================"
    log " Wildcard App Monitor (Snapdragon 845)"
    log " Pattern: $PACKAGE_PATTERN"
    log "========================================"
    
    for cmd in am pm; do ! command -v $cmd &>/dev/null && { log "✗ Missing Termux:API - install from F-Droid"; exit 1; }; done
    
    apply_tweaks
    kill_background
    mapfile -t apps < <(start_apps)
    [ ${#apps[@]} -eq 0 ] && exit 1
    monitor_apps "${apps[@]}"
}

trap 'log "Stopping..."; termux-wake-unlock; exit 0' SIGINT SIGTERM
main
