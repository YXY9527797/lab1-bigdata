package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Scanner;

/**
 * 题目 1：向 HDFS 上传任意文本文件；如果指定的文件在 HDFS 中已经存在，
 * 则由用户指定“追加到原文件末尾”还是“覆盖原文件”。
 */
public final class UploadFile {

    private UploadFile() {
    }

    /**
     * @param localSrc  本地源文件
     * @param hdfsDst   HDFS 目标路径
     * @param mode      已由用户指定的模式：{@code append} / {@code overwrite}；为 null 时交互式询问
     * @return 处理结果描述
     */
    public static String run(String localSrc, String hdfsDst, String mode) throws IOException {
        Path src = new Path(localSrc);
        Path dst = HdfsUtil.checkPath(hdfsDst);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!Files.exists(java.nio.file.Paths.get(localSrc))) {
                throw new IOException("本地文件不存在：" + localSrc);
            }

            boolean exists = fs.exists(dst);
            HdfsUtil.echo("hdfs dfs -ls %s   # 判断目标文件是否已存在", dst);
            System.out.println("目标文件 " + dst + " 在 HDFS 中" + (exists ? "已存在" : "不存在"));

            String action;
            if (!exists) {
                action = "overwrite";
            } else if (mode != null && !mode.trim().isEmpty()) {
                action = mode.trim().toLowerCase();
            } else {
                action = askUser(dst.toString());
            }

            if ("append".equals(action)) {
                // ---- 追加到原有文件末尾：用 FileSystem.append() 拿到一个可写流 ----
                HdfsUtil.echo("FileSystem.append(new Path(\"%s\"))   # 以追加方式打开", dst);
                try (OutputStream out = fs.append(dst)) {
                    byte[] data = Files.readAllBytes(java.nio.file.Paths.get(localSrc));
                    out.write(data);
                }
                System.out.println("已把 " + localSrc + " 的内容【追加】到 " + dst + " 末尾");
            } else {
                // ---- 覆盖原文件：copyFromLocalFile(delSrc=false, overwrite=true, ...) ----
                HdfsUtil.echo("hdfs dfs -put -f %s %s", localSrc, dst);
                fs.copyFromLocalFile(false, true, src, dst);
                System.out.println("已把 " + localSrc + " 【覆盖】上传到 " + dst);
            }

            System.out.println("上传后文件状态：" + HdfsUtil.formatStatus(fs.getFileStatus(dst)));
            return action;
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }

    /** 交互式询问用户：追加还是覆盖。 */
    private static String askUser(String hdfsPath) {
        System.out.println("目标文件 " + hdfsPath + " 已存在，请选择处理方式：");
        System.out.println("  [1] 追加到原有文件末尾 (append)");
        System.out.println("  [2] 覆盖原有的文件       (overwrite)");
        System.out.print("请输入 1 或 2：");
        System.out.flush();
        try (Scanner in = new Scanner(new BufferedReader(new InputStreamReader(System.in, StandardCharsets.UTF_8)))) {
            if (in.hasNextLine()) {
                String line = in.nextLine().trim();
                if ("1".equals(line) || "append".equalsIgnoreCase(line)) {
                    return "append";
                }
                if ("2".equals(line) || "overwrite".equalsIgnoreCase(line)) {
                    return "overwrite";
                }
            }
        }
        System.out.println("输入无法识别，默认按【覆盖】处理。");
        return "overwrite";
    }
}
