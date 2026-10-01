#!/usr/bin/env bash
# =============================================================================
# part1-linux-hadoop/run.sh —— 运行 Linux 常用操作全部题目并留存日志
#
# 权限自适应：
#   * 当前就是 root（uid=0）      -> 直接在真实系统上执行
#   * 有免密 sudo                 -> 用 sudo 执行（这样 chown root、写 /usr 才有效）
#   * 两者都没有（本实验环境）    -> 用 env/lab-root.sh 在“用户命名空间 + 可写根
#                                    视图”中执行：命令与路径和教材完全一致，
#                                    写操作全部落在临时视图，真实系统只读不受影响
# =============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/.." && pwd)"
mkdir -p "$DIR/logs"
LOG="$DIR/logs/linux-basics.log"

if [ "$(id -u)" -eq 0 ]; then
  echo "[run] 当前为 root，直接在真实系统路径下执行。"
  RUNNER=(env HOME="$HOME" /bin/bash)
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  echo "[run] 检测到免密 sudo，使用 sudo 执行。"
  RUNNER=(sudo -n -E env HOME="$HOME" /bin/bash)
else
  echo "[run] 当前用户 $(id -un) 无 root/sudo 权限。"
  echo "[run] 改在 “用户命名空间 + 可写根视图” 中执行：命令与路径同教材一致，"
  echo "[run] 所有写操作只落在临时视图（/tmp/lab1-bigdata-root-view），真实系统不受影响。"
  RUNNER=("$LAB_ROOT/env/lab-root.sh" /bin/bash)
fi

echo "[run] 脚本 : $DIR/linux_basics.sh"
echo "[run] 日志 : $LOG"
echo
"${RUNNER[@]}" "$DIR/linux_basics.sh" 2>&1 | tee "$LOG"
echo
echo "[run] 完成，共 $(wc -l < "$LOG") 行日志。"
