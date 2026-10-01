#!/usr/bin/env bash
# =============================================================================
# part3-mapreduce/build.sh —— 编译 MapReduce 实验代码并打成 jar
#
# 直接用 javac + `hadoop classpath`，不依赖 Maven（离线环境也能用）。
# =============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"

OUT="$DIR/build"
CLASSES="$OUT/classes"
JAR="$OUT/mr-lab.jar"

echo "[build] 收集 Hadoop 依赖 classpath ..."
CP="$(hadoop classpath)"

rm -rf "$CLASSES"
mkdir -p "$CLASSES"

echo "[build] 待编译的源文件："
find "$DIR/src/main/java" -name '*.java' | sort | tee "$OUT/sources.txt"

javac -encoding UTF-8 --release 8 \
      -cp "$CP" \
      -d "$CLASSES" \
      @"$OUT/sources.txt"

echo "[build] 打包 $JAR"
jar cfe "$JAR" edu.sdu.bigdata.mr.MrLab -C "$CLASSES" .
echo "[build] 完成：$JAR"
ls -l "$JAR"
