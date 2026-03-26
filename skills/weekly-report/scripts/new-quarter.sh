#!/bin/bash
# new-quarter.sh — 初始化新季度目录和 OKR 文件
#
# 用法:
#   bash new-quarter.sh <reports-dir> [year] [quarter]
#
# 示例:
#   bash new-quarter.sh ~/weekly-reports          # 自动取当前年/季度
#   bash new-quarter.sh ~/weekly-reports 2026 2   # 指定年和季度

set -e

REPORTS_DIR="${1:?用法: new-quarter.sh <reports-dir> [year] [quarter]}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="${SKILL_DIR}/reference/okr-template.md"

read -r DEFAULT_YEAR DEFAULT_QUARTER <<< "$(python3 - <<'PYEOF'
from datetime import date
today = date.today()
print(today.year, (today.month - 1) // 3 + 1)
PYEOF
)"

YEAR="${2:-$DEFAULT_YEAR}"
QUARTER="${3:-$DEFAULT_QUARTER}"

OKR_DIR="${REPORTS_DIR}/${YEAR}/Q${QUARTER}"
OKR_FILE="${OKR_DIR}/okr.md"

mkdir -p "$OKR_DIR"

if [ -f "$OKR_FILE" ]; then
    echo "📄 OKR 文件已存在，跳过创建"
else
    cp "$TEMPLATE" "$OKR_FILE"
    echo "✅ 已创建 OKR 文件"
fi

echo "---"
echo "OKR_FILE=${OKR_FILE}"
echo "YEAR=${YEAR} Q${QUARTER}"
echo ""
echo "下一步: 编辑 ${OKR_FILE}，填写本季度 OKR"
