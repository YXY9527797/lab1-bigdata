package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;

import java.io.File;
import java.io.IOException;

/**
 * 题目 2：从 HDFS 中下载指定文件；如果本地已存在同名文件，
 * 则自动对下载的文件重命名（file.txt -> file.txt.1 -> file.txt.2 ...）。
 */
public final class DownloadFile {

    private DownloadFile() {
    }

    public static String run(String hdfsSrc, String localDir) throws IOException {
        Path src = HdfsUtil.checkPath(hdfsSrc);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(src)) {
                throw new IOException("HDFS 上不存在该文件：" + hdfsSrc);
            }
            if (fs.getFileStatus(src).isDirectory()) {
                throw new IOException("该路径是目录，请指定具体文件：" + hdfsSrc);
            }

            File dir = new File(localDir);
            if (!dir.exists() && !dir.mkdirs()) {
                throw new IOException("无法创建本地目录：" + localDir);
            }

            // ---- 关键点：本地同名文件的重命名策略 ----
            File target = new File(dir, src.getName());
            String renamedFrom = null;
            if (target.exists()) {
                renamedFrom = target.getName();
                int i = 1;
                File candidate;
                do {
                    candidate = new File(dir, src.getName() + "." + i);
                    i++;
                } while (candidate.exists());
                target = candidate;
                System.out.println("本地已存在同名文件 " + renamedFrom
                        + "，自动重命名为：" + target.getName());
            }

            HdfsUtil.echo("hdfs dfs -get %s %s", src, target.getAbsolutePath());
            // copyToLocalFile(delSrc=false, src, dst)
            fs.copyToLocalFile(false, src, new Path(target.getAbsolutePath()));

            System.out.println("已下载到本地：" + target.getAbsolutePath()
                    + "（" + target.length() + " 字节）");
            return target.getAbsolutePath();
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }
}
