package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;

/**
 * 题目 4 与题目 5：
 * <ul>
 *   <li>题目 4：显示 HDFS 中指定文件的读写权限、大小、创建时间、路径等信息；</li>
 *   <li>题目 5：给定 HDFS 中某一个目录，递归输出该目录下所有文件的上述信息。</li>
 * </ul>
 * 对应 Shell 命令：{@code hdfs dfs -ls <file>} 与 {@code hdfs dfs -ls -R <dir>}。
 */
public final class FileInfo {

    private FileInfo() {
    }

    /** 题目 4：输出单个文件（或目录）的详细信息。 */
    public static void showFile(String hdfsPath) throws IOException {
        Path path = HdfsUtil.checkPath(hdfsPath);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(path)) {
                throw new IOException("HDFS 上不存在该路径：" + hdfsPath);
            }
            HdfsUtil.echo("hdfs dfs -ls %s", path);
            HdfsUtil.printHeader("【题目4】文件详细信息");
            System.out.println(HdfsUtil.formatStatus(fs.getFileStatus(path)));
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }

    /** 题目 5：递归输出目录下所有文件的信息。 */
    public static int showDirRecursive(String hdfsDir) throws IOException {
        Path dir = HdfsUtil.checkPath(hdfsDir);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(dir)) {
                throw new IOException("HDFS 上不存在该目录：" + hdfsDir);
            }
            if (!fs.getFileStatus(dir).isDirectory()) {
                throw new IOException("该路径不是目录：" + hdfsDir);
            }
            HdfsUtil.echo("hdfs dfs -ls -R %s", dir);
            HdfsUtil.printHeader("【题目5】目录 " + dir + " 下所有文件的详细信息（递归）");

            // Hadoop 没有“一次递归列出全部”的 listStatus 重载，
            // 标准做法是：对自己 listStatus()，遇到子目录再递归下去。
            List<FileStatus> all = new ArrayList<>();
            collect(fs, dir, all);

            int fileCount = 0;
            for (FileStatus st : all) {
                System.out.println(HdfsUtil.formatStatus(st));
                if (st.isFile()) {
                    fileCount++;
                }
            }
            System.out.println("--------------------------------------------------------------------------");
            System.out.println("共 " + all.size() + " 个条目，其中文件 " + fileCount + " 个。");
            return fileCount;
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }

    /** 深度优先递归收集目录下的所有条目（先目录后其子项，与 ls -R 顺序一致）。 */
    private static void collect(FileSystem fs, Path dir, List<FileStatus> out) throws IOException {
        FileStatus[] children = fs.listStatus(dir);
        // 排序，保证每次运行输出顺序一致，便于实验报告复现
        Arrays.sort(children, new Comparator<FileStatus>() {
            @Override
            public int compare(FileStatus a, FileStatus b) {
                return a.getPath().toString().compareTo(b.getPath().toString());
            }
        });
        for (FileStatus st : children) {
            out.add(st);
            if (st.isDirectory()) {
                collect(fs, st.getPath(), out);
            }
        }
    }
}
