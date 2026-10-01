#!/usr/bin/env bash
# =============================================================================
# part2-hdfs/test-sequence.sh —— 统一的 10 道 HDFS 题目测试场景
#
# 同一套场景分别喂给两个实现，便于报告里直接对照：
#   * Shell 实现 : part2-hdfs/hdfs_shell.sh
#   * Java 实现  : part2-hdfs/java/run-hdfs-lab.sh
#
# 用法:  test-sequence.sh <实现命令> <HDFS 实验根目录> <本地工作目录>
# =============================================================================
set -uo pipefail

IMPL="$1"
BASE="$2"
LOCAL="$3"

mkdir -p "$LOCAL"

step()  { echo; echo "==================== $* ===================="; }

# 准备本地测试数据
cat > "$LOCAL/input.txt" <<'EOF'
Hello HDFS
大数据系统基本实验
实验一 第 2 部分
EOF
cat > "$LOCAL/more.txt" <<'EOF'
===== 用户选择「追加」时写入的这一行 =====
EOF

# ---------------------------------------------------------------- 题目 1
step "题目1-① 上传（目标不存在，直接上传）"
"$IMPL" upload "$LOCAL/input.txt" "$BASE/upload.txt" overwrite

step "题目1-② 上传（目标已存在，指定 overwrite 覆盖）"
"$IMPL" upload "$LOCAL/input.txt" "$BASE/upload.txt" overwrite

step "题目1-③ 上传（目标已存在，未指定模式 -> 由用户交互指定：这里输入 1 = 追加）"
printf '1\n' | "$IMPL" upload "$LOCAL/more.txt" "$BASE/upload.txt"

# ---------------------------------------------------------------- 题目 2
step "题目2-① 下载（本地无同名文件）"
"$IMPL" download "$BASE/upload.txt" "$LOCAL/download"

step "题目2-② 下载（本地已有同名文件 -> 自动重命名）"
"$IMPL" download "$BASE/upload.txt" "$LOCAL/download"

echo "-- 本地下载目录内容："
ls -l "$LOCAL/download"

# ---------------------------------------------------------------- 题目 3
step "题目3 把 HDFS 中指定文件的内容输出到终端"
"$IMPL" cat "$BASE/upload.txt"

# ---------------------------------------------------------------- 题目 4
step "题目4 显示指定文件的权限、大小、创建时间、路径"
"$IMPL" info "$BASE/upload.txt"

# ---------------------------------------------------------------- 题目 5
step "题目5 递归显示指定目录下所有文件的信息"
"$IMPL" info-r "$BASE"

# ---------------------------------------------------------------- 题目 6
step "题目6-① 创建文件（所在目录不存在 -> 自动创建目录）"
"$IMPL" file "$BASE/newdir1/newdir2/created.txt" create

step "题目6-② 删除该文件"
"$IMPL" file "$BASE/newdir1/newdir2/created.txt" delete

step "题目6-③ 删除一个不存在的文件"
"$IMPL" file "$BASE/no-such-file.txt" delete

# ---------------------------------------------------------------- 题目 7
step "题目7-① 创建目录（父目录不存在 -> 自动创建）"
"$IMPL" dir "$BASE/emptydir" create

step "题目7-② 删除空目录（应当删除成功）"
"$IMPL" dir "$BASE/emptydir" delete

step "题目7-③ 造一个非空目录"
"$IMPL" dir "$BASE/nonempty/sub" create
"$IMPL" upload "$LOCAL/input.txt" "$BASE/nonempty/sub/keep.txt" overwrite

step "题目7-④ 删除非空目录（按要求不删除）"
"$IMPL" dir "$BASE/nonempty" delete

# ---------------------------------------------------------------- 题目 8
step "题目8-① 追加内容到文件【末尾】"
"$IMPL" append "$BASE/upload.txt" ">>> 这一行追加在文件末尾 <<<" tail

step "题目8-② 追加内容到文件【开头】"
"$IMPL" append "$BASE/upload.txt" ">>> 这一行追加在文件开头 <<<" head

# ---------------------------------------------------------------- 题目 9
step "题目9 删除 HDFS 中指定的文件"
"$IMPL" upload "$LOCAL/input.txt" "$BASE/todelete.txt" overwrite
"$IMPL" rm "$BASE/todelete.txt"

# --------------------------------------------------------------- 题目 10
step "题目10 把文件从源路径移动到目的路径"
"$IMPL" upload "$LOCAL/input.txt" "$BASE/mv-src.txt" overwrite
"$IMPL" mv "$BASE/mv-src.txt" "$BASE/mvdir/mv-dst.txt"

step "收尾：最终 HDFS 实验目录结构"
"$IMPL" info-r "$BASE"
