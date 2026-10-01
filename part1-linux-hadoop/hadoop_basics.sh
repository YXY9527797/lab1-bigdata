#!/usr/bin/env bash
# =============================================================================
# hadoop_basics.sh —— 实验一 第 1 部分（续）：熟悉常用的 Hadoop（HDFS）操作
#
# 对应教材最后 5 道小题：
#   1) 以 hadoop 用户登录 Linux、启动 Hadoop，并为其创建 HDFS 用户目录 /user/hadoop
#   2) 在 HDFS 的 /user/hadoop 下创建 test 文件夹，并查看文件列表
#   3) 把本地 ~/.bashrc 上传到 HDFS 的 test 文件夹中，并查看 test
#   4) 把 HDFS 上的文件夹 test 复制回本地文件系统的 /usr/local/hadoop 目录下
#
# 说明：本脚本通常由 part1-linux-hadoop/run-hadoop-basics.sh 调用，后者会把它
#       放进“可写根视图”中执行，这样第 4 步的 /usr/local/hadoop 才能真实可写，
#       而命令路径与教材完全一致。
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"

# 以 HDFS 超级用户身份操作（视图内 whoami 是 root，需显式指定，否则会被 HDFS 拒绝）
export HADOOP_USER_NAME="$HDFS_SUPERUSER"

BANNER="────────────────────────────────────────────────────────────────────────"
section() { printf '\n%s\n【%s】%s\n%s\n' "$BANNER" "$1" "$2" "$BANNER"; }
run() { echo "\$ $*"; "$@"; }

echo "################ 实验一 · Hadoop（HDFS）基本操作 ################"
echo "操作身份 (HADOOP_USER_NAME) : $HADOOP_USER_NAME"
echo "HDFS 地址                    : $HDFS_URI"
echo "本地主目录                  : $HOME"

# ---------------------------------------------------------------------------
section "1" "以 hadoop 用户登录并启动 Hadoop，为 hadoop 用户创建 HDFS 用户目录 /user/hadoop"
# ---------------------------------------------------------------------------
echo "教材中的标准操作步骤（在装有 Hadoop 的 Linux 机器上）："
cat <<'STEPS'
    $ su - hadoop                    # 以 hadoop 用户登录（或直接以 hadoop 用户登录系统）
    $ start-dfs.sh                   # 启动 HDFS：NameNode + DataNode + SecondaryNameNode
    $ start-yarn.sh                  # 启动 YARN：ResourceManager + NodeManager
    $ jps                            # 确认守护进程都已起来
STEPS
echo
echo "-- 确认本机 Hadoop 集群已经启动（以 HDFS 报告为准，可直接反映 DataNode 存活情况）"
run hdfs dfsadmin -report
echo
echo "-- 确认 YARN 节点状态"
run yarn node -list
echo
echo "-- 为 hadoop 用户创建 HDFS 用户目录 /user/hadoop"
run hdfs dfs -mkdir -p /user/hadoop
echo "\$ hdfs dfs -chown hadoop:supergroup /user/hadoop    # 属主改为 hadoop 用户"
hdfs dfs -chown hadoop:supergroup /user/hadoop
run hdfs dfs -ls -d /user/hadoop

# ---------------------------------------------------------------------------
section "2" "在 /user/hadoop 下创建 test 文件夹，并查看文件列表"
# ---------------------------------------------------------------------------
run hdfs dfs -mkdir -p /user/hadoop/test
run hdfs dfs -ls /user/hadoop
echo
echo "-- 递归查看 /user/hadoop 下的目录树"
run hdfs dfs -ls -R /user/hadoop

# ---------------------------------------------------------------------------
section "3" "把本地 ~/.bashrc 上传到 HDFS 的 test 文件夹中，并查看 test"
# ---------------------------------------------------------------------------
echo "本地待上传文件：$HOME/.bashrc （$(wc -l < "$HOME/.bashrc") 行，$(stat -c %s "$HOME/.bashrc") 字节）"
run hdfs dfs -put -f "$HOME/.bashrc" /user/hadoop/test
echo
run hdfs dfs -ls /user/hadoop/test
echo
echo "-- 校验：HDFS 上文件与本地文件内容一致（比较 MD5）"
echo "本地 : $(md5sum "$HOME/.bashrc" | awk '{print $1}')"
echo "HDFS : $(hdfs dfs -cat /user/hadoop/test/.bashrc | md5sum | awk '{print $1}')"
echo
echo "-- 查看 HDFS 上该文件的前 5 行"
hdfs dfs -cat /user/hadoop/test/.bashrc | head -n 5

# ---------------------------------------------------------------------------
section "4" "把 HDFS 文件夹 test 复制到本地文件系统的 /usr/local/hadoop 目录下"
# ---------------------------------------------------------------------------
echo "\$ hdfs dfs -get /user/hadoop/test /usr/local/hadoop"
run hdfs dfs -get /user/hadoop/test /usr/local/hadoop
echo
echo "-- 查看本地结果"
run ls -l /usr/local/hadoop
echo "\$ ls -la /usr/local/hadoop/test      # -a 才能看到 .bashrc 这个隐藏文件"
run ls -la /usr/local/hadoop/test
echo
echo "-- 校验：本地副本与 HDFS 上文件一致"
echo "HDFS : $(hdfs dfs -cat /user/hadoop/test/.bashrc | md5sum | awk '{print $1}')"
echo "本地 : $(md5sum /usr/local/hadoop/test/.bashrc | awk '{print $1}')"

printf '\n%s\nHadoop（HDFS）基本操作全部题目执行完毕。\n%s\n' "$BANNER" "$BANNER"
