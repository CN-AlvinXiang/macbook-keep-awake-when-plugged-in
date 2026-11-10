#!/bin/bash
# =====================================================================
# lid-awake-on-ac.sh —— 「插电合盖不睡眠，拔电合盖正常睡眠」一键安装器
#
# 为什么这样设计：
#   macOS 的 `pmset disablesleep` 是全局开关，不区分电源来源，系统设置里也没有
#   「合盖不睡」选项。所以装一个 root 级 launchd 守护任务，每 10 秒看一次供电状态：
#     接电源 -> disablesleep 1（合盖不睡，可继续远程）
#     电池   -> disablesleep 0（恢复正常睡眠）
#
# 用法（在任意位置运行，会自动请求 sudo 密码）：
#   bash lid-awake-on-ac.sh install     安装并立即生效
#   bash lid-awake-on-ac.sh status      查看当前状态（无需 sudo）
#   bash lid-awake-on-ac.sh uninstall   卸载并恢复系统默认睡眠行为
#
# 注意：插电合盖时机器会持续运行发热，别放进包里；拔电后最多 10 秒恢复睡眠。
# =====================================================================
set -euo pipefail

LABEL="com.local.lid-awake-on-ac"
BIN="/usr/local/bin/lid-awake-on-ac-worker.sh"
PLIST="/Library/LaunchDaemons/${LABEL}.plist"

[ "$(uname)" = "Darwin" ] || { echo "仅支持 macOS"; exit 1; }

show_status() {
  echo "供电：$(pmset -g batt | head -1)"
  echo "SleepDisabled：$(pmset -g | awk '/SleepDisabled/{print $2}')  （1=合盖不睡，0=正常睡眠）"
  if [ -f "$PLIST" ]; then echo "守护任务：已安装"; else echo "守护任务：未安装"; fi
}

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    exec sudo bash "$0" "$@"
  fi
}

do_install() {
  mkdir -p /usr/local/bin
  # 实际干活的小脚本：按供电来源切换 disablesleep，只在状态不一致时才写
  cat > "$BIN" <<'EOF'
#!/bin/bash
if pmset -g batt | head -1 | grep -q "AC Power"; then want=1; else want=0; fi
cur=$(pmset -g | awk '/SleepDisabled/{print $2}')
[ "$cur" != "$want" ] && /usr/bin/pmset -a disablesleep "$want"
exit 0
EOF
  chown root:wheel "$BIN"; chmod 755 "$BIN"

  cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>${LABEL}</string>
    <key>ProgramArguments</key><array><string>${BIN}</string></array>
    <key>RunAtLoad</key><true/>
    <key>StartInterval</key><integer>10</integer>
</dict>
</plist>
EOF
  chown root:wheel "$PLIST"; chmod 644 "$PLIST"

  # 重复安装时先卸旧的，保证幂等
  launchctl bootout system "$PLIST" 2>/dev/null || true
  launchctl bootstrap system "$PLIST"
  sleep 12
  echo "安装完成。"
  show_status
}

do_uninstall() {
  launchctl bootout system "$PLIST" 2>/dev/null || true
  rm -f "$PLIST" "$BIN"
  pmset -a disablesleep 0
  echo "已卸载，睡眠行为恢复默认。"
  show_status
}

case "${1:-}" in
  install)   need_root "$@"; do_install ;;
  uninstall) need_root "$@"; do_uninstall ;;
  status)    show_status ;;
  *) echo "用法: bash $0 {install|status|uninstall}"; exit 1 ;;
esac
