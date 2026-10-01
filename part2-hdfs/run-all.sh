#!/usr/bin/env bash
# =============================================================================
# part2-hdfs/run-all.sh —— 依次运行 Shell 实现与 Java 实现（题目要求
# “编程实现以下功能，并利用 Hadoop 提供的 Shell 命令完成相同任务”）
# =============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======== ① Shell 命令实现 ========"
"$DIR/run-shell.sh" || exit 1
echo
echo "======== ② Java API 实现 ========"
"$DIR/run-java.sh" || exit 1
echo
echo "======== 两种实现的输出对比 ========"
for f in "$DIR/logs/hdfs-shell.log" "$DIR/logs/hdfs-java.log"; do
  echo "  $(basename "$f") : $(wc -l < "$f") 行"
done
