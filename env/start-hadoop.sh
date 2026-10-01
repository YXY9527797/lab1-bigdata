#!/usr/bin/env bash
# =============================================================================
# start-hadoop.sh —— 启动 HDFS（NameNode + DataNode）与 YARN（RM + NM）
#
# 用法：
#   ./env/start-hadoop.sh              标准方式：调用 $HADOOP_HOME/sbin/start-dfs.sh
#                                      + start-yarn.sh（需要配置本机免密 SSH 登录，
#                                      因为这两个脚本会 ssh 到 localhost 拉起守护进程）
#   ./env/start-hadoop.sh --direct     直接方式：用 `hdfs --daemon start` /
#                                      `yarn --daemon start` 拉起，不需要 SSH
# =============================================================================
set -euo pipefail
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$ENV_DIR/hadoop.env.sh"

MODE="${1:-standard}"

if [ "$MODE" = "--direct" ]; then
  echo "=== 直接方式启动守护进程（不需要 SSH） ==="
  "$HADOOP_HOME/bin/hdfs" --daemon start namenode
  sleep 8
  "$HADOOP_HOME/bin/hdfs" --daemon start datanode
  "$HADOOP_HOME/bin/yarn" --daemon start resourcemanager
  sleep 5
  "$HADOOP_HOME/bin/yarn" --daemon start nodemanager
else
  echo "=== 启动 HDFS（sbin/start-dfs.sh） ==="
  "$HADOOP_HOME/sbin/start-dfs.sh" 2>&1 | grep -v '^Starting' || true
  echo "=== 启动 YARN（sbin/start-yarn.sh） ==="
  "$HADOOP_HOME/sbin/start-yarn.sh" 2>&1 | grep -v '^Starting' || true
fi

echo "=== 等待 NameNode 退出安全模式 ==="
"$HADOOP_HOME/bin/hdfs" dfsadmin -safemode wait
echo "safemode: $("$HADOOP_HOME/bin/hdfs" dfsadmin -safemode get)"

echo "=== Java 进程 ==="
jps

echo "=== HDFS 根目录 ==="
"$HADOOP_HOME/bin/hdfs" dfs -ls /
