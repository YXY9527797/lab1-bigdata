# 大数据管理与分析 · 实验一：大数据系统基本实验

> 学号：202400390056　姓名：于昕杨　班级：2026 级 1 班

本仓库为《大数据管理与分析》课程**实验一**的完整代码与运行记录，包含三部分内容：

| 部分 | 内容 | 目录 |
| --- | --- | --- |
| 第 1 部分 | 熟悉常用的 Linux 操作和 Hadoop 操作 | [`part1-linux-hadoop/`](part1-linux-hadoop/) |
| 第 2 部分 | 熟悉常用的 HDFS 操作（**Shell 命令 + Java API 两套实现**） | [`part2-hdfs/`](part2-hdfs/) |
| 第 3 部分 | MapReduce 初级编程（合并去重 / 排序 / 祖孙关系挖掘） | [`part3-mapreduce/`](part3-mapreduce/) |

实验报告见 [`report/202400390056-于昕杨-实验一.pdf`](report/)（源码 `report/report.html`）。

---

## 一、目录结构

```
lab1-bigdata/
├── env/                      Hadoop 单节点环境（配置模板 + 集群启停脚本）
│   ├── hadoop.env.sh         统一的环境变量（其它脚本 source 它）
│   ├── templates/            core-site / hdfs-site / mapred-site / yarn-site 模板
│   ├── setup-env.sh          由模板生成配置，可选格式化 NameNode
│   ├── start-hadoop.sh       启动 HDFS + YARN（支持 --direct 免 ssh 方式）
│   ├── stop-hadoop.sh        停止 HDFS + YARN
│   ├── run-cluster.sh        不依赖 ssh 的前台集群监管脚本
│   └── lab-root.sh           在“可写根视图”中执行命令（无 root 权限时用）
│
├── part1-linux-hadoop/
│   ├── linux_basics.sh       教材 17 道 Linux 题目（全部真实执行并回显）
│   ├── hadoop_basics.sh      Hadoop 启动 + HDFS 用户目录/上传/取回 4 道题
│   ├── run.sh                运行 Linux 题目并留存日志
│   └── run-hadoop-basics.sh  运行 Hadoop 题目并留存日志
│
├── part2-hdfs/
│   ├── hdfs_shell.sh         Shell 命令实现的 10 道 HDFS 题目
│   ├── test-sequence.sh      统一的 10 道题测试场景（两个实现共用）
│   ├── run-shell.sh          跑 Shell 实现
│   ├── run-java.sh           跑 Java 实现
│   ├── run-all.sh            两个实现都跑一遍
│   └── java/                 Java API 实现（10 个任务类 + 工具类 + 统一 CLI + pom.xml）
│
├── part3-mapreduce/
│   ├── src/main/java/edu/sdu/bigdata/mr/
│   │   ├── MergeDedup.java   题目1 文件合并与去重
│   │   ├── SortAndRank.java  题目2 整数排序并输出位次
│   │   ├── GrandParent.java  题目3 child-parent 表挖掘祖孙关系
│   │   └── MrLab.java        统一 CLI 入口
│   ├── input/                三个作业的输入数据（与教材样例一致）
│   ├── expected/             标准答案，用于 diff 自动校验
│   ├── build.sh / run.sh     编译 / 一键运行（支持 local 模式）
│   └── pom.xml
│
├── report/                   实验报告（HTML 源 + PDF/DOCX + 生成脚本）
├── tools/
│   └── push-to-github.sh     一键在 GitHub 创建公开仓库并推送
└── docs/run-logs/            各步骤的真实运行日志（约 1760 行）
```

---

## 二、实验环境

| 项目 | 版本 |
| --- | --- |
| 操作系统 | Ubuntu 22.04.5 LTS（Linux 6.8.0-40-generic，4 核 / 7.7 GB 内存） |
| JDK | OpenJDK 11.0.32 |
| Hadoop | Apache Hadoop 3.3.6，**伪分布式**（NameNode / DataNode / ResourceManager / NodeManager 同机） |
| 其它 | bash、GNU coreutils、git、LibreOffice（报告排版） |

集群地址：HDFS `hdfs://localhost:9000`，NameNode UI <http://localhost:9870>，YARN UI <http://localhost:8088>。

---

## 三、如何复现

### 1. 准备并启动 Hadoop 单节点集群

```bash
# 生成配置（路径自动替换为本机真实路径）；首次运行加 --format 格式化 NameNode
./env/setup-env.sh --format

# 启动 HDFS + YARN
./env/start-hadoop.sh --direct     # 无免密 ssh 时用 --direct；有 ssh 可直接 ./env/start-hadoop.sh
./env/run-cluster.sh               # 或者：前台监管方式启动（容器/CI 里推荐）
```

> 官方 `start-dfs.sh` / `start-yarn.sh` 会通过 `ssh localhost` 拉起守护进程，
> 需要配置免密 SSH；若不可用，用 `--direct` 或 `run-cluster.sh` 直接拉起。

### 2. 第 1 部分：Linux 与 Hadoop 基本操作

