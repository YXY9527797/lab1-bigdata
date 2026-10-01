package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;
import java.net.URI;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * HDFS 实验公共工具类。
 *
 * <p>把“连接 HDFS”“格式化文件状态输出”等所有小题目都要用到的逻辑集中在这里，
 * 避免每个任务类里重复写样板代码。</p>
 */
public final class HdfsUtil {

    /** 默认 NameNode 地址，与 env/templates/core-site.xml 中的 fs.defaultFS 一致。 */
    public static final String DEFAULT_URI = "hdfs://localhost:9000";

    private HdfsUtil() {
    }

    /**
     * 取得 HDFS 客户端对象。
     *
     * <p>NameNode 地址优先取环境变量 {@code HDFS_URI}，否则用 {@link #DEFAULT_URI}；
     * 提交作业的操作系统用户优先取环境变量 {@code HADOOP_USER_NAME}（在“可写根视图”
     * 里运行时 whoami 是 root，必须显式指定为 HDFS 超级用户，否则会被 HDFS 拒绝）。</p>
     */
    public static FileSystem getFileSystem() throws IOException {
        Configuration conf = new Configuration();
        String uri = System.getenv("HDFS_URI");
        if (uri == null || uri.trim().isEmpty()) {
            uri = DEFAULT_URI;
        }
        String user = System.getenv("HADOOP_USER_NAME");
        if (user == null || user.trim().isEmpty()) {
            return FileSystem.get(URI.create(uri), conf);
        }
        try {
            return FileSystem.get(URI.create(uri), conf, user);
        } catch (InterruptedException e) {
            // 恢复中断标志，并转换为 IOException，避免调用方被迫处理中断异常
            Thread.currentThread().interrupt();
            throw new IOException("获取 HDFS 客户端时被中断", e);
        }
    }

    /** 打印一条待执行的命令，便于实验日志与实验报告对照。 */
    public static void echo(String fmt, Object... args) {
        System.out.println("$ " + String.format(fmt, args));
    }

    /** 把文件状态格式化为“权限 / 属主 / 大小 / 创建(修改)时间 / 路径”一行。 */
    public static String formatStatus(FileStatus st) {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return String.format("%-10s %-10s %10d  %s  %s",
                st.getPermission().toString(),
                st.getOwner(),
                st.getLen(),
                sdf.format(new Date(st.getModificationTime())),
                st.getPath().toString());
    }

    /** 打印表头，与 {@link #formatStatus(FileStatus)} 的输出列对齐。 */
    public static void printHeader(String title) {
        System.out.println(title);
        System.out.println(String.format("%-10s %-10s %10s  %-19s  %s",
                "权限", "属主", "大小(字节)", "创建/修改时间", "路径"));
        System.out.println("--------------------------------------------------------------------------");
    }

    /** 判断某个路径是否位于 HDFS 上，并给出统一的错误信息。 */
    public static Path checkPath(String path) {
        if (path == null || path.trim().isEmpty()) {
            throw new IllegalArgumentException("路径不能为空");
        }
        return new Path(path.trim());
    }

    /** 关闭文件系统，忽略关闭异常。 */
    public static void closeQuietly(FileSystem fs) {
        if (fs != null) {
            try {
                fs.close();
            } catch (IOException ignored) {
                // 关闭失败不影响实验结果
            }
        }
    }
}
