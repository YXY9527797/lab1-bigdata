package edu.sdu.bigdata.mr;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * 实验一 第 3 部分 · 题目 3：对指定的表格进行信息挖掘（由 child-parent 表求祖孙关系）。
 *
 * <p>输入：每行 {@code child<TAB>parent}；<br>
 * 输出：每行 {@code grandchild<TAB>grandparent}。</p>
 *
 * <p><b>思路（一趟 MapReduce 完成自连接）：</b>对输入的每一行 (child, parent) 输出
 * 两条记录，用前缀区分“方向”：</p>
 * <ul>
 *   <li>{@code key=parent, value="1"+child} —— 表示 parent 的下一辈是 child；</li>
 *   <li>{@code key=child,  value="2"+parent} —— 表示 child 的上一辈是 parent。</li>
 * </ul>
 * <p>于是对于任意中间人 X，Reducer 收到的 values 里既有 “1+子辈” 又有 “2+父辈”，
 * 把这两组做笛卡尔积就得到 (孙辈, 祖辈) 关系，即所求结果。</p>
 */
public class GrandParent {

    /** 值前缀：表示这条记录描述的是“key 的子辈”。 */
    private static final String CHILD_FLAG = "1";
    /** 值前缀：表示这条记录描述的是“key 的父辈”。 */
    private static final String PARENT_FLAG = "2";

    public static class GPMapper extends Mapper<Object, Text, Text, Text> {

        private final Text outKey = new Text();
        private final Text outValue = new Text();

        @Override
        protected void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty()) {
                return;
            }
            String[] tokens = line.split("\\s+");
            if (tokens.length < 2) {
                System.err.println("格式不正确，应为 child<TAB>parent: " + line);
                return;
            }
            String child = tokens[0];
            String parent = tokens[1];

            // 记录 1：以 parent 为 key，说明 parent 有个孩子叫 child
            outKey.set(parent);
            outValue.set(CHILD_FLAG + child);
            context.write(outKey, outValue);

            // 记录 2：以 child 为 key，说明 child 有个父亲/母亲叫 parent
            outKey.set(child);
            outValue.set(PARENT_FLAG + parent);
            context.write(outKey, outValue);
        }
    }

    /** Reducer：对中间人 key，把“子辈集合”与“父辈集合”做笛卡尔积。 */
    public static class GPReducer extends Reducer<Text, Text, Text, Text> {

        @Override
        protected void reduce(Text key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            List<String> children = new ArrayList<>();   // key 的下一辈
            List<String> parents = new ArrayList<>();    // key 的上一辈

            for (Text v : values) {
                String s = v.toString();
                if (s.startsWith(CHILD_FLAG)) {
                    children.add(s.substring(CHILD_FLAG.length()));
                } else if (s.startsWith(PARENT_FLAG)) {
                    parents.add(s.substring(PARENT_FLAG.length()));
                }
            }

            // 孙辈(children) 与 祖辈(parents) 组合：child 的父母是 key，key 的父母是 parents
            for (String grandchild : children) {
                for (String grandparent : parents) {
                    context.write(new Text(grandchild), new Text(grandparent));
                }
            }
        }
    }

    public static boolean run(String input, String output) throws Exception {
        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "lab1-3-grandparent-mining");

        job.setJarByClass(GrandParent.class);
        job.setMapperClass(GPMapper.class);
        job.setReducerClass(GPReducer.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(Text.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        job.setNumReduceTasks(1);

        FileInputFormat.addInputPath(job, new Path(input));
        FileOutputFormat.setOutputPath(job, new Path(output));

        return job.waitForCompletion(true);
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("用法: GrandParent <输入目录> <输出目录>");
            System.exit(1);
        }
        System.exit(run(args[0], args[1]) ? 0 : 1);
    }
}
