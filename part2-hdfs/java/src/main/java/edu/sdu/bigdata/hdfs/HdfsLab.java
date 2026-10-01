package edu.sdu.bigdata.hdfs;

/**
 * 实验一 第 2 部分统一命令行入口：把 10 道 HDFS 题目封装成子命令，
 * 便于一次性演示、也便于与 Shell 版本（part2-hdfs/hdfs_shell.sh）逐条对照。
 *
 * <pre>
 * 用法: HdfsLab &lt;子命令&gt; [参数...]
 *   1) upload   &lt;local&gt;  &lt;hdfs&gt; [append|overwrite]  上传（已存在时用户选择追加/覆盖）
 *   2) download &lt;hdfs&gt;   &lt;localdir&gt;                 下载（本地同名文件自动重命名）
 *   3) cat      &lt;hdfs&gt;                              输出文件内容到终端
 *   4) info     &lt;hdfs&gt;                              显示权限/大小/时间/路径
 *   5) info-r   &lt;hdfsdir&gt;                           递归显示目录下所有文件的信息
 *   6) file     &lt;hdfs&gt;   &lt;create|delete&gt;            文件创建/删除（父目录自动创建）
 *   7) dir      &lt;hdfsdir&gt; &lt;create|delete&gt;           目录创建/删除（非空不删）
 *   8) append   &lt;hdfs&gt;   &lt;content&gt; &lt;head|tail&gt;      追加内容到文件开头/结尾
 *   9) rm       &lt;hdfs&gt;                              删除指定文件
 *  10) mv       &lt;src&gt;    &lt;dst&gt;                      移动文件到目的路径
 * </pre>
 */
public final class HdfsLab {

    public static void main(String[] args) {
        if (args.length == 0) {
            usage();
            System.exit(1);
        }
        String cmd = args[0].toLowerCase();
        try {
            switch (cmd) {
                case "upload":
                    require(args, 3, "upload <local> <hdfs> [append|overwrite]");
                    System.out.println("【题目1】向 HDFS 上传文件"
                            + (args.length > 3 ? "（用户指定模式：" + args[3] + "）" : "（已存在时交互式询问用户）"));
                    UploadFile.run(args[1], args[2], args.length > 3 ? args[3] : null);
                    break;

                case "download":
                    require(args, 3, "download <hdfs> <localdir>");
                    System.out.println("【题目2】从 HDFS 下载文件（本地同名则自动重命名）");
                    DownloadFile.run(args[1], args[2]);
                    break;

                case "cat":
                    require(args, 2, "cat <hdfs>");
                    System.out.println("【题目3】把 HDFS 文件内容输出到终端");
                    CatFile.run(args[1]);
                    break;

                case "info":
                    require(args, 2, "info <hdfs>");
                    System.out.println("【题目4】显示 HDFS 文件的权限/大小/创建时间/路径");
                    FileInfo.showFile(args[1]);
                    break;

                case "info-r":
                    require(args, 2, "info-r <hdfsdir>");
                    System.out.println("【题目5】递归显示 HDFS 目录下所有文件的信息");
                    FileInfo.showDirRecursive(args[1]);
                    break;

                case "file":
                    require(args, 3, "file <hdfs> <create|delete>");
                    System.out.println("【题目6】HDFS 文件创建/删除（父目录不存在则自动创建）");
                    CreateDeleteFile.run(args[1], args[2]);
                    break;

                case "dir":
                    require(args, 3, "dir <hdfsdir> <create|delete>");
                    System.out.println("【题目7】HDFS 目录创建/删除（目录非空时不删除）");
                    CreateDeleteDir.run(args[1], args[2]);
                    break;

                case "append":
                    require(args, 4, "append <hdfs> <content> <head|tail>");
                    System.out.println("【题目8】向 HDFS 文件追加内容（用户指定追加到开头或结尾）");
                    AppendContent.run(args[1], args[2], args[3]);
                    break;

                case "rm":
                    require(args, 2, "rm <hdfs>");
                    System.out.println("【题目9】删除 HDFS 中指定的文件");
                    DeleteFile.run(args[1]);
                    break;

                case "mv":
                    require(args, 3, "mv <src> <dst>");
                    System.out.println("【题目10】把 HDFS 文件从源路径移动到目的路径");
                    MoveFile.run(args[1], args[2]);
                    break;

                default:
                    usage();
                    System.exit(1);
            }
        } catch (Exception e) {
            System.err.println("执行失败：" + e.getMessage());
            System.exit(2);
        }
    }

    private static void require(String[] args, int n, String usageStr) {
        if (args.length < n) {
            System.err.println("参数不足。用法: HdfsLab " + usageStr);
            System.exit(1);
        }
    }

    private static void usage() {
        System.out.println("实验一 第 2 部分：HDFS 常用操作 Java API 实现");
        System.out.println("用法: HdfsLab <子命令> [参数...]");
        System.out.println("  upload   <local>  <hdfs> [append|overwrite]   题目1 上传文件");
        System.out.println("  download <hdfs>   <localdir>                  题目2 下载文件");
        System.out.println("  cat      <hdfs>                               题目3 输出文件内容");
        System.out.println("  info     <hdfs>                               题目4 文件属性");
        System.out.println("  info-r   <hdfsdir>                            题目5 目录递归属性");
        System.out.println("  file     <hdfs>   <create|delete>             题目6 文件创建/删除");
        System.out.println("  dir      <hdfsdir> <create|delete>            题目7 目录创建/删除");
        System.out.println("  append   <hdfs>   <content> <head|tail>       题目8 追加内容");
        System.out.println("  rm       <hdfs>                               题目9 删除文件");
        System.out.println("  mv       <src>    <dst>                       题目10 移动文件");
    }

    private HdfsLab() {
    }
}
