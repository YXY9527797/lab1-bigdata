#!/usr/bin/env bash
# =============================================================================
# hdfs_shell.sh —— 实验一 第 2 部分：用 Hadoop Shell 命令完成 10 道 HDFS 题目
#
# 与 Java API 版本（java/src/main/java/edu/sdu/bigdata/hdfs/）一一对应：
#
#   1) upload   <local>  <hdfs> [append|overwrite]  上传；已存在时由用户选择追加/覆盖
#   2) download <hdfs>   <localdir>                 下载；本地同名文件自动重命名
#   3) cat      <hdfs>                              输出文件内容到终端
#   4) info     <hdfs>                              显示权限/大小/时间/路径
#   5) info-r   <hdfsdir>                           递归显示目录下所有文件的信息
#   6) file     <hdfs>   <create|delete>            文件创建/删除（父目录自动创建）
#   7) dir      <hdfsdir> <create|delete>           目录创建/删除（非空则不删）
#   8) append   <hdfs>   <content> <head|tail>      追加内容到文件开头或结尾
#   9) rm       <hdfs>                              删除指定文件
#  10) mv       <src>    <dst>                      移动文件到目的路径
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$LAB_ROOT/env/hadoop.env.sh"
export HADOOP_USER_NAME="$HDFS_SUPERUSER"

HDFS="hdfs dfs"

die() { echo "错误：$*" >&2; exit 1; }
# 回显将要执行的 Shell 命令
show() { echo "\$ $*"; }

cmd="${1:-}"; shift || true

