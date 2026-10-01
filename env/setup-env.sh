#!/usr/bin/env bash
# =============================================================================
# setup-env.sh —— 根据模板生成 Hadoop 站点配置文件，并格式化 HDFS
#   1) 把 env/templates/*.xml.template 中的 @LAB_ROOT@ / @HADOOP_HOME@ 占位符
#      替换成本机真实路径，写入 env/hadoop-conf/
#   2) 首次运行时格式化 NameNode（生成 fsimage）
# 用法：  ./env/setup-env.sh            # 生成配置（幂等）
#         ./env/setup-env.sh --format   # 生成配置并格式化 NameNode
# =============================================================================
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$ENV_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$ENV_DIR/hadoop.env.sh"

echo "[setup-env] LAB_ROOT    = $LAB_ROOT"
echo "[setup-env] JAVA_HOME   = $JAVA_HOME"
echo "[setup-env] HADOOP_HOME = $HADOOP_HOME"

mkdir -p "$HADOOP_CONF_DIR" "$HADOOP_LOG_DIR" "$HADOOP_PID_DIR" \
         "$LAB_ROOT/env/tmp" "$LAB_ROOT/env/hadoopdata/name" "$LAB_ROOT/env/hadoopdata/data" \
         "$LAB_ROOT/env/yarn/local" "$LAB_ROOT/env/yarn/logs"

# 先铺一份官方默认配置文件（capacity-scheduler.xml、hadoop-policy.xml、log4j.properties、
# hadoop-env.sh、mapred-queues 等）。*site.xml 不在此列，它们统一由下面的模板生成。
# 注意 capacity-scheduler.xml 是必需的：YARN CapacityScheduler 要靠它初始化队列，
# 缺失时会报 “Queue configuration missing child queue names for root”。
for f in "$HADOOP_HOME"/etc/hadoop/*; do
  [ -f "$f" ] || continue                 # 跳过 shellprofile.d 等目录
  base="$(basename "$f")"
  case "$base" in
    *-site.xml)            continue ;;   # 由本仓库模板生成
    *.cmd|*.template|*.example) continue ;;  # Windows / 示例文件跳过
  esac
  [ -e "$HADOOP_CONF_DIR/$base" ] || cp "$f" "$HADOOP_CONF_DIR/"
done
# 官方 hadoop-env.sh 中的 JAVA_HOME 固定为本机 JDK
sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|" "$HADOOP_CONF_DIR/hadoop-env.sh"

# 从模板生成 site 配置
for tpl in "$ENV_DIR"/templates/*.xml.template; do
  name="$(basename "$tpl" .template)"
  sed -e "s|@LAB_ROOT@|$LAB_ROOT|g" \
      -e "s|@HADOOP_HOME@|$HADOOP_HOME|g" \
      -e "s|@JAVA_HOME@|$JAVA_HOME|g" \
      "$tpl" > "$HADOOP_CONF_DIR/$name"
  echo "[setup-env] generated $HADOOP_CONF_DIR/$name"
done

if [ "${1:-}" = "--format" ]; then
  echo "[setup-env] formatting HDFS NameNode ..."
  "$HADOOP_HOME/bin/hdfs" namenode -format -force -nonInteractive | tail -3
  echo "[setup-env] format done."
fi

echo "[setup-env] OK"
