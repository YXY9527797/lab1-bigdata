#!/usr/bin/env bash
# =============================================================================
# part2-hdfs/java/build.sh —— 编译 HDFS Java API 实验代码
#
# 直接用 javac + `hadoop classpath` 编译，不依赖 Maven（离线环境也能用）。
# 需要 Maven 时也可以用同目录下的 pom.xml（见 README）。
# =============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/../.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"

OUT="$DIR/build"
CLASSES="$OUT/classes"
JAR="$OUT/hdfs-lab.jar"

echo "[build] 收集 Hadoop 依赖 classpath ..."
CP="$(hadoop classpath)"
echo "[build] classpath 长度：${#CP} 字符"

rm -rf "$CLASSES"
mkdir -p "$CLASSES"

echo "[build] 待编译的源文件："
find "$DIR/src/main/java" -name '*.java' | sort | tee "$OUT/sources.txt"

javac -encoding UTF-8 --release 8 \
      -cp "$CP" \
      -d "$CLASSES" \
      @"$OUT/sources.txt"

echo "[build] 打包 $JAR"
jar cf "$JAR" -C "$CLASSES" .
echo "[build] 完成：$JAR"
ls -l "$JAR"
