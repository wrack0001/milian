#!/bin/bash
# new-report.sh — 创建周报文件
#
# 用法:
#   bash new-report.sh <reports-dir> [--date YYYY-MM-DD]
#
# 示例:
#   bash new-report.sh ~/weekly-reports                      # 当前周
#   bash new-report.sh ~/weekly-reports --date 2026-03-09   # 补录指定日期所在周

set -e

REPORTS_DIR="${1:?用法: new-report.sh <reports-dir> [--date YYYY-MM-DD]}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="${SKILL_DIR}/reference/report-template.md"

REF_DATE=""
shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --date)
            if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                echo "❌ 错误: --date 需要提供日期值，格式: YYYY-MM-DD"
                exit 1
            fi
            REF_DATE="$2"; shift 2 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

if [ -n "$REF_DATE" ] && ! [[ "$REF_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "❌ 错误: 日期格式必须为 YYYY-MM-DD，收到: $REF_DATE"
    exit 1
fi

read -r YEAR QUARTER MONTH WEEK_DIR PREV_YEAR PREV_QUARTER PREV_MONTH PREV_WEEK_DIR <<< "$(python3 - "$REF_DATE" <<'PYEOF'
import sys
from datetime import date, timedelta

arg = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else ""
ref = date.fromisoformat(arg) if arg else date.today()

monday = ref - timedelta(days=ref.weekday())
sunday = monday + timedelta(days=6)
year    = monday.year
month   = f"{monday.month:02d}"
quarter = (monday.month - 1) // 3 + 1
week_dir = f"{monday.strftime('%m.%d')}-{sunday.strftime('%m.%d')}"

prev_monday = monday - timedelta(days=7)
prev_sunday = prev_monday + timedelta(days=6)
prev_year    = prev_monday.year
prev_month   = f"{prev_monday.month:02d}"
prev_quarter = (prev_monday.month - 1) // 3 + 1
prev_week_dir = f"{prev_monday.strftime('%m.%d')}-{prev_sunday.strftime('%m.%d')}"

print(year, quarter, month, week_dir, prev_year, prev_quarter, prev_month, prev_week_dir)
PYEOF
)"

REPORT_DIR="${REPORTS_DIR}/${YEAR}/Q${QUARTER}/${MONTH}/${WEEK_DIR}"
REPORT_FILE="${REPORT_DIR}/report.md"
OKR_FILE="${REPORTS_DIR}/${YEAR}/Q${QUARTER}/okr.md"
PREV_REPORT_FILE="${REPORTS_DIR}/${PREV_YEAR}/Q${PREV_QUARTER}/${PREV_MONTH}/${PREV_WEEK_DIR}/report.md"

if [ ! -f "$OKR_FILE" ]; then
    echo ""
    if [ -n "$REF_DATE" ]; then
        echo "⚠️  补录模式：${YEAR} 年 Q${QUARTER} 的 OKR 文件不存在："
    else
        echo "⚠️  首次使用？检测到季度 OKR 文件不存在："
    fi
    echo "    ${OKR_FILE}"
    echo ""
    echo "请先初始化该季度："
    echo "    bash $(dirname "$0")/new-quarter.sh ${REPORTS_DIR} ${YEAR} ${QUARTER}"
    echo ""
    echo "初始化完成后编辑 okr.md 填写你的 OKR，再重新运行本脚本。"
    echo ""
    exit 1
fi

mkdir -p "$REPORT_DIR"

if [ -f "$REPORT_FILE" ]; then
    echo "📄 周报已存在，跳过创建"
else
    if [ ! -f "$TEMPLATE" ]; then
        echo "❌ 创建周报失败，模板文件不存在: $TEMPLATE"
        exit 1
    fi
    cp "$TEMPLATE" "$REPORT_FILE"
    if [ -n "$REF_DATE" ]; then
        echo "✅ 已创建补录周报（${WEEK_DIR}）"
    else
        echo "✅ 已创建本周周报"
    fi
fi

echo "---"
echo "REPORT_FILE=${REPORT_FILE}"
echo "WEEK=${WEEK_DIR}"
echo "YEAR=${YEAR} Q${QUARTER} ${MONTH}月"
echo "OKR_FILE=${OKR_FILE}"
if [ -f "$PREV_REPORT_FILE" ]; then
    echo "PREV_REPORT_FILE=${PREV_REPORT_FILE}"
else
    echo "PREV_REPORT_FILE="
fi
