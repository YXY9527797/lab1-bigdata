#!/usr/bin/env bash
# =============================================================================
# hadoop.env.sh —— 实验统一的 Hadoop 环境变量
#   其它脚本通过 `source env/hadoop.env.sh` 引用，保证使用同一套配置目录、
#   同一套日志目录，从而让每次实验的日志可复现。
# =============================================================================

# 本仓库根目录（本文件位于 <repo>/env/ 下）
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LAB_ROOT

# ---- JDK：Hadoop 3.3.6 需要 JDK 8/11，本机使用 JDK 11 --------------------
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-11-openjdk-amd64}"

# ---- Hadoop 安装目录 ------------------------------------------------------
export HADOOP_HOME="${HADOOP_HOME:-/usr/local/hadoop}"

# ---- 使用实验自带的配置目录，而不是 $HADOOP_HOME/etc/hadoop --------------
export HADOOP_CONF_DIR="$LAB_ROOT/env/hadoop-conf"
export HADOOP_LOG_DIR="$LAB_ROOT/env/logs"
export HADOOP_PID_DIR="$LAB_ROOT/env/pids"
export HADOOP_MAPRED_HOME="$HADOOP_HOME"
export HADOOP_COMMON_HOME="$HADOOP_HOME"
export HADOOP_HDFS_HOME="$HADOOP_HOME"
export HADOOP_YARN_HOME="$HADOOP_HOME"

# Hadoop 自带 native 库
export LD_LIBRARY_PATH="$HADOOP_HOME/lib/native:${LD_LIBRARY_PATH:-}"

export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

# ---- UTF-8 locale ---------------------------------------------------------
# 本实验仓库可能位于含中文的路径下（例如 …/文档/…）。YARN 容器与 JVM 需要
# UTF-8 的 locale 才能正确解析这类路径，否则中文会被替换成 '?'，容器启动时
# 创建日志目录失败（container-launch 异常）。
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"

# ---- 常用别名变量 ---------------------------------------------------------
export HDFS_URI="hdfs://localhost:9000"   # 与 core-site.xml 中 fs.defaultFS 一致
export HDFS_USER="$(whoami)"

# HDFS 超级用户 = 启动 NameNode 的那个操作系统用户 = 元数据目录属主。
# 当脚本运行在“可写根视图”（用户命名空间）里时 whoami 是 root，与 HDFS 中
# 记录的超级用户不一致，会导致建 /user/hadoop 被拒；因此显式取元数据目录属主。
export HDFS_SUPERUSER="${HDFS_SUPERUSER:-$(stat -c %U "$LAB_ROOT/env/hadoopdata/name" 2>/dev/null || whoami)}"
