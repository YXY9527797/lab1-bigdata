package edu.sdu.bigdata.mr;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;

/**
 * 实验一 第 3 部分 · 题目 2：编程实现对输入文件的排序。
 *
 * <p>输入：多个文件，每行一个整数（也兼容一行多个整数）；<br>
 * 输出：升序排序后，每行两个整数 —— 第一个是排序位次，第二个是原始整数。</p>
 *
 * <p><b>思路：</b>Map 阶段把整数作为 <b>key</b> 输出，框架在进入 Reduce 之前
 * 会对 key 自动排序，所以 Reducer 收到的 key 已经是升序的。再把 Reduce 任务数设为
 * 1，用一个计数器递增即可得到<b>全局连续</b>的位次。同一个整数出现多次时，values
 * 迭代器会给出多个元素，每个都占一个位次，因此位次不会跳号。</p>
 */
public class SortAndRank {

    /** Mapper：把每行的每个整数抽出来，以 IntWritable 作为 key（框架据此排序）。 */
    public static class SortMapper extends Mapper<Object, Text, IntWritable, NullWritable> {

        private final IntWritable outKey = new IntWritable();

        @Override
        protected void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            String[] tokens = value.toString().trim().split("\\s+");
            for (String token : tokens) {
                if (token.isEmpty()) {
                    continue;
                }
                try {
                    outKey.set(Integer.parseInt(token));
                    context.write(outKey, NullWritable.get());
                } catch (NumberFormatException e) {
                    // 忽略非整数内容，保证作业健壮
                    System.err.println("跳过非整数内容: " + token);
                }
            }
        }
    }

    /**
     * Reducer：key 已按升序到达。rank 从 0 开始递增，
     * 对同一个 key 的每个 value 都输出一行 “位次 + 整数”。
     */
    public static class RankReducer extends Reducer<IntWritable, NullWritable, IntWritable, IntWritable> {

        private int rank = 0;                  // 全局位次计数器（单 Reduce 任务内有效）

        @Override
        protected void reduce(IntWritable key, Iterable<NullWritable> values, Context context)
                throws IOException, InterruptedException {
            for (NullWritable ignored : values) {
                rank++;
                context.write(new IntWritable(rank), key);
            }
        }
    }

    public static boolean run(String input, String output) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "lab1-2-sort-and-rank");

        job.setJarByClass(SortAndRank.class);
        job.setMapperClass(SortMapper.class);
        job.setReducerClass(RankReducer.class);

        job.setMapOutputKeyClass(IntWritable.class);
        job.setMapOutputValueClass(NullWritable.class);
        job.setOutputKeyClass(IntWritable.class);
        job.setOutputValueClass(IntWritable.class);

        // 关键：必须是 1 个 Reduce 任务，位次才是全局连续升序的
        job.setNumReduceTasks(1);

        FileInputFormat.addInputPath(job, new Path(input));
        FileOutputFormat.setOutputPath(job, new Path(output));

        return job.waitForCompletion(true);
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("用法: SortAndRank <输入目录> <输出目录>");
            System.exit(1);
        }
        System.exit(run(args[0], args[1]) ? 0 : 1);
    }
}
