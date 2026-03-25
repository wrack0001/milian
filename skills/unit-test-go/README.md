# Go Unit Test Skill

> Go 单元测试（UT）编写规范与落地清单，提供可直接套用的表驱动测试模板。

## 📦 技能简介

本技能为 CodeBuddy 提供 Go 语言单元测试的编写规范和最佳实践，帮助开发者快速生成高质量、规范化的单元测试代码。

### 核心特性

- ✅ **命名规范**：测试函数以 `TestUnit` 开头，可被 `-run=TestUnit` 筛选
- ✅ **表驱动测试**：提供 `table-driven + t.Run` 模板
- ✅ **Mock 生成**：支持 `go:generate mockgen` 规范
- ✅ **多场景覆盖**：基础测试、并发测试、基准测试、错误处理等

## 🚀 安装方法

### 方法一：手动安装

npx skills add https://github.com/wrack0001/milian --skill unit-test-go
嗯
## 📁 目录结构

```
unit-test-go/
├── SKILL.md              # 技能定义文件（核心）
├── README.md             # 使用说明（本文件）
├── LICENSE.txt           # 许可证
├── skills_summary.md     # 技能摘要
├── reference/            # 参考文档
│   ├── basic-test.md         # 基础测试范例
│   ├── table-driven-test.md  # 表驱动测试范例
│   ├── struct-method-test.md # 结构体方法测试
│   ├── concurrent-test.md    # 并发测试范例
│   ├── benchmark-test.md     # 基准测试范例
│   └── error-handling.md     # 错误处理范例
├── assets/               # 静态资源（预留）
└── scripts/              # 脚本资源（预留）
```

## 📖 使用方式

### 1. 激活技能

在 CodeBuddy 对话中，技能会根据以下关键词自动激活：

- 提到"单元测试"、"unit test"、"UT"
- 请求生成 Go 测试代码
- 讨论 mock、表驱动测试等相关话题

### 2. 常用指令示例

```
# 生成基础单元测试
请为 service/user.go 中的 GetUser 函数生成单元测试

# 生成表驱动测试
请使用表驱动方式为 Calculate 函数生成测试用例

# 生成带 Mock 的测试
请为 OrderService.CreateOrder 方法生成单元测试，需要 mock 数据库依赖
```

### 3. 测试执行命令

```bash
# 执行所有单元测试
GOARCH=amd64 go test ./... -gcflags=all=-l \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" \
  -run=TestUnit

# 执行指定包的测试
go test ./service/... -run=TestUnit -v
```

## 📋 命名规范速查

| 被测代码 | 测试函数命名 |
|---------|-------------|
| `func Foo(...)` | `TestUnit_Foo` |
| `func (b *Bar) Foo(...)` | `TestUnitBar_Foo` |

## ⚠️ 注意事项

1. **必须携带 ldflags 参数**：执行测试时需添加 `-ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn"`
2. **Mock 包替换**：如生成的 gomock 是 `go.uber.org/mock/gomock`，需替换为 `github.com/golang/mock/gomock`
3. **文件行数限制**：测试文件最多 1600 行，测试函数最多 160 行

## 🔗 相关资源

- [Go Testing 官方文档](https://golang.org/pkg/testing/)
- [gomock 项目](https://github.com/golang/mock)
- [testify 断言库](https://github.com/stretchr/testify)

## 📄 许可证

MIT License - 详见 [LICENSE.txt](./LICENSE.txt)

---

**版本**：1.0.0  
**维护者**：wanghaidong
**更新日期**：2026-01-28
