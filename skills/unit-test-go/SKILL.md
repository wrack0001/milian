---
name: unit-test-go
description: Go 单元测试（UT）编写规范与落地清单（默认可被 `-run=TestUnit` 筛选），并提供可直接套用的表驱动测试（table-driven + `t.Run`）模板。
license: Complete terms in LICENSE.txt
---

## 项目要求

### 测试用例生成策略
- **质量优先**: 优先保证生成的测试用例能够正确运行，确保代码质量
- **完整覆盖**: 生成全面的测试用例，包括正常流程、边界情况和异常处理
- **场景丰富**: 根据函数特性生成多种测试场景，提高测试覆盖率

## 单测代码规范
- **使用testing框架**：使用t.Run方法执行单测代码。
- **必要的import语句**: 包括 testing 包以及所有被测试函数和mock对象所需的包。
- **测试函数**: 每个测试用例都应该有一个对应的测试函数，函数名以 TestUnit 开头，并接受一个 *testing.T 类型的参数。
- **测试逻辑**: 在测试函数中，首先创建被测试函数所需的依赖（包括mock对象），然后调用被测试函数，最后使用断言来验证函数的行为是否符合预期。
- **测试函数命名**: `TestUnit_` + 被测试函数名（示例：`func TestUnitExample(t *testing.T)`）

## Mock 生成规范
- go:generate mockgen -source=task_repo.go -destination=./mock/repo_mock.go -package=taskMock
- 如果生成的`gomock`是`go.uber.org/mock/gomock`替换成`github.com/golang/mock/gomock`

### 使用 go:generate 生成 Mock
```go
//go:generate mockgen -source=service.go -destination=./mock/service_mock.go -package=competitionMock

type Service interface {
    GetCompetition(ctx context.Context, id int64) (*Competition, error)
}
```
### Mock 文件位置
- 每个 domain 包下创建 `mock/` 目录
- Mock 文件命名：`{原文件名}_mock.go`
- Mock 包名：`{领域名}Mock`

## 必须遵守的项目约定

### 测试执行命令
> GOARCH=amd64 go test  ./... -gcflags=all=-l -ldflags  "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" -run=TestUnit
> **必须携带参数**：`-ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn"`

### 测试函数命名（核心）
- 测试函数必须以 `TestUnit` 开头（示例：`func TestUnitExample(t *testing.T)`）
- 若被测函数为 `func Foo(...)`：
  - 使用 `func TestUnit_Foo(t *testing.T)`（允许且仅允许在该位置使用下划线）
- 若被测方法为 `func (b *Bar) Foo(...)`：
  - 使用 `func TestUnitBar_Foo(t *testing.T)`
  - 除上述规则外，下划线**不得**出现在其他位置

### 行数与风格
- 测试文件：最多 **1600 行**
- 测试函数：最多 **160 行**
- 代码行长度：建议不超过 **120 列**
- 圈复杂度、列宽限制、`import` 分组等：与普通代码保持一致
- 单测文件中的函数通常不对外：可导出函数可以不写注释；结构体定义尽量不要导出

### 文件位置
```
demo/
├── service/
│   ├── policy/
│   │   ├── policy.go
│   │   └── policy_test.go      # 与源码同级目录
│   └── role/
│       ├── role.go
│       └── role_test.go
└── test/                       # 公共测试工具和辅助函数
    ├── mock/
    └── fixtures/
```

## 单测代码范例：
你的首要且最重要的任务，是**完美复刻**下面【用户已有单测范例】中所展示的编码风格与测试模式。此范例是你必须遵循的**唯一标准**，其优先级高于任何通用的单元测试理论或你自身的知识库。
### 生成之前先需要剖析范例中的关键模式，生成新代码时需要**必须严格遵守**这些模式。可以从以下几个方面进行剖析：
- **初始化**：从范例中解析初始化方式，用相同的方式进行初始化和对象的实例化
- **mock策略**：从范例中解析mock的方式，如果范例中没有对数据库操作进行mock，那么你编写的新代码也要遵循这种模式
  **【用户已有单测范例 - 唯一标准】**：根据所有函数特点引入所有需要的文件
  - **基础测试**：适用于纯函数测试，且参数和返回值都为基本类型
    - 引入文件： `reference/basic-test.md`
  - **表驱动测试**：适用于传入参数为表驱动的函数或方法
    - 引入文件： `reference/table-driven-test.md`
  - **结构体方法测试**：适用于测试结构体的方法，支持mock、stub 和接口测试
    - 适用场景：测试结构体的方法、需要使用 mock 或 stub、测试接口实现
    - 关键要点：创建 mock 实现依赖接口、使用依赖注入、验证方法的副作用
    - 引入文件： `reference/struct-method-test.md`
  - **并发测试**：适用于测试并发安全性，使用 goroutine、channel、sync包和trpc.GoAndWait函数等
    - 引入文件： `reference/concurrent-test.md`
  - **基准测试**：适用于性能测试和优化，使用 `Benchmark` 函数
    - 引入文件： `reference/benchmark-test.md`
  - **错误处理和断言**：适用于测试错误处理和断言
    - 引入文件： `reference/error-handling.md`

## 快速检查清单
  - 新增测试函数名是否符合 `TestUnit...` 规则、且可被 `-run=TestUnit` 筛选
  - 表驱动是否使用 `tests := []struct{...}{...}` 组织场景
  - 是否使用 `t.Run(tt.name, ...)` 输出清晰的子用例
  - 是否覆盖：正常路径 + 关键边界 + 错误路径（如除零、空值、越界等）
  - 执行 go test 是否带 `-ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn"`
  - import 分组是否符合项目规范（必要时使用 `imports` skill 协助）
