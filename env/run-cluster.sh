#!/usr/bin/env bash
# =============================================================================
# run-cluster.sh —— 不依赖 SSH 的前台集群监管脚本
#
# 为什么需要它：
#   Hadoop 官方 start-dfs.sh / start-yarn.sh 会通过 `ssh localhost` 去拉起各守护
#   进程（这是 Hadoop 的标准做法，见报告中的标准启动方式）。在部分受限环境
#   （容器、CI、无免密 SSH 的机器）中 ssh 不可用，此时可以直接用本脚本把
#   NameNode / DataNode / ResourceManager / NodeManager 以**前台进程**方式拉起，
#   由外部监管者（systemd、supervisor、终端会话）维持其运行。
#
# 用法：  ./env/run-cluster.sh          # 前台运行，Ctrl-C 结束全部守护进程
#         nohup ./env/run-cluster.sh & # 后台常驻
# =============================================================================
set -uo pipefail
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$ENV_DIR/hadoop.env.sh"

mkdir -p "$HADOOP_LOG_DIR" "$LAB_ROOT/env/yarn/logs" "$LAB_ROOT/env/yarn/local"

declare -a PIDS=()
declare -a NAMES=()

start_daemon() {           # $1=显示名  $2...=命令
  local name="$1"; shift
  local log="$HADOOP_LOG_DIR/${name}-console.log"
  echo "[run-cluster] starting $name -> $log"
  "$@" >>"$log" 2>&1 &
  PIDS+=("$!"); NAMES+=("$name")
}

stop_all() {
  echo "[run-cluster] stopping: ${NAMES[*]:-none}"
  for p in "${PIDS[@]:-}"; do kill "$p" 2>/dev/null || true; done
  wait 2>/dev/null || true
}
trap stop_all EXIT INT TERM

start_daemon namenode       "$HADOOP_HOME/bin/hdfs" namenode
sleep 8
start_daemon datanode       "$HADOOP_HOME/bin/hdfs" datanode
start_daemon resourcemanager "$HADOOP_HOME/bin/yarn" resourcemanager
sleep 5
start_daemon nodemanager    "$HADOOP_HOME/bin/yarn" nodemanager

echo "[run-cluster] all daemons launched, waiting ..."

# 采集一次真实的 jps 输出作为“Hadoop 已启动”的证据：守护进程运行在本后台作业
# 自己的 PID 命名空间里，其它终端/会话中的 jps 看不到它们，所以必须在这里落盘。
sleep 12
{
  echo "# 由 env/run-cluster.sh 在集群所在命名空间内采集： $(date '+%F %T')"
  echo "\$ jps -l"
  jps -l
} > "$HADOOP_LOG_DIR/jps-startup.txt" 2>&1
cat "$HADOOP_LOG_DIR/jps-startup.txt"

wait
