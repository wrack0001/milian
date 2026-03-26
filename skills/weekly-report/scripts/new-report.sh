#!/bin/bash
# new-report.sh — 创建本周周报文件
#
# 用法:
#   bash new-report.sh <reports-dir>
#
# 示例:
#   bash new-report.sh ~/weekly-reports
#
# 输出:
#   创建文件: {reports-dir}/{year}/Q{quarter}/{month}/{MM.DD-MM.DD}/report.md
#   打印文件路径（供 LLM 读取）

set -e

REPORTS_DIR="${1:?用法: new-report.sh <reports-dir>}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="${SKILL_DIR}/reference/report-template.md"

# 用 Python3 计算日期（跨平台，macOS/Linux 均可用）
read -r YEAR QUARTER MONTH WEEK_DIR <<< "$(python3 - <<'PYEOF'
from datetime import date, timedelta
today = date.today()
monday = today - timedelta(days=today.weekday())   # 本周一
sunday = monday + timedelta(days=6)                # 本周日
year    = monday.year
month   = f"{monday.month:02d}"
quarter = (monday.month - 1) // 3 + 1
week_dir = f"{monday.strftime('%m.%d')}-{sunday.strftime('%m.%d')}"
print(year, quarter, month, week_dir)
PYEOF
)"

REPORT_DIR="${REPORTS_DIR}/${YEAR}/Q${QUARTER}/${MONTH}/${WEEK_DIR}"
REPORT_FILE="${REPORT_DIR}/report.md"
OKR_FILE="${REPORTS_DIR}/${YEAR}/Q${QUARTER}/okr.md"

# 检查 OKR 文件是否存在
if [ ! -f "$OKR_FILE" ]; then
    echo "⚠️  找不到 OKR 文件: ${OKR_FILE}"
    echo "请先初始化本季度："
    echo "  bash $(dirname "$0")/new-quarter.sh ${REPORTS_DIR} ${YEAR} ${QUARTER}"
    exit 1
fi

mkdir -p "$REPORT_DIR"

if [ -f "$REPORT_FILE" ]; then
    echo "📄 周报已存在，跳过创建"
else
    cp "$TEMPLATE" "$REPORT_FILE"
    echo "✅ 已创建周报"
fi

echo "---"
echo "REPORT_FILE=${REPORT_FILE}"
echo "WEEK=${WEEK_DIR}"
echo "YEAR=${YEAR} Q${QUARTER} ${MONTH}月"
echo "OKR_FILE=${OKR_FILE}"
