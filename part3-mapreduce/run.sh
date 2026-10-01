#!/usr/bin/env bash
# =============================================================================
# part3-mapreduce/run.sh —— 运行实验一第 3 部分的三个 MapReduce 作业
#
# 流程：编译 -> 上传输入到 HDFS -> 依次提交三个作业 -> 打印结果 ->
#       与 expected/ 下的标准答案比对（diff），全过程写入 logs/mr.log。
#
# 用法：  ./part3-mapreduce/run.sh            # 提交到 YARN（默认，真实分布式框架）
#         ./part3-mapreduce/run.sh local      # 用 LocalJobRunner 单进程跑，便于调试
# =============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"
export HADOOP_USER_NAME="$HDFS_SUPERUSER"

MODE="${1:-yarn}"
mkdir -p "$DIR/logs"
LOG="$DIR/logs/mr.log"
BASE="/user/yxy/mr-lab"
JAR="$DIR/build/mr-lab.jar"

# ---------- local 模式：复制一份配置，把 MapReduce 框架改成 local --------------
if [ "$MODE" = "local" ]; then
  LOCAL_CONF="$DIR/build/conf-local"
  rm -rf "$LOCAL_CONF"; mkdir -p "$LOCAL_CONF"
  cp -r "$HADOOP_CONF_DIR"/. "$LOCAL_CONF"/
  sed -i 's|<value>yarn</value>|<value>local</value>|' "$LOCAL_CONF/mapred-site.xml"
  export HADOOP_CONF_DIR="$LOCAL_CONF"
  echo "[run] 使用 LocalJobRunner（mapreduce.framework.name=local）"
else
  echo "[run] 提交到 YARN（mapreduce.framework.name=yarn）"
fi

echo "[run] 编译 ..."
"$DIR/build.sh" > "$DIR/logs/mr-build.log" 2>&1 || {
  echo "[run] 编译失败，详见 $DIR/logs/mr-build.log"; tail -30 "$DIR/logs/mr-build.log"; exit 1; }

# ---------- 单个作业：上传输入 -> 提交 -> 打印并校验输出 ----------------------
# $1 标题  $2 子命令  $3 本地输入目录  $4 HDFS 输出子目录名  $5 标准答案文件
run_job() {
  local title="$1" sub="$2" local_in="$3" out_name="$4" expected="$5"
  local hdfs_in="$BASE/${out_name}-input"
  local hdfs_out="$BASE/${out_name}-output"

  {
    echo
    echo "================================================================================"
    echo "# $title"
    echo "================================================================================"
    echo "\$ hdfs dfs -rm -r -f $hdfs_in $hdfs_out"
    hdfs dfs -rm -r -f "$hdfs_in" "$hdfs_out" >/dev/null 2>&1
    echo "\$ hdfs dfs -put $local_in $hdfs_in"
    hdfs dfs -mkdir -p "$hdfs_in"
    hdfs dfs -put -f "$local_in"/* "$hdfs_in"/
    echo "-- HDFS 上的输入文件："
    hdfs dfs -ls "$hdfs_in"

    echo
    echo "\$ hadoop jar $(basename "$JAR") $sub $hdfs_in $hdfs_out"
    hadoop jar "$JAR" "$sub" "$hdfs_in" "$hdfs_out"
    local rc=$?

    echo
    echo "-- 作业输出目录："
    hdfs dfs -ls "$hdfs_out"
    echo "-- 运行结果（part-r-00000）："
    hdfs dfs -cat "$hdfs_out/part-r-00000"
    echo
    echo "-- 与 expected/$expected 比对："
    if diff <(hdfs dfs -cat "$hdfs_out/part-r-00000" | sort) <(sort "$DIR/expected/$expected") >/dev/null; then
      echo "【一致】输出与标准答案完全相同"
    else
      echo "【不一致】差异如下："
      diff <(hdfs dfs -cat "$hdfs_out/part-r-00000" | sort) <(sort "$DIR/expected/$expected")
    fi
    return $rc
  } 2>&1 | tee -a "$LOG"
  return "${PIPESTATUS[0]}"
}

{
  echo "############################################################"
  echo "#  实验一 第 3 部分：MapReduce 初级编程"
  echo "#  运行模式: $MODE"
  echo "#  HDFS 实验根目录: $BASE"
  echo "#  执行时间: $(date '+%F %T')"
  echo "############################################################"
} | tee "$LOG"

fail=0
run_job "题目1：文件的合并和去重"          dedup       "$DIR/input/dedup"       "dedup"       "dedup.txt"       || fail=1
run_job "题目2：对输入文件进行排序"        sort        "$DIR/input/sort"        "sort"        "sort.txt"        || fail=1
run_job "题目3：child-parent 表信息挖掘"   grandparent "$DIR/input/grandparent" "grandparent" "grandparent.txt" || fail=1

echo | tee -a "$LOG"
if [ "$fail" -ne 0 ]; then
  echo "[run] 有作业失败，请查看日志：$LOG" | tee -a "$LOG"; exit 1
fi
echo "[run] 三个作业全部完成，日志：$LOG （共 $(wc -l < "$LOG") 行）" | tee -a "$LOG"
