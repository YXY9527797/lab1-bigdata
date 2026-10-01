#!/usr/bin/env bash
# =============================================================================
# linux_basics.sh —— 实验一 第 1 部分：熟悉常用的 Linux 操作
#
# 覆盖教材列出的全部题目：
#   1.cd  2.ls  3.mkdir  4.rmdir  5.cp  6.mv  7.rm  8.cat  9.tac  10.more
#   11.head 12.tail 13.touch 14.chown 15.find 16.tar 17.grep
#
# 执行方式（任选其一）：
#   A. 有 root / sudo 权限的普通机器：  bash linux_basics.sh
#   B. 无 root 权限（本实验环境）：      ../env/lab-root.sh /bin/bash linux_basics.sh
#      后者会在用户命名空间里构造一个“可写的根视图”，使 /usr、/ 的写操作
#      与 `chown root` 都能真实成功，且不影响真实系统。
#
# 脚本以 `$ ` 开头回显每一条命令，紧跟其真实输出，便于直接摘录进实验报告。
# =============================================================================
set -u

# 在“可写根视图”中运行时，HOME 已由 env/lab-root.sh 传递进来；
# 这里统一回到用户主目录，保证后续相对路径行为一致。
cd "$HOME" || exit 1

BANNER="────────────────────────────────────────────────────────────────────────"
section() { printf '\n%s\n【%s】%s\n%s\n' "$BANNER" "$1" "$2" "$BANNER"; }
# 回显并执行命令
run() { echo "\$ $*"; "$@"; }

echo "################ 实验一 · Linux 常用操作 ################"
echo "执行用户 : $(id -un)   uid=$(id -u)"
echo "用户主目录: $HOME"
echo "当前目录 : $(pwd)"
echo "系统信息 : $(uname -srm)"
echo "发行版本 : $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"

# ---------------------------------------------------------------------------
section "1" "cd 命令：切换目录"
# ---------------------------------------------------------------------------
echo "-- (1) 切换到目录 /usr/local"
cd /usr/local && echo "\$ cd /usr/local" && echo "当前目录：$(pwd)"
echo
echo "-- (2) 切换到当前目录的上一级目录"
cd .. && echo "\$ cd .." && echo "当前目录：$(pwd)"
echo
echo "-- (3) 切换到当前登录用户自己的主文件夹"
cd ~ && echo "\$ cd ~" && echo "当前目录：$(pwd)"

# ---------------------------------------------------------------------------
section "2" "ls 命令：查看文件与目录"
# ---------------------------------------------------------------------------
echo "-- 查看目录 /usr 下的所有文件和目录"
run ls -l /usr
echo
echo "-- 等价的常用写法：ls /usr（只列名字，按列排列）"
run ls /usr

# ---------------------------------------------------------------------------
section "3" "mkdir 命令：新建目录"
# ---------------------------------------------------------------------------
echo "-- (1) 进入 /tmp，创建目录 a，并查看 /tmp 下已经存在哪些目录"
cd /tmp && echo "\$ cd /tmp" && echo "当前目录：$(pwd)"
run mkdir a
echo "\$ ls -l /tmp        # 查看 /tmp 下已有的目录"
run ls -l /tmp
echo
echo "-- (2) 进入 /tmp，创建目录 a1/a2/a3/a4（-p 递归创建）"
cd /tmp && run mkdir -p a1/a2/a3/a4
echo "\$ find /tmp/a1 -type d" && find /tmp/a1 -type d

