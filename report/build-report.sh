#!/usr/bin/env bash
# =============================================================================
# report/build-report.sh —— 由 report.html 生成实验报告 PDF 与 DOCX
#
#   排版要求（见实验说明）：宋体、小四号（12pt）、1.25 倍行距、A4、不超过 8 页，
#   文件名为“学号-姓名-实验一.pdf”。这些都在 report.html 的 CSS 中设定：
#       body { font-family:"SimSun","宋体",…; font-size:12pt; line-height:1.25 }
#
# 依赖：LibreOffice（soffice）与 poppler-utils（pdfinfo，仅用于检查页数）
# 注意：本机没有安装“宋体/SimSun”，PDF 渲染时会自动替换为 Noto Serif CJK SC
#       （同为衬线中文字体）；文档中声明的字体仍是宋体。
# =============================================================================
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$DIR/build"
NAME="202400390056-于昕杨-实验一"          # 学号-姓名-实验一
LO_PROFILE="file://$BUILD/lo-profile"    # 可写的 LibreOffice 用户配置目录

mkdir -p "$BUILD"

lo() {
  soffice -env:UserInstallation="$LO_PROFILE" --headless --norestore "$@"
}

echo "[report] HTML -> PDF ..."
lo --infilter="HTML (StarWriter)" --convert-to pdf:writer_pdf_Export --outdir "$BUILD" "$DIR/report.html" >/dev/null 2>&1
cp -f "$BUILD/report.pdf" "$DIR/$NAME.pdf"

echo "[report] HTML -> DOCX ..."
lo --infilter="HTML (StarWriter)" --convert-to docx:"MS Word 2007 XML" --outdir "$BUILD" "$DIR/report.html" >/dev/null 2>&1
cp -f "$BUILD/report.docx" "$DIR/$NAME.docx"

echo "[report] 生成结果："
ls -l "$DIR/$NAME.pdf" "$DIR/$NAME.docx"
echo "[report] 页数：$(pdfinfo "$DIR/$NAME.pdf" | awk '/^Pages/{print $2}')（要求不超过 8 页）"
echo "[report] 纸张：$(pdfinfo "$DIR/$NAME.pdf" | awk -F': *' '/^Page size/{print $2}')"