case "$cmd" in

  # ---------------------------------------------------------------- 题目 1
  upload)
    local_src="${1:-}"; hdfs_dst="${2:-}"; mode="${3:-}"
    [ -n "$local_src" ] && [ -n "$hdfs_dst" ] || die "用法: upload <local> <hdfs> [append|overwrite]"
    [ -f "$local_src" ] || die "本地文件不存在：$local_src"

    # 注意：`hdfs dfs -put` 不会自动创建上级目录，目标目录不存在时会报
    # “No such file or directory”，因此这里先 mkdir -p。
    # （Java 的 FileSystem.copyFromLocalFile 内部会 mkdirs，所以 Java 版不需要这一步
    #   —— 这正是 Shell 命令与 Java API 的一个行为差异，见实验报告问答部分。）
    dst_parent="$(dirname "$hdfs_dst")"
    if ! $HDFS -test -e "$dst_parent"; then
      echo "目标目录 $dst_parent 不存在，先创建"
      show "$HDFS -mkdir -p $dst_parent"
      $HDFS -mkdir -p "$dst_parent" || die "创建目标目录失败"
    fi

    show "$HDFS -test -e $hdfs_dst"
    if $HDFS -test -e "$hdfs_dst"; then
      echo "目标文件 $hdfs_dst 在 HDFS 中已存在"
      if [ -z "$mode" ]; then
        echo "请选择处理方式：[1] 追加到原有文件末尾 (append)  [2] 覆盖原有的文件 (overwrite)"
        read -r -p "请输入 1 或 2：" ans
        case "$ans" in 1|append) mode=append ;; *) mode=overwrite ;; esac
      fi
      if [ "$mode" = "append" ]; then
        show "$HDFS -appendToFile $local_src $hdfs_dst"
        $HDFS -appendToFile "$local_src" "$hdfs_dst" || die "追加失败"
        echo "已把 $local_src 的内容【追加】到 $hdfs_dst 末尾"
      else
        show "$HDFS -put -f $local_src $hdfs_dst"
        $HDFS -put -f "$local_src" "$hdfs_dst" || die "覆盖上传失败"
        echo "已把 $local_src 【覆盖】上传到 $hdfs_dst"
      fi
    else
      echo "目标文件 $hdfs_dst 不存在，直接上传"
      show "$HDFS -put $local_src $hdfs_dst"
      $HDFS -put "$local_src" "$hdfs_dst" || die "上传失败"
      echo "已上传到 $hdfs_dst"
    fi
    show "$HDFS -ls $hdfs_dst"; $HDFS -ls "$hdfs_dst"
    ;;

  # ---------------------------------------------------------------- 题目 2
  download)
    hdfs_src="${1:-}"; local_dir="${2:-}"
    [ -n "$hdfs_src" ] && [ -n "$local_dir" ] || die "用法: download <hdfs> <localdir>"
    show "$HDFS -test -e $hdfs_src"
    $HDFS -test -e "$hdfs_src" || die "HDFS 上不存在该文件：$hdfs_src"
    mkdir -p "$local_dir" || die "无法创建本地目录：$local_dir"

    base="$(basename "$hdfs_src")"
    target="$local_dir/$base"
    if [ -e "$target" ]; then
      echo "本地已存在同名文件 $base，自动重命名："
      i=1
      while [ -e "$local_dir/$base.$i" ]; do i=$((i + 1)); done
      target="$local_dir/$base.$i"
      echo "  -> $(basename "$target")"
    fi
    show "$HDFS -get $hdfs_src $target"
    $HDFS -get "$hdfs_src" "$target" || die "下载失败"
    ls -l "$target"
    ;;

  # ---------------------------------------------------------------- 题目 3
  cat)
    f="${1:-}"; [ -n "$f" ] || die "用法: cat <hdfs>"
    show "$HDFS -cat $f"
    $HDFS -cat "$f" || die "输出失败"
    ;;

  # ---------------------------------------------------------------- 题目 4
  info)
    f="${1:-}"; [ -n "$f" ] || die "用法: info <hdfs>"
    show "$HDFS -ls $f"
    $HDFS -ls "$f" || die "查询失败"
    echo "-- 用 -stat 精确取各项属性（%a 权限 %b 大小 %y 修改时间 %n 路径）"
    show "$HDFS -stat '权限=%a 大小=%b 字节 修改时间=%y 路径=%n' $f"
    $HDFS -stat '权限=%a 大小=%b 字节 修改时间=%y 路径=%n' "$f"
    ;;

  # ---------------------------------------------------------------- 题目 5
  info-r)
    d="${1:-}"; [ -n "$d" ] || die "用法: info-r <hdfsdir>"
    show "$HDFS -ls -R $d"
    $HDFS -ls -R "$d" || die "查询失败"
    ;;

  # ---------------------------------------------------------------- 题目 6
  file)
    f="${1:-}"; action="${2:-create}"
    [ -n "$f" ] || die "用法: file <hdfs> <create|delete>"
    if [ "$action" = "delete" ]; then
      if $HDFS -test -e "$f"; then
        show "$HDFS -rm $f"; $HDFS -rm "$f" || die "删除失败"
        echo "已删除文件：$f"
      else
        echo "文件不存在，无需删除：$f"
      fi
    else
      parent="$(dirname "$f")"
      show "$HDFS -test -e $parent"
      if ! $HDFS -test -e "$parent"; then
        echo "文件所在目录 $parent 不存在，自动创建"
        show "$HDFS -mkdir -p $parent"; $HDFS -mkdir -p "$parent" || die "创建父目录失败"
      fi
      show "$HDFS -touchz $f"; $HDFS -touchz "$f" || die "创建文件失败"
      echo "已创建文件：$f"
      show "$HDFS -ls $f"; $HDFS -ls "$f"
    fi
    ;;

  # ---------------------------------------------------------------- 题目 7
  dir)
    d="${1:-}"; action="${2:-create}"
    [ -n "$d" ] || die "用法: dir <hdfsdir> <create|delete>"
    if [ "$action" = "delete" ]; then
      if ! $HDFS -test -e "$d"; then
        echo "目录不存在，无需删除：$d"; exit 0
      fi
      # 判断目录是否为空：用 `hdfs dfs -count`，输出为“目录数 文件数 总大小 路径”。
      # 坑：这里的“目录数”把该目录**自身**也算进去了，所以空目录返回的是
      #     “1 0 0 /path” 而不是 “0 0 0 /path”，必须减 1 才是子目录个数。
      # （Java 版用 fs.listStatus(path).length == 0 判断，不存在这个坑。）
      read -r dn fn _size _path < <($HDFS -count "$d" | tail -n 1)
      sub_dirs=$(( ${dn:-0} - 1 ))
      [ "$sub_dirs" -lt 0 ] && sub_dirs=0
      if [ "$sub_dirs" -gt 0 ] || [ "${fn:-0}" -gt 0 ]; then
        echo "目录 $d 非空（子目录 $sub_dirs 个、文件 $fn 个），按要求【不删除】："
        show "$HDFS -ls $d"; $HDFS -ls "$d"
      else
        echo "目录 $d 为空（-count 输出：$dn $fn），可以删除"
        show "$HDFS -rmdir $d"; $HDFS -rmdir "$d" || die "删除失败"
        echo "已删除空目录：$d"
      fi
    else
      show "$HDFS -mkdir -p $d"; $HDFS -mkdir -p "$d" || die "创建目录失败"
      echo "已创建目录（父目录不存在时会自动创建）：$d"
      show "$HDFS -ls -d $d"; $HDFS -ls -d "$d"
    fi
    ;;

  # ---------------------------------------------------------------- 题目 8
  append)
    f="${1:-}"; content="${2:-}"; position="${3:-tail}"
    [ -n "$f" ] || die "用法: append <hdfs> <content> <head|tail>"
    $HDFS -test -e "$f" || die "HDFS 上不存在该文件：$f"

    echo "追加前内容："
    echo "--------------------------------------------------"; $HDFS -cat "$f"; echo "--------------------------------------------------"

    tmp="$(mktemp -d)"
    if [ "$position" = "head" ]; then
      echo "追加位置：文件开头（HDFS 的 appendToFile 只能追加到末尾，"
      echo "          因此先把原文件取回本地，按“新内容+原内容”重组后再整体写回）"
      $HDFS -get "$f" "$tmp/old" >/dev/null || die "取回原文件失败"
      { printf '%s\n' "$content"; cat "$tmp/old"; } > "$tmp/new"
      show "$HDFS -rm $f";            $HDFS -rm "$f" >/dev/null || die "删除原文件失败"
      show "$HDFS -put $tmp/new $f";  $HDFS -put "$tmp/new" "$f" || die "写回失败"
    else
      echo "追加位置：文件末尾（使用 hdfs dfs -appendToFile）"
      printf '%s\n' "$content" > "$tmp/append"
      show "$HDFS -appendToFile <新内容> $f"
      $HDFS -appendToFile "$tmp/append" "$f" || die "追加失败"
    fi
    rm -rf "$tmp"

    echo "追加后内容："
    echo "--------------------------------------------------"; $HDFS -cat "$f"; echo "--------------------------------------------------"
    show "$HDFS -ls $f"; $HDFS -ls "$f"
    ;;

  # ---------------------------------------------------------------- 题目 9
  rm)
    f="${1:-}"; [ -n "$f" ] || die "用法: rm <hdfs>"
    if $HDFS -test -e "$f"; then
      show "$HDFS -ls $f"; $HDFS -ls "$f"
      show "$HDFS -rm $f"; $HDFS -rm "$f" || die "删除失败"
      echo "已删除文件：$f"
      show "$HDFS -test -e $f && echo 仍存在 || echo 已不存在"
      $HDFS -test -e "$f" && echo "仍存在" || echo "已不存在"
    else
      echo "文件不存在，无需删除：$f"
    fi
    ;;

  # --------------------------------------------------------------- 题目 10
  mv)
    src="${1:-}"; dst="${2:-}"
    [ -n "$src" ] && [ -n "$dst" ] || die "用法: mv <src> <dst>"
    $HDFS -test -e "$src" || die "源路径不存在：$src"
    parent="$(dirname "$dst")"
    if ! $HDFS -test -e "$parent"; then
      echo "目的目录 $parent 不存在，自动创建"
      show "$HDFS -mkdir -p $parent"; $HDFS -mkdir -p "$parent" || die "创建目的目录失败"
    fi
    show "$HDFS -mv $src $dst"; $HDFS -mv "$src" "$dst" || die "移动失败"
    echo "移动完成：$src  ->  $dst"
    show "$HDFS -ls $dst"; $HDFS -ls "$dst"
    ;;

  *)
    sed -n '3,20p' "$0"
    exit 1
    ;;
esac
