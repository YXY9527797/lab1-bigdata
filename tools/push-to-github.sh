#!/usr/bin/env bash
# =============================================================================
# tools/push-to-github.sh —— 在 GitHub 上创建公开仓库并推送本仓库
#
# 为什么需要 token：GitHub 不允许匿名创建仓库或推送代码，必须携带具备 repo 权限
# 的 Personal Access Token（PAT）。本脚本把 token 只用于「本次 curl 与本次 git push」，
# 推送完成后会把 origin 重置为不带 token 的干净地址，不会把 token 写进 .git/config。
#
# 用法：
#   GITHUB_TOKEN=ghp_xxxxxxxx ./tools/push-to-github.sh [仓库名]
#
#   # 也可用细粒度令牌（fine-grained）：
#   #   Repository access: All repositories
#   #   Permissions: Contents = Read and write, Administration = Read and write
#
# 完成后：
#   * 仓库地址形如 https://github.com/<你的用户名>/<仓库名>
#   * 记得把该地址填进 report/report.html 并重新生成报告：
#         ./report/build-report.sh
# =============================================================================
set -euo pipefail

: "${GITHUB_TOKEN:?请通过环境变量提供 token，例如：GITHUB_TOKEN=ghp_xxx $0}"

REPO="${1:-lab1-bigdata}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

API="https://api.github.com"
AUTH="Authorization: Bearer $GITHUB_TOKEN"

echo "[1/5] 校验 token 并获取用户名 ..."
USER_JSON="$(curl -sS -H "$AUTH" -H "Accept: application/vnd.github+json" "$API/user")"
LOGIN="$(printf '%s' "$USER_JSON" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("login",""))')"
if [ -z "$LOGIN" ]; then
  echo "错误：无法获取 GitHub 用户信息，token 可能无效或权限不足。返回内容：" >&2
  printf '%s\n' "$USER_JSON" >&2
  exit 1
fi
echo "      已认证用户：$LOGIN"

echo "[2/5] 检查仓库 $LOGIN/$REPO 是否已存在 ..."
CODE="$(curl -sS -o /dev/null -w '%{http_code}' -H "$AUTH" "$API/repos/$LOGIN/$REPO")"
if [ "$CODE" = "200" ]; then
  echo "      仓库已存在，跳过创建。"
elif [ "$CODE" = "404" ]; then
  echo "      创建公开仓库 $REPO ..."
  curl -sS -X POST -H "$AUTH" -H "Accept: application/vnd.github+json" \
       "$API/user/repos" \
       -d "{\"name\":\"$REPO\",\"private\":false,\"has_issues\":true,\"has_wiki\":false,
            \"description\":\"大数据管理与分析 实验一：Linux/Hadoop 基本操作、HDFS 常用操作（Shell+Java API）、MapReduce 初级编程\"}" \
       >/dev/null
  echo "      创建完成。"
else
  echo "错误：查询仓库返回 HTTP $CODE，请检查 token 权限（需要 repo / Administration:Read and write）。" >&2
  exit 1
fi

echo "[3/5] 提交本地改动（如有）..."
git add -A
if ! git diff --cached --quiet; then
  git commit -q -m "更新实验一代码与报告"
fi
BRANCH="$(git branch --show-current)"

echo "[4/5] 推送分支 $BRANCH ..."
# token 只出现在这一条命令的 URL 中，不会写进 .git/config
git push "https://${LOGIN}:${GITHUB_TOKEN}@github.com/${LOGIN}/${REPO}.git" "$BRANCH:$BRANCH"

echo "[5/5] 把 origin 设为不带 token 的干净地址 ..."
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${LOGIN}/${REPO}.git"
git branch --set-upstream-to="origin/$BRANCH" "$BRANCH" 2>/dev/null || true

echo
echo "完成。公开仓库地址："
echo "    https://github.com/${LOGIN}/${REPO}"
echo
echo "提醒：请把上面的地址填进 report/report.html（搜索“用户名”），再执行"
echo "      ./report/build-report.sh"
echo "      重新生成报告 PDF，然后就可以把 GitHub 上的分支设置为默认分支（若需要）。"
