# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目说明

本仓库是米连科技（milian）的 Claude AI Skill 包集合，目前包含 `unit-test-go` 一个 skill，提供 Go 单元测试编写规范与模板。

安装方式：

```bash
npx skills add https://github.com/wrack0001/milian --skill unit-test-go
```

## 仓库结构

```
skills/
└── unit-test-go/
    ├── SKILL.md              # Skill 核心定义（规范、命名、生成策略等）
    ├── README.md             # 安装说明与使用指引
    └── reference/            # 6 类测试模板（按场景选用）
```

每个 skill 目录下的 `SKILL.md` 是核心文件，定义了 skill 的行为规则与约束。`reference/` 目录下的 `.md` 文件是供 skill 引用的代码模板。

## 新增 Skill 的结构约定

新 skill 目录应包含：
- `SKILL.md`：frontmatter 含 `name`、`description`、`license` 字段；正文包含禁止操作、生成策略、规范、工程约定等章节
- `README.md`：面向用户的说明文档
- `LICENSE.txt`：许可证文件
- `reference/`（可选）：细分场景的参考文档

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
