package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * 题目 8：向 HDFS 中指定的文件追加内容，由用户指定内容追加到原有文件的开头或结尾。
 *
 * <p><b>实现要点：</b>HDFS 的 {@code append()} 只能把数据写到文件<b>末尾</b>。要追加到
 * <b>开头</b>，必须“读出原内容 -> 删除原文件 -> 重新创建并先写新内容再写原内容”
 * （即整体重写），本类对两种情况分别处理。</p>
 */
public final class AppendContent {

    private AppendContent() {
    }

    /**
     * @param hdfsFile 目标文件
     * @param content  要追加的文本内容
     * @param position {@code head} 追加到开头 / {@code tail} 追加到结尾
     */
    public static void run(String hdfsFile, String content, String position) throws IOException {
        Path path = HdfsUtil.checkPath(hdfsFile);
        boolean toHead = "head".equalsIgnoreCase(position);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(path)) {
                throw new IOException("HDFS 上不存在该文件：" + hdfsFile);
            }

            String before = readAll(fs, path);
            System.out.println("追加前内容（" + before.length() + " 字符）：");
            System.out.println("--------------------------------------------------");
            System.out.print(before.endsWith("\n") ? before : before + "\n");
            System.out.println("--------------------------------------------------");

            String after;
            if (toHead) {
                // ---- 追加到开头：HDFS 无此 API，采用“读-删-重建”整体重写 ----
                System.out.println("追加位置：文件开头（HDFS 的 append 只能追加到末尾，");
                System.out.println("          因此这里读出原内容后删除文件，再按“新内容+原内容”重建）");
                after = content + (content.endsWith("\n") ? "" : "\n") + before;

                HdfsUtil.echo("hdfs dfs -rm %s        # 先删除", path);
                fs.delete(path, false);
                HdfsUtil.echo("hdfs dfs -put -   # 新建文件并写入：新内容 + 原内容");
                try (FSDataOutputStream out = fs.create(path, true)) {
                    out.write(after.getBytes(StandardCharsets.UTF_8));
                }
            } else {
                // ---- 追加到末尾：直接使用 HDFS 的 append API ----
                System.out.println("追加位置：文件末尾（使用 FileSystem.append()）");
                HdfsUtil.echo("FileSystem.append(new Path(\"%s\"))", path);
                after = before + (before.endsWith("\n") || before.isEmpty() ? "" : "\n") + content
                        + (content.endsWith("\n") ? "" : "\n");
                try (FSDataOutputStream out = fs.append(path)) {
                    String added = (before.endsWith("\n") || before.isEmpty() ? "" : "\n")
                            + content + (content.endsWith("\n") ? "" : "\n");
                    out.write(added.getBytes(StandardCharsets.UTF_8));
                }
            }

            System.out.println("追加后内容（" + readAll(fs, path).length() + " 字符）：");
            System.out.println("--------------------------------------------------");
            System.out.print(readAll(fs, path));
            System.out.println("--------------------------------------------------");
            System.out.println("追加后文件状态：" + HdfsUtil.formatStatus(fs.getFileStatus(path)));
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }

    /** 一次读出 HDFS 文件全部内容（实验用小文件，直接读入内存即可）。 */
    public static String readAll(FileSystem fs, Path path) throws IOException {
        try (FSDataInputStream in = fs.open(path);
             ByteArrayOutputStream bos = new ByteArrayOutputStream()) {
            IOUtils.copyBytes(in, bos, 4096, false);
            return new String(bos.toByteArray(), StandardCharsets.UTF_8);
        }
    }
}
