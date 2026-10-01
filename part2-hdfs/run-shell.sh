#!/usr/bin/env bash
# =============================================================================
# part2-hdfs/run-shell.sh —— 用 Shell 命令完成 10 道 HDFS 题目并留存日志
# =============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"
export HADOOP_USER_NAME="$HDFS_SUPERUSER"

mkdir -p "$DIR/logs"
LOG="$DIR/logs/hdfs-shell.log"
BASE="/user/yxy/hdfs-lab-shell"          # 本实现使用的 HDFS 实验根目录
LOCAL="$DIR/local-shell"                 # 本实现使用的本地工作目录

echo "[run] 清空上次的实验目录：$BASE"
hdfs dfs -rm -r -f "$BASE" >/dev/null 2>&1 || true
rm -rf "$LOCAL"

{
  echo "############################################################"
  echo "#  实验一 第 2 部分：HDFS 常用操作 —— Shell 命令实现"
  echo "#  HDFS 实验根目录: $BASE"
  echo "#  本地工作目录   : $LOCAL"
  echo "#  执行时间       : $(date '+%F %T')"
  echo "############################################################"
  "$DIR/test-sequence.sh" "$DIR/hdfs_shell.sh" "$BASE" "$LOCAL"
} 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}

echo
if [ "$rc" -ne 0 ]; then
  echo "[run] 失败：退出码 $rc，日志：$LOG"; exit "$rc"
fi
echo "[run] 完成，日志：$LOG （共 $(wc -l < "$LOG") 行）"
