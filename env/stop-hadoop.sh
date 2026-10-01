#!/usr/bin/env bash
# =============================================================================
# stop-hadoop.sh —— 停止 YARN 与 HDFS
# =============================================================================
set -uo pipefail
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$ENV_DIR/hadoop.env.sh"

echo "=== 停止 YARN ==="
"$HADOOP_HOME/sbin/stop-yarn.sh" 2>&1 | grep -v "^Stopping" || true

echo "=== 停止 HDFS ==="
"$HADOOP_HOME/sbin/stop-dfs.sh" 2>&1 | grep -v "^Stopping" || true

echo "=== 剩余 Java 进程 ==="
jps
