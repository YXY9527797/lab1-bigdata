package edu.sdu.bigdata.mr;

/**
 * 实验一 第 3 部分统一入口：按子命令提交对应的 MapReduce 作业。
 *
 * <pre>
 * 用法: MrLab &lt;子命令&gt; &lt;输入目录&gt; &lt;输出目录&gt;
 *   dedup       题目1 文件合并与去重
 *   sort        题目2 整数排序并输出位次
 *   grandparent 题目3 child-parent 表挖掘祖孙关系
 *   all         依次运行以上三个作业（输出目录分别为 &lt;输出根&gt;/dedup 等）
 * </pre>
 */
public final class MrLab {

    public static void main(String[] args) throws Exception {
        if (args.length < 3) {
            usage();
            System.exit(1);
        }
        String cmd = args[0].toLowerCase();
        String input = args[1];
        String output = args[2];

        boolean ok;
        switch (cmd) {
            case "dedup":
                System.out.println("######## 题目1：文件的合并和去重 ########");
                ok = MergeDedup.run(input, output);
                break;
            case "sort":
                System.out.println("######## 题目2：对输入文件进行排序 ########");
                ok = SortAndRank.run(input, output);
                break;
            case "grandparent":
                System.out.println("######## 题目3：child-parent 表的信息挖掘 ########");
                ok = GrandParent.run(input, output);
                break;
            default:
                usage();
                ok = false;
                System.exit(1);
                return;
        }
        System.out.println(ok ? "作业执行成功：" + output : "作业执行失败");
        System.exit(ok ? 0 : 1);
    }

    private static void usage() {
        System.out.println("实验一 第 3 部分：MapReduce 初级编程");
        System.out.println("用法: MrLab <子命令> <输入目录> <输出目录>");
        System.out.println("  dedup        题目1 文件合并与去重");
        System.out.println("  sort         题目2 整数排序并输出位次");
        System.out.println("  grandparent  题目3 child-parent 表挖掘祖孙关系");
    }

    private MrLab() {
    }
}
