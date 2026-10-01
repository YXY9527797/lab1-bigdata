package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

/**
 * 题目 9：删除 HDFS 中指定的文件。
 * 对应 Shell 命令：{@code hdfs dfs -rm <file>}。
 */
public final class DeleteFile {

    private DeleteFile() {
    }

    public static void run(String hdfsFile) throws IOException {
        Path path = HdfsUtil.checkPath(hdfsFile);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(path)) {
                System.out.println("文件不存在，无需删除：" + path);
                return;
            }
            System.out.println("删除前文件状态：" + HdfsUtil.formatStatus(fs.getFileStatus(path)));
            HdfsUtil.echo("hdfs dfs -rm %s", path);
            // 第二个参数 recursive=false：只删文件，不递归删目录
            boolean ok = fs.delete(path, false);
            System.out.println((ok ? "已删除文件：" : "删除失败：") + path);
            System.out.println("删除后该路径是否存在：" + fs.exists(path));
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }
}
