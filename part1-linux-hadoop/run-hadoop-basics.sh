#!/usr/bin/env bash
# =============================================================================
# part1-linux-hadoop/run-hadoop-basics.sh —— 运行 Hadoop(HDFS) 基本操作并留存日志
#
# 两步走：
#   1) 先在外层环境记录“Hadoop 已启动”的证据：
#        * jps 输出 —— 守护进程运行在集群后台作业自己的 PID 命名空间里，其它会话
#          的 jps 看不到它们，因此直接引用集群启动时在集群命名空间内采集并落盘的
#          env/logs/jps-startup.txt；
#        * hdfs dfsadmin -report / yarn node -list —— 走网络向 NameNode、RM 查询，
#          在任何会话里都能执行，是最直接的存活证据。
#   2) 在“可写根视图”里执行 hadoop_basics.sh：这样第 4 步的 /usr/local/hadoop
#      真实可写，而所有 HDFS 命令的路径与教材完全一致。
# =============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"
mkdir -p "$DIR/logs"
LOG="$DIR/logs/hadoop-basics.log"

{
  echo "################ 集群守护进程（jps） ################"
  echo "# 说明：NameNode/DataNode/ResourceManager/NodeManager 启动在集群后台作业"
  echo "#       自己的 PID 命名空间内，其它会话中的 jps 看不到它们；下面这份输出是"
  echo "#       集群启动时在同一命名空间内采集并落盘的（env/logs/jps-startup.txt）。"
  cat "$LAB_ROOT/env/logs/jps-startup.txt" 2>/dev/null \
    || echo "(未找到 jps-startup.txt，请先执行 env/run-cluster.sh 启动集群)"
  echo
  echo "\$ hdfs dfsadmin -safemode get"
  hdfs dfsadmin -safemode get || true
  echo
  echo "\$ yarn node -list"
  yarn node -list || true
} | tee "$LOG"

"$LAB_ROOT/env/lab-root.sh" /bin/bash "$DIR/hadoop_basics.sh" 2>&1 | tee -a "$LOG"
rc=${PIPESTATUS[0]}
echo
if [ "$rc" -ne 0 ]; then
  echo "[run] 失败：子脚本退出码 $rc，日志：$LOG"
  exit "$rc"
fi
echo "[run] 完成，日志：$LOG （共 $(wc -l < "$LOG") 行）"
