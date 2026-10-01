#!/usr/bin/env bash
# =============================================================================
# lab-root.sh —— 在“可写的根视图”里执行一条命令
#
# 为什么需要它：
#   教材第一部分若干题目要求写系统目录或需要 root 身份，例如
#       mkdir /test                     （在根目录下建目录）
#       cp ~/.bashrc /usr/bashrc1       （向 /usr 写文件）
#       chown root /tmp/hello           （改属主为 root）
#   如果当前账户没有 sudo 权限，这些命令会因 EACCES 失败，报告里就只能写
#   “权限不足”，拿不到真实执行结果。
#
# 做法：
#   先用 `unshare -r` 进入一个用户命名空间，在那里获得一个“映射的 root 身份”；
#   再用 bind mount + chroot 构造可写的根视图（见 _lab-root-enter.sh）。
#   于是命令中的路径与教科书完全一致（/usr、/test、/tmp、~ …），
#   而所有写操作都落在 /tmp 下的临时视图里，真实系统始终只读、毫发无损。
#
# 用法：
#   ./env/lab-root.sh /bin/bash /path/to/script.sh arg1 arg2
#   ./env/lab-root.sh --print-view          # 只打印视图根目录
# =============================================================================
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 根视图放在 /tmp（每次运行都是一块干净的 tmpfs），不污染仓库、也不会递归
ROOT_VIEW="${LAB_ROOT_VIEW:-/tmp/lab1-bigdata-root-view}"

if [ "${1:-}" = "--print-view" ]; then echo "$ROOT_VIEW"; exit 0; fi

export HOME="${HOME:-/home/$(id -un)}"

exec unshare -r -m "$ENV_DIR/_lab-root-enter.sh" "$ROOT_VIEW" "$@"
