#!/data/data/com.termux/files/usr/bin/bash
# Game Booster + Thermal Disable (Snapdragon 845)
# ⚠️ ROOT REQUIRED - USE WITH ACTIVE COOLER

PACKAGE_PATTERN="${1:-com.roblox.*}"
CHECK_INTERVAL=2
PROTECTED=("android" "com.android.systemui" "com.termux" "com.android.phone")

log() { echo "[$(date '+%H:%M:%S')] $1"; }
is_protected() { for p in "${PROTECTED[@]}"; do [[ "$1" == "$p"* ]] && return 0; done; return 1; }

apply_tweaks() {
  log "Applying gaming tweaks (Snapdragon 845)..."
  [ "$(id -u)" != "0" ] && ! command -v tsu &>/dev/null && { log "ROOT REQUIRED!"; exit 1; }
  
  # CPU Performance Mode
  for i in {0..7}; do
    echo 1 > "/sys/devices/system/cpu/cpu$i/online" 2>/dev/null
    echo performance > "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor" 2>/dev/null
    MAX=$(cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_max_freq" 2>/dev/null)
    [ -n "$MAX" ] && echo "$MAX" > "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_min_freq" 2>/dev/null
  done
  
  # GPU Boost
  echo performance > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
  GPU_MAX=$(cat /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 2>/dev/null)
  [ -n "$GPU_MAX" ] && echo "$GPU_MAX" > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
  
  # Thermal Disable (HIGH RISK)
  stop thermal-engine 2>/dev/null
  stop thermald 2>/dev/null
  killall -9 thermal-engine thermald 2>/dev/null
  for tz in /sys/class/thermal/thermal_zone*; do
    [ -d "$tz" ] || continue
    for f in "$tz"/trip_point_*_temp; do [ -f "$f" ] && echo 99999 > "$f" 2>/dev/null; done
  done
  
  # Optimizations
  for d in /sys/block/mmcblk[0-9]/queue/scheduler; do [ -f "$d" ] && echo deadline > "$d" 2>/dev/null; done
  echo 10 > /proc/sys/vm/swappiness 2>/dev/null
  sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
  settings put global window_animation_scale 0 2>/dev/null
  settings put global transition_animation_scale 0 2>/dev/null
  settings put global animator_duration_scale 0 2>/dev/null
  
  termux-wake-lock
  log "✅ Gaming mode active - MONITOR TEMPERATURE!"
}

kill_bg() {  log "Killing background apps..."
  while IFS= read -r pkg; do
    is_protected "$pkg" && continue
    [[ "$pkg" == $PACKAGE_PATTERN ]] && continue
    am force-stop "$pkg" 2>/dev/null
  done < <(dumpsys activity processes 2>/dev/null | grep -oE 'Proc\[.*/[0-9]+\]' | grep -oE '[a-z][a-z.]*' | sort -u)
  am kill-all 2>/dev/null
}

resolve_pkgs() {
  local pat="${1//./\\.}"; pat="${pat//\*/.*}"
  pm list packages 2>/dev/null | grep -E "^package:$pat\$" | cut -d: -f2
}

start_apps() {
  mapfile -t pkgs < <(resolve_pkgs "$PACKAGE_PATTERN")
  [ ${#pkgs[@]} -eq 0 ] && { log "No packages found for '$PACKAGE_PATTERN'"; pm list packages | grep -iE "roblox|game" | head -5 | sed 's/package:/  - /'; exit 1; }
  log "Found ${#pkgs[@]} apps:"
  for p in "${pkgs[@]}"; do log "  - $p"; done
  for p in "${pkgs[@]}"; do
    am force-stop "$p" 2>/dev/null
    act=$(dumpsys package "$p" 2>/dev/null | grep -A2 "MAIN.*LAUNCHER" | grep Activity | head -1 | grep -oE "$p/[^ ]+" | head -1)
    [ -n "$act" ] && am start -n "$act" 2>/dev/null || monkey -p "$p" -c android.intent.category.LAUNCHER 1 2>/dev/null
    sleep 1.5
  done
  echo "${pkgs[@]}"
}

monitor() {
  local pkgs=("$@")
  log "Monitoring apps (CTRL+C to stop)..."
  while true; do
    for p in "${pkgs[@]}"; do
      if ! pidof "$p" &>/dev/null; then
        log "! CRASH: $p → restarting..."
        am start -n "$p/$(dumpsys package $p 2>/dev/null | grep -A2 'MAIN.*LAUNCHER' | grep Activity | head -1 | grep -oE '$p/[^ ]+' | head -1)" 2>/dev/null || \
        monkey -p "$p" -c android.intent.category.LAUNCHER 1 2>/dev/null
        sleep 2
      fi
    done
    sleep $CHECK_INTERVAL
  done
}

main() {
  for cmd in am pm settings; do command -v $cmd &>/dev/null || { log "Install Termux:API from F-Droid"; exit 1; }; done
  termux-setup-storage 2>/dev/null
  apply_tweaks
  kill_bg
  mapfile -t apps < <(start_apps)  monitor "${apps[@]}"
}

trap 'log "Restoring defaults..."; for i in {0..7}; do echo schedutil > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null; done; start thermal-engine 2>/dev/null; termux-wake-unlock; exit' INT TERM
main "$@"    log "🧹 Killing background apps..."
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
