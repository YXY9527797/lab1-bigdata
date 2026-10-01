package edu.sdu.bigdata.mr;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;

/**
 * 实验一 第 3 部分 · 题目 1：编程实现文件的合并和去重。
 *
 * <p>输入：同一目录下的文件 A 与文件 B，每行形如 {@code 20170101<TAB>x}；<br>
 * 输出：合并两个文件并剔除重复后的新文件 C。</p>
 *
 * <p><b>思路：</b>把“整行内容”作为 Map 输出的 key。MapReduce 框架会把相同 key
 * 归并到同一次 reduce 调用，因此 Reducer 里对每个 key 只输出一次，重复行自然被
 * 剔除；同时框架会对 key 排序，输出即按日期有序。</p>
 */
public class MergeDedup {

    /** Mapper：读入每一行，以整行内容为 key 输出；value 用 NullWritable 表示“只需 key”。 */
    public static class DedupMapper extends Mapper<Object, Text, Text, NullWritable> {

        private final Text outKey = new Text();

        @Override
        protected void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty()) {
                return;                       // 跳过空行
            }
            outKey.set(line);
            context.write(outKey, NullWritable.get());
        }
    }

    /**
     * Reducer：相同内容的行会被归到同一个 key 上，这里只输出一次，实现去重。
     * （不需要关心 values 有几个，它们都是 NullWritable。）
     */
    public static class DedupReducer extends Reducer<Text, NullWritable, Text, NullWritable> {

        @Override
        protected void reduce(Text key, Iterable<NullWritable> values, Context context)
                throws IOException, InterruptedException {
            context.write(key, NullWritable.get());
        }
    }

    /** 组装并提交作业；args = &lt;输入目录&gt; &lt;输出目录&gt;。 */
    public static boolean run(String input, String output) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "lab1-1-merge-and-dedup");

        job.setJarByClass(MergeDedup.class);
        job.setMapperClass(DedupMapper.class);
        job.setReducerClass(DedupReducer.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(NullWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(NullWritable.class);

        // 用 1 个 Reduce 任务：输出单个结果文件，便于与样例 C 对照
        job.setNumReduceTasks(1);

        FileInputFormat.addInputPath(job, new Path(input));
        FileOutputFormat.setOutputPath(job, new Path(output));

        return job.waitForCompletion(true);
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("用法: MergeDedup <输入目录> <输出目录>");
            System.exit(1);
        }
        System.exit(run(args[0], args[1]) ? 0 : 1);
    }
}
