#!/usr/bin/env bash
# =============================================================================
# _lab-root-enter.sh —— 内部脚本，由 lab-root.sh 在“用户命名空间”中调用
#
# 职责：搭建一棵“顶层可写的根文件系统视图”，然后 chroot 进去执行用户命令。
#
# 视图的构造原则 —— “需要写入的那一层换成新的空目录，其余子项原样 bind 进来”：
#   根 /                    : 新目录（可写），/ 下每个顶层条目单独 bind 进来，
#                             这样 `mkdir /test`、`tar -czf /test.tar.gz` 都能成功；
#   /usr                    : 新目录（可写），/usr/bin、/usr/lib、/usr/local …
#                             每个子目录单独 bind 进来；
#   /usr/local              : 同上（第 4 项要把内容复制到 /usr/local/hadoop 下）；
#   /usr/local/hadoop       : 同上，因此 `hdfs dfs -get /user/hadoop/test /usr/local/hadoop`
#                             可以真实完成，同时 /usr/local/hadoop/bin、etc、share
#                             等真实内容仍然可见；
#   /tmp                    : 干净、可写，并且做成挂载点（与真实系统一致）。
#
# 效果：命令中的路径与教科书完全一致（/usr、/test、/tmp、~ …），
#       而所有写操作都落在 /tmp 下的临时视图里，真实系统只读、毫发无损。
# =============================================================================
set -euo pipefail

ROOT_VIEW="$1"; shift

# 关闭挂载传播，避免视图内新建的挂载递归回流到原 /home 等目录
mount --make-rprivate / 2>/dev/null || true

rm -rf "$ROOT_VIEW"
mkdir -p "$ROOT_VIEW"

# bind_entry <真实路径> <视图路径>
#   目录用 --rbind（连同其下的子挂载一起）；普通文件/符号链接先造一个空文件
#   再 --bind。/swapfile、/vmlinuz 这类根目录下的普通文件必须这样处理，否则
#   rbind 会因为“目标不是目录”而失败。
bind_entry() {
  local src="$1" dst="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dst"
    mount --rbind "$src" "$dst"
  else
    : > "$dst"
    mount --bind "$src" "$dst"
  fi
}

# writable_chain <真实目录> <视图目录> <继续下钻的相对路径>
#   把 <视图目录> 建成可写空目录，其中 src 的每个子项都 bind 进来；
#   <相对路径> 指向的那个子项不直接 bind，而是递归地再做成“可写影子”。
writable_chain() {
  local src="$1" dst="$2" chain="${3:-}"
  local next="" remain=""
  if [ -n "$chain" ]; then
    next="${chain%%/*}"
    remain="${chain#*/}"
    [ "$remain" = "$chain" ] && remain=""
  fi

  mkdir -p "$dst"
  local sub b
  for sub in "$src"/*; do
    [ -e "$sub" ] || continue
    b="$(basename "$sub")"
    [ -n "$next" ] && [ "$b" = "$next" ] && continue
    bind_entry "$sub" "$dst/$b"
  done

  if [ -n "$next" ]; then
    writable_chain "$src/$next" "$dst/$next" "$remain"
  fi
}

# --- 1) 根 / 这一层可写；/usr 与 /tmp 稍后单独处理 -------------------------
for sub in /*; do
  b="$(basename "$sub")"
  case "$b" in usr|tmp) continue ;; esac
  bind_entry "$sub" "$ROOT_VIEW/$b"
done

# --- 2) /usr、/usr/local、/usr/local/hadoop 逐层可写 ------------------------
writable_chain /usr "$ROOT_VIEW/usr" "local/hadoop"

# --- 3) /tmp：干净可写，且是挂载点（与真实 Linux 一致） ---------------------
mkdir -p "$ROOT_VIEW/tmp"
chmod 1777 "$ROOT_VIEW/tmp"
mount --bind "$ROOT_VIEW/tmp" "$ROOT_VIEW/tmp"

exec chroot "$ROOT_VIEW" "$@"
