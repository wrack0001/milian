# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目说明

本仓库是米连科技（milian）的 Claude AI Skill 包集合，包含以下 skill：

| Skill | 用途 | 安装命令 |
|-------|------|---------|
| `unit-test-go` | Go 单元测试编写规范与模板 | `npx skills add https://github.com/wrack0001/milian --skill unit-test-go` |
| `weekly-report` | 将工作流水账整理成 OKR 周报 | `npx skills add https://github.com/wrack0001/milian --skill weekly-report` |

## 仓库架构

每个 skill 目录下的 `SKILL.md` 是核心文件，定义了 skill 的行为规则与约束。`reference/` 目录下的 `.md` 文件是供 skill 引用的代码模板。`scripts/`（可选）存放辅助脚本。

## 新增 Skill 的结构约定

新 skill 目录应包含：
- `SKILL.md`：frontmatter 含 `name`、`description`、`license` 字段；正文包含禁止操作、生成策略、规范、工程约定等章节
- `README.md`：面向用户的说明文档
- `LICENSE.txt`：许可证文件
- `reference/`（可选）：细分场景的参考文档
- `scripts/`（可选）：辅助脚本

## unit-test-go Skill 核心规范摘要

完整规范见 `skills/unit-test-go/SKILL.md`，以下为关键约定：

### 测试函数命名
- 普通函数：`TestUnit_Foo`
- 结构体方法 `(b *Bar) Foo`：`TestUnitBar_Foo`
- 基准测试：`BenchmarkFoo`（豁免 TestUnit 前缀）
- 除上述规则外，下划线不得出现在函数名其他位置

### 测试执行命令（在使用此 skill 的目标项目中执行）

```bash
# 单元测试
GOARCH=amd64 go test ./... \
  -gcflags=all=-l \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" \
  -run=TestUnit

# 基准测试
go test ./... -bench=. -benchmem \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn"
```

> `-gcflags=all=-l` 和 `-ldflags` 两个参数缺一不可。`GOARCH=amd64` 在 Apple M 芯片上必须指定（gomonkey 依赖 x86/x64 指令集）。

### Mock 工具选择

| 场景 | 工具 |
|------|------|
| 项目已有 `NewMockXxx` | gomock |
| patch 具体函数/私有方法 | gomonkey |
| 外部依赖（DB/HTTP/文件） | 必须 mock |

### Mock 文件生成

```bash
go install github.com/golang/mock/mockgen@latest
go generate ./...
```

若生成文件中出现 `go.uber.org/mock/gomock`，需批量替换为 `github.com/golang/mock/gomock`。

## weekly-report Skill 核心规范摘要

完整规范见 `skills/weekly-report/SKILL.md`，以下为关键约定：

### 脚本命令

```bash
# 初始化季度 OKR（每季度运行一次）
bash skills/weekly-report/scripts/new-quarter.sh <reports-dir> [year] [quarter]

# 创建周报文件（每周运行）
bash skills/weekly-report/scripts/new-report.sh <reports-dir>              # 当前周
bash skills/weekly-report/scripts/new-report.sh <reports-dir> --date YYYY-MM-DD  # 补录
```

脚本依赖 `python3` 计算日期。输出 `REPORT_FILE` 和 `OKR_FILE` 路径供 skill 读取。

### 周报目录结构（由脚本自动生成在用户指定的 reports-dir 中）

```
<reports-dir>/<year>/Q<quarter>/okr.md
<reports-dir>/<year>/Q<quarter>/<month>/<MM.DD-MM.DD>/report.md
```

### 周报格式要点
- 两张 Markdown 表格：上周工作总结（7列）+ 本周工作计划（7列）
- 三只青蛙排序：🐸1 > 🐸2 > 🐸3，按 OKR 优先级排列，其余为临时任务
- 状态标记：🟢 完成 / 🟡 部分完成 / 🔴 未完成
- 🟡/🔴 任务自动带入下周计划
- 无法推断的字段标注 `（待补充）`/`（待确认）`