# ---------------------------------------------------------------------------
section "4" "rmdir 命令：删除空的目录"
# ---------------------------------------------------------------------------
echo "-- (1) 删除 /tmp 下上面创建的目录 a"
run rmdir /tmp/a
echo "\$ ls -d /tmp/a ; echo 删除后是否存在：\$?" && { ls -d /tmp/a 2>&1; echo "退出码=$? (非 0 表示已删除)"; }
echo
echo "-- (2) 删除目录 a1/a2/a3/a4，然后查看 /tmp 下还有哪些目录"
# rmdir -p 从最深层开始逐级删除，并且会继续向上删除“已经变空”的父目录。
# 依次删掉 a4→a3→a2→a1 之后，它还会尝试删掉 /tmp，但 /tmp 是挂载点，于是报
# “设备或资源忙”并停下 —— 真实 Linux 上行为完全相同（并非配置错误）。
run rmdir -p /tmp/a1/a2/a3/a4
echo "（说明：a4/a3/a2/a1 已被逐级删除；再向上删 /tmp 时因它是挂载点而被拒绝）"
echo "\$ ls -l /tmp        # 此时 /tmp 下已经没有 a、a1 等目录"
run ls -l /tmp
echo "\$ find /tmp -maxdepth 1 -name 'a*' | wc -l    # 期望输出 0"
find /tmp -maxdepth 1 -name 'a*' | wc -l

# ---------------------------------------------------------------------------
section "5" "cp 命令：复制文件或目录"
# ---------------------------------------------------------------------------
echo "-- (1) 把主文件夹下的 .bashrc 复制到 /usr 下，并重命名为 bashrc1"
run cp "$HOME/.bashrc" /usr/bashrc1
run ls -l /usr/bashrc1
echo
echo "-- (2) 在 /tmp 下新建目录 test，再把这个目录复制到 /usr 目录下"
run mkdir /tmp/test
run cp -r /tmp/test /usr
echo "\$ ls -ld /usr/test" && ls -ld /usr/test

# ---------------------------------------------------------------------------
section "6" "mv 命令：移动文件与目录，或更名"
# ---------------------------------------------------------------------------
echo "-- (1) 把 /usr 目录下的文件 bashrc1 移动到 /usr/test 目录下"
run mv /usr/bashrc1 /usr/test
echo "\$ ls -l /usr/test" && ls -l /usr/test
echo
echo "-- (2) 把 /usr 目录下的 test 目录重命名为 test2"
run mv /usr/test /usr/test2
echo "\$ ls -ld /usr/test2" && ls -ld /usr/test2

# ---------------------------------------------------------------------------
section "7" "rm 命令：移除文件或目录"
# ---------------------------------------------------------------------------
echo "-- (1) 把 /usr/test2 目录下的 bashrc1 文件删除"
run rm /usr/test2/bashrc1
echo "\$ ls -la /usr/test2" && ls -la /usr/test2
echo
echo "-- (2) 把 /usr 目录下的 test2 目录删除（-r 递归删除目录）"
run rm -r /usr/test2
echo "\$ ls -ld /usr/test2 ; echo 删除后是否存在：\$?" && { ls -ld /usr/test2 2>&1; echo "退出码=$? (非 0 表示已删除)"; }

# ---------------------------------------------------------------------------
section "8" "cat 命令：查看文件内容"
# ---------------------------------------------------------------------------
echo "\$ cat ~/.bashrc"
run cat "$HOME/.bashrc"

# ---------------------------------------------------------------------------
section "9" "tac 命令：反向查看文件内容"
# ---------------------------------------------------------------------------
echo "\$ tac ~/.bashrc      # 从最后一行往前显示"
run tac "$HOME/.bashrc"

# ---------------------------------------------------------------------------
section "10" "more 命令：一页一页翻动查看"
# ---------------------------------------------------------------------------
echo "说明：more 是交互式分页器，在终端里可用 空格(下一页)/Enter(下一行)/q(退出)。"
echo "      在非交互脚本中它退化为一次性输出，这里用 more -n 限定页长以便观察分页效果。"
echo "\$ more -10 ~/.bashrc"
run more -10 "$HOME/.bashrc"

