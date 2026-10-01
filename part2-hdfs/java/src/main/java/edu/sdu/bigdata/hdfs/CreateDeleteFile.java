package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

/**
 * 题目 6：提供一个 HDFS 内的文件路径，对该文件进行创建和删除操作；
 * 如果文件所在目录不存在，则自动创建目录。
 */
public final class CreateDeleteFile {

    private CreateDeleteFile() {
    }

    /** @param action {@code create} 或 {@code delete} */
    public static void run(String hdfsFile, String action) throws IOException {
        Path path = HdfsUtil.checkPath(hdfsFile);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if ("delete".equalsIgnoreCase(action)) {
                delete(fs, path);
            } else {
                create(fs, path);
            }
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }

    /** 创建文件；父目录不存在时用 mkdirs() 自动补全，再 create() 建空文件。 */
    public static void create(FileSystem fs, Path path) throws IOException {
        Path parent = path.getParent();
        if (parent != null && !fs.exists(parent)) {
            HdfsUtil.echo("hdfs dfs -mkdir -p %s   # 文件所在目录不存在，自动创建", parent);
            fs.mkdirs(parent);
            System.out.println("已自动创建父目录：" + parent);
        }
        HdfsUtil.echo("hdfs dfs -touchz %s   # 等价于 FileSystem.create(path)", path);
        // create(path, overwrite=true) 会新建一个空文件；关闭流即完成创建
        fs.create(path, true).close();
        System.out.println("已创建文件：" + path);
        System.out.println("文件状态：" + HdfsUtil.formatStatus(fs.getFileStatus(path)));
    }

    private static void delete(FileSystem fs, Path path) throws IOException {
        if (!fs.exists(path)) {
            System.out.println("文件不存在，无需删除：" + path);
            return;
        }
        HdfsUtil.echo("hdfs dfs -rm %s", path);
        boolean ok = fs.delete(path, false);
        System.out.println((ok ? "已删除文件：" : "删除失败：") + path);
    }
}
