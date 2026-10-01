package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;

/**
 * 题目 7：提供一个 HDFS 的目录路径，对该目录进行创建和删除操作。
 * <ul>
 *   <li>创建目录时，如果所在目录不存在，则自动创建相应目录（mkdirs）；</li>
 *   <li>删除目录时，<b>当该目录为空时删除，当该目录不为空时不删除</b>。</li>
 * </ul>
 */
public final class CreateDeleteDir {

    private CreateDeleteDir() {
    }

    /** @param action {@code create} 或 {@code delete} */
    public static void run(String hdfsDir, String action) throws IOException {
        Path path = HdfsUtil.checkPath(hdfsDir);
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

    /** 创建目录：mkdirs() 会递归创建所有缺失的父目录。 */
    public static void create(FileSystem fs, Path path) throws IOException {
        if (fs.exists(path)) {
            System.out.println("目录已存在：" + path);
            return;
        }
        HdfsUtil.echo("hdfs dfs -mkdir -p %s", path);
        boolean ok = fs.mkdirs(path);
        System.out.println((ok ? "已创建目录：" : "创建失败：") + path);
        System.out.println("目录状态：" + HdfsUtil.formatStatus(fs.getFileStatus(path)));
    }

    /**
     * 删除目录：先用 listStatus() 判断目录是否为空。
     * 为空 -> delete(path, false)；非空 -> 拒绝删除并给出提示。
     */
    public static void delete(FileSystem fs, Path path) throws IOException {
        if (!fs.exists(path)) {
            System.out.println("目录不存在，无需删除：" + path);
            return;
        }
        if (!fs.getFileStatus(path).isDirectory()) {
            System.out.println("该路径不是目录，本操作只处理目录：" + path);
            return;
        }

        FileStatus[] children = fs.listStatus(path);
        if (children.length > 0) {
            // 题目要求：目录非空时不删除
            System.out.println("目录 " + path + " 非空（含 " + children.length + " 个子项），按要求【不删除】：");
            for (FileStatus st : children) {
                System.out.println("    " + HdfsUtil.formatStatus(st));
            }
            return;
        }

        HdfsUtil.echo("hdfs dfs -rmdir %s   # 目录为空，可以删除", path);
        boolean ok = fs.delete(path, false);
        System.out.println((ok ? "已删除空目录：" : "删除失败：") + path);
    }
}
