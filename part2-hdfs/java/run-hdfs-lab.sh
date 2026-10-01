#!/usr/bin/env bash
# =============================================================================
# part2-hdfs/java/run-hdfs-lab.sh —— HdfsLab 命令行包装脚本
#
# 作用：准备好 Hadoop classpath 与 HADOOP_USER_NAME，让 test-sequence.sh 可以
#       像调用一个普通命令那样调用 Java 实现：
#           ./run-hdfs-lab.sh info /user/yxy/hdfs-lab-java/upload.txt
# =============================================================================
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"

# 在“可写根视图”等场景下 whoami 可能不是 HDFS 超级用户，这里显式指定
export HADOOP_USER_NAME="${HADOOP_USER_NAME:-$HDFS_SUPERUSER}"

JAR="$DIR/build/hdfs-lab.jar"
if [ ! -f "$JAR" ]; then
  echo "错误：未找到 $JAR，请先执行 part2-hdfs/java/build.sh" >&2
  exit 1
fi

CP="$JAR:$HADOOP_CONF_DIR:$(hadoop classpath)"
exec java -Dfile.encoding=UTF-8 -cp "$CP" edu.sdu.bigdata.hdfs.HdfsLab "$@"