# ---------------------------------------------------------------------------
section "11" "head 命令：取出前面几行"
# ---------------------------------------------------------------------------
echo "-- (1) 查看 ~/.bashrc 前 20 行"
run head -n 20 "$HOME/.bashrc"
echo
echo "-- (2) 查看 ~/.bashrc，后面 50 行不显示，只显示前面几行"
echo "\$ head -n -50 ~/.bashrc     # 负号表示“去掉末尾 50 行”"
run head -n -50 "$HOME/.bashrc"

# ---------------------------------------------------------------------------
section "12" "tail 命令：取出后面几行"
# ---------------------------------------------------------------------------
echo "-- (1) 查看 ~/.bashrc 最后 20 行"
run tail -n 20 "$HOME/.bashrc"
echo
echo "-- (2) 查看 ~/.bashrc，并且只列出 50 行以后的数据"
echo "\$ tail -n +51 ~/.bashrc     # +51 表示从第 51 行开始输出到末尾"
run tail -n +51 "$HOME/.bashrc"

# ---------------------------------------------------------------------------
section "13" "touch 命令：修改文件时间或创建新文件"
# ---------------------------------------------------------------------------
echo "-- (1) 在 /tmp 下创建一个空文件 hello，并查看文件时间"
run touch /tmp/hello
echo "\$ ls -l --time-style=full-iso /tmp/hello" && ls -l --time-style=full-iso /tmp/hello
echo "\$ stat /tmp/hello" && stat /tmp/hello
echo
echo "-- (2) 修改 hello 文件，将文件时间整为 5 天前"
run touch -d "5 days ago" /tmp/hello
echo "\$ ls -l --time-style=full-iso /tmp/hello" && ls -l --time-style=full-iso /tmp/hello
echo "\$ date -d '5 days ago'" && date -d '5 days ago'

# ---------------------------------------------------------------------------
section "14" "chown 命令：修改文件所有者权限"
# ---------------------------------------------------------------------------
echo "-- 将 hello 文件所有者改为 root 帐号，并查看属性"
run chown root /tmp/hello
echo "\$ ls -l /tmp/hello" && ls -l /tmp/hello
echo "\$ stat -c '文件=%n 属主=%U 属组=%G 权限=%A' /tmp/hello" && \
  stat -c '文件=%n 属主=%U 属组=%G 权限=%A' /tmp/hello

# ---------------------------------------------------------------------------
section "15" "find 命令：文件查找"
# ---------------------------------------------------------------------------
echo "-- 找出主文件夹下文件名为 .bashrc 的文件"
echo "\$ find ~ -name .bashrc"
run find "$HOME" -name .bashrc

# ---------------------------------------------------------------------------
section "16" "tar 命令：压缩命令"
# ---------------------------------------------------------------------------
echo "-- (1) 在根目录 / 下新建文件夹 test，然后在根目录 / 下打包成 test.tar.gz"
run mkdir /test
run touch /test/file1.txt /test/file2.txt
echo "\$ ls -l /test" && ls -l /test
cd / && echo "\$ cd /" && echo "当前目录：$(pwd)"
run tar -czf /test.tar.gz test
echo "\$ ls -lh /test.tar.gz" && ls -lh /test.tar.gz
echo "\$ tar -tzvf /test.tar.gz   # 查看压缩包内容"
run tar -tzvf /test.tar.gz
echo
echo "-- (2) 把上面的 test.tar.gz 压缩包解压缩到 /tmp 目录"
run tar -xzf /test.tar.gz -C /tmp
echo "\$ ls -l /tmp/test" && ls -l /tmp/test

# ---------------------------------------------------------------------------
section "17" "grep 命令：查找字符串"
# ---------------------------------------------------------------------------
echo "-- 从 ~/.bashrc 文件中查找字符串 'examples'"
echo "\$ grep -n 'examples' ~/.bashrc"
run grep -n 'examples' "$HOME/.bashrc"
echo "退出码=$? （0 表示找到匹配行）"

printf '\n%s\nLinux 常用操作全部题目执行完毕。\n%s\n' "$BANNER" "$BANNER"