```bash
./part1-linux-hadoop/run.sh                 # 17 道 Linux 题目
./part1-linux-hadoop/run-hadoop-basics.sh   # 4 道 Hadoop/HDFS 题目
```

### 3. 第 2 部分：HDFS 常用操作（两种实现）

```bash
./part2-hdfs/run-all.sh     # 依次跑 Shell 实现与 Java 实现，输出与标准答案对照
# 也可以单独跑：
./part2-hdfs/run-shell.sh
./part2-hdfs/run-java.sh
# Java 实现也可手动调用：
./part2-hdfs/java/run-hdfs-lab.sh info /user/hadoop/test/.bashrc
```

### 4. 第 3 部分：MapReduce 三个作业

```bash
./part3-mapreduce/run.sh          # 提交到 YARN（真实分布式框架）
./part3-mapreduce/run.sh local    # 用 LocalJobRunner 单进程跑，便于调试
```

---

## 四、实验结果

全部结果均已实测通过，日志见 [`docs/run-logs/`](docs/run-logs/)。

**第 1 部分**：17 道 Linux 题全部真实执行成功；HDFS 上 `/user/hadoop` 属主为
`hadoop:supergroup`，`~/.bashrc`（3968 字节）上传后与本地 MD5 一致
（`dacd0a2d71506e39140b00bcdf3007eb`），并成功取回本地 `/usr/local/hadoop/test`。

**第 2 部分**：Shell 与 Java 两套实现跑同一测试场景，10 道题全部成功、结果逐条一致。

**第 3 部分**：三个作业在 YARN 上运行成功，输出与 `expected/` 标准答案 `diff` 完全一致。

| 题目 | 作业 ID | Map / Reduce | 输出 |
| --- | --- | --- | --- |
| 1 合并去重 | job_1790871965624_0002 | 2 / 1 | 11 条输入 → 9 条输出（去掉 2 条重复） |
| 2 排序编号 | job_1790871965624_0003 | 3 / 1 | 11 个整数升序 + 连续位次 1~11 |
| 3 祖孙挖掘 | job_1790871965624_0004 | 1 / 1 | 14 条 child-parent → 12 组祖孙关系 |

---

## 五、实验中踩到的几个坑（值得记录）

1. **无 root 权限时如何完成写 `/usr`、`/` 和 `chown root` 的题目**
   `env/lab-root.sh` 借助 Linux 用户命名空间（`unshare -r`）取得映射 root 身份，
   再用 bind mount + `chroot` 构造一个“可写的根视图”：`/`、`/usr`、`/usr/local`、
   `/usr/local/hadoop` 这几层是新目录（可写），其下真实内容（`/usr/bin`、
   `/usr/local/hadoop/...`）逐项 bind 进来原样可见。于是命令路径与教材完全一致、
   全部真实执行成功，而所有写操作只落在临时视图里，真实系统不受影响。

2. **`rmdir -p /tmp/a1/a2/a3/a4` 会一路删到 `/tmp`**
   `-p` 会继续删除“已经变空”的父目录。真实系统上 `/tmp` 是挂载点，删除会因
   `EBUSY` 被拒绝（报“设备或资源忙”）；若 `/tmp` 只是普通目录，它会被删掉，
   连累后面所有涉及 `/tmp` 的题目。实验里刻意把视图中的 `/tmp` 也做成挂载点，
   使行为与真实系统一致。

3. **YARN 容器启动失败：中文路径 + locale 被裁剪**
   仓库路径含中文（“文档”）时，容器 JVM 的 locale 是 ASCII，路径里的中文被替换成
   `??????`，导致容器创建日志目录失败（`container-launch` 异常）。解决：在
   `yarn-site.xml` 的 `yarn.nodemanager.env-whitelist` 中补上 `LANG,LC_ALL,LANGUAGE`，
   并在 `mapred-site.xml` 中为容器 JVM 指定 `-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8`。

4. **Shell 与 Java API 的 3 处行为差异**
   - `hdfs dfs -put` **不会**自动创建父目录，Java 的 `copyFromLocalFile` 内部会 `mkdirs`；
   - `hdfs dfs -count` 输出的“目录数”**包含目录自身**，用它判空会误判，而
     `listStatus().length == 0` 没有这个问题；
   - HDFS 的 `append` 只能追加到**末尾**，要实现“追加到开头”只能读出原内容后
     删除重建（整体重写）。

---

## 六、说明

* **报告排版**：`report/report.html` 中 CSS 设定为宋体、小四（12pt）、1.25 倍行距、A4，
  由 `report/build-report.sh` 调用 LibreOffice 生成 PDF 与 DOCX。
  本机未安装“宋体/SimSun”字体，PDF 渲染时会自动替换为同为衬线的 Noto Serif CJK SC，
  文档中声明的字体仍是宋体。
* **配置目录** `env/hadoop-conf/` 由 `env/setup-env.sh` 从 `env/templates/` 生成，
  含本机绝对路径，因此未纳入版本控制；克隆后执行一次 `setup-env.sh` 即可。
