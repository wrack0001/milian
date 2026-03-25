# Go Unit Test Skill

> Go 单元测试（UT）编写规范与落地清单，提供基础测试、表驱动、结构体方法、并发、基准测试、错误处理 6 类可直接套用的测试模板。

## 技能简介

本技能为 AI 提供 Go 语言单元测试的编写规范和最佳实践，帮助开发者快速生成高质量、规范化的单元测试代码。

### 核心特性

- **命名规范**：测试函数以 `TestUnit` 开头，可被 `-run=TestUnit` 统一筛选
- **表驱动测试**：提供 `tests := []struct{...}{...}` + `t.Run` 标准模板
- **Mock 支持**：gomonkey 函数/方法 patch + gomock 接口 mock，含完整操作步骤
- **6 类测试模板**：基础 / 表驱动 / 结构体方法 / 并发 / 基准 / 错误处理
- **断言规范**：统一使用 testify/assert，明确 assert vs require 使用时机

## 安装方法

```bash
npx skills add https://github.com/wrack0001/milian --skill unit-test-go
```

## 目录结构

```
unit-test-go/
├── SKILL.md                  # 技能定义文件（核心）
├── README.md                 # 使用说明（本文件）
├── LICENSE.txt               # 许可证
└── reference/                # 参考文档（按场景选用）
    ├── basic-test.md         # 基础测试：纯函数、无依赖、无需 mock
    ├── table-driven-test.md  # 表驱动测试：多组输入/输出场景
    ├── struct-method-test.md # 结构体方法测试：需要 mock/stub 的场景
    ├── concurrent-test.md    # 并发测试：goroutine、atomic、sync
    ├── benchmark-test.md     # 基准测试：性能测量与优化
    └── error-handling.md     # 错误处理与断言：error 处理规范
```

## 使用方式

在对话中描述需求即可，技能会自动选择合适的测试模板：

```
# 生成基础单元测试
请为 service/user.go 中的 GetUser 函数生成单元测试

# 生成带 Mock 的测试
请为 OrderService.CreateOrder 方法生成单元测试，需要 mock 数据库依赖

# 生成并发测试
请为 worker.go 中的并发处理逻辑生成测试
```

## 测试执行命令

```bash
# 执行所有单元测试（必须携带两个参数）
GOARCH=amd64 go test ./... \
  -gcflags=all=-l \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" \
  -run=TestUnit

# 执行基准测试
go test ./... -bench=. -benchmem \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn"
```

> **参数说明**
> - `GOARCH=amd64`：gomonkey 依赖 x86/x64 指令集，ARM 架构（如 Apple M 芯片）下 mock 会失效
> - `-gcflags=all=-l`：禁用内联优化，gomonkey patch 依赖此参数，缺少时 mock 失效
> - `-ldflags "..."`：解决 protobuf 注册冲突

## 命名规范速查

| 被测代码 | 测试函数命名 | 说明 |
|---------|-------------|------|
| `func Foo(...)` | `TestUnit_Foo` | 普通函数，下划线在 Unit 和函数名之间 |
| `func (b *Bar) Foo(...)` | `TestUnitBar_Foo` | 结构体方法，类型名紧接 Unit，下划线在类型名和方法名之间 |
| `func BenchmarkFoo(b *testing.B)` | `BenchmarkFoo` | 基准测试，豁免 TestUnit 规则 |

> 除以上规则之外，下划线**不得**出现在测试函数名的任何其他位置。

## Mock 使用规范

### 选择 gomock 还是 gomonkey

| 场景 | 推荐方式 |
|------|---------|
| 项目 `mock/` 目录已有 `NewMockXxx` | 使用 gomock |
| 需要 patch 具体函数/私有方法 | 使用 gomonkey |
| 外部依赖（数据库/HTTP/文件） | 必须 mock（任意方式） |

### gomonkey 注意事项

- `reflect.TypeOf` 参数：指针接收者方法用 `&T{}`，值接收者方法用 `T{}`
- patch 必须在测试函数**循环外**初始化，`defer p.Reset()` 在函数级执行
- 需配合 `-gcflags=all=-l` 参数，否则 mock 失效

### Mock 文件生成

```bash
# 安装 mockgen
go install github.com/golang/mock/mockgen@latest

# 生成 mock（//go:generate 注释须紧贴 interface 定义上方）
go generate ./...

# 若生成文件中出现 go.uber.org/mock/gomock，批量替换为 github.com/golang/mock/gomock
grep -rl "go.uber.org/mock/gomock" . --include="*_mock.go" | \
  xargs sed -i '' 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g'
```

## 注意事项

1. **测试文件包名**：使用 `package foo`（与源文件同包），不用 `package foo_test`
2. **断言库**：统一使用 `testify/assert`；断言失败后无法继续时改用 `testify/require`
3. **子测试命名**：`tt.name` 必须唯一且语义化，禁止重复使用 `"test"` / `"normal"`
4. **错误处理**：所有返回的 error 必须处理，禁止用 `_` 忽略
5. **文件行数**：测试文件最多 1600 行，测试函数最多 160 行

## 相关资源

- [Go Testing 官方文档](https://golang.org/pkg/testing/)
- [gomock 项目](https://github.com/golang/mock)
- [gomonkey 项目](https://github.com/agiledragon/gomonkey)
- [testify 断言库](https://github.com/stretchr/testify)

## 许可证

MIT License - 详见 [LICENSE.txt](./LICENSE.txt)

---

**版本**：2.0.0
**维护者**：wanghaidong
**更新日期**：2026-03-25
