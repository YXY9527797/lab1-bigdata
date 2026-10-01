package edu.sdu.bigdata.hdfs;

import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IOUtils;

import java.io.IOException;

/**
 * 题目 3：把 HDFS 中指定文件的内容输出到终端。
 */
public final class CatFile {

    private CatFile() {
    }

    public static void run(String hdfsFile) throws IOException {
        Path path = HdfsUtil.checkPath(hdfsFile);
        FileSystem fs = HdfsUtil.getFileSystem();
        try {
            if (!fs.exists(path)) {
                throw new IOException("HDFS 上不存在该文件：" + hdfsFile);
            }
            HdfsUtil.echo("hdfs dfs -cat %s", path);
            // open() 返回输入流；IOUtils.copyBytes 把流拷贝到标准输出
            try (FSDataInputStream in = fs.open(path)) {
                IOUtils.copyBytes(in, System.out, 4096, false);
            }
            System.out.println();
        } finally {
            HdfsUtil.closeQuietly(fs);
        }
    }
}
