package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

/**
 * 题目 10：在 HDFS 中，将文件从源路径移动到目的路径。
 * 对应 Shell 命令：{@code hdfs dfs -mv <src> <dst>}。
 *
 * <p>HDFS 的 rename 是“原子重命名”，同一文件系统内就是移动；
 * 若目的路径的父目录不存在，这里会自动创建，保证移动成功。</p>
 */
public final class MoveFile {

    private MoveFile() {
    }

    public static void run(String srcPath, String dstPath) throws IOException {
        Path src = HdfsUtil.checkPath(srcPath);
        Path dst = HdfsUtil.checkPath(dstPath);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(src)) {
                throw new IOException("源路径不存在：" + srcPath);
            }
            System.out.println("移动前源文件状态：" + HdfsUtil.formatStatus(fs.getFileStatus(src)));

            Path parent = dst.getParent();
            if (parent != null && !fs.exists(parent)) {
                HdfsUtil.echo("hdfs dfs -mkdir -p %s   # 目的目录不存在，自动创建", parent);
                fs.mkdirs(parent);
                System.out.println("已自动创建目的目录：" + parent);
            }

            HdfsUtil.echo("hdfs dfs -mv %s %s", src, dst);
            boolean ok = fs.rename(src, dst);
            if (!ok) {
                throw new IOException("移动失败：" + src + " -> " + dst);
            }
            System.out.println("移动完成：" + src + "  ->  " + dst);
            System.out.println("源路径是否还存在：" + fs.exists(src));
            System.out.println("目的文件状态：" + HdfsUtil.formatStatus(fs.getFileStatus(dst)));
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }
}
