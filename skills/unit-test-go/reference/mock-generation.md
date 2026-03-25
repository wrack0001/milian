# Mock 生成与使用规范

所有接口 mock 通过 `mockgen` 生成到 `./mock/` 子目录，**禁止手写 mock**。

> **版本背景**：`github.com/golang/mock` 已停止维护，`go.uber.org/mock` 是其官方接续版本，两者 API 完全兼容，仅 module 路径不同。**生成文件的 import 路径必须与项目 `go.mod` 中声明的版本一致**，否则会编译报错。

## 前置条件

根据项目 `go.mod` 中使用的版本安装对应的 `mockgen`：

```bash
# 项目使用 go.uber.org/mock（新版，推荐）
go install go.uber.org/mock/mockgen@latest

# 项目使用 github.com/golang/mock（旧版）
go install github.com/golang/mock/mockgen@latest
```

> 工具版本决定生成文件的 import 路径，保持与项目依赖一致可避免 Step 3 的额外操作。

## 快速开始

### 1. 在接口定义上方添加 go:generate 指令

```go
// domain/room/client.go
package room

import (
    "context"

    "rtc/rtc-service/domain/model" // 替换为实际 module 路径
)

//go:generate mockgen -source=client.go -destination=./mock/client_mock.go -package=roomMock

type Client interface {
    GetRoomInfo(ctx context.Context, roomID string) (*model.RoomInfo, error)
}
```

### 2. 执行生成

```bash
go generate ./domain/room/...
```

生成的文件：`domain/room/mock/client_mock.go`，包名为 `roomMock`。

### 3. 对齐导入路径（按需）

检查生成文件的 import 路径是否与项目 `go.mod` 一致：

```bash
head -10 domain/room/mock/client_mock.go | grep mock
```

**情况一：路径一致，无需处理。** 例如项目使用 `go.uber.org/mock`，生成文件也是 `go.uber.org/mock/gomock`。

**情况二：路径不一致，执行替换。** 常见于使用新版 `mockgen`（`go.uber.org/mock`）但项目依赖仍是 `github.com/golang/mock` 的情况：

```bash
# macOS（BSD sed）
sed -i '' 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g' domain/room/mock/*.go

# Linux（GNU sed）
sed -i 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g' domain/room/mock/*.go
```

> 若每次生成后都需替换，建议将该命令加入 CI 的 `go generate` 步骤之后自动执行。

## 文件结构

```
domain/room/
├── client.go           # interface 定义 + go:generate 指令（同一文件）
├── room.go             # 实现
├── room_test.go        # 测试
└── mock/
    └── client_mock.go  # 生成的 mock（独立包 roomMock）
```

## go:generate 指令详解

```go
//go:generate mockgen -source=client.go -destination=./mock/client_mock.go -package=roomMock
```

| 参数 | 说明 |
|---|---|
| `-source=client.go` | 源文件，相对于当前目录（即 `client.go` 所在目录） |
| `-destination=./mock/client_mock.go` | 输出路径，生成到 `./mock/` 子目录 |
| `-package=roomMock` | 生成文件的包名，使用驼峰命名（项目约定，非 Go 通用规范） |

**要点**：
- `//go:generate` 紧贴 interface 定义上方，与 interface 在同一文件
- `-source` 指向当前文件，不要写绝对路径
- `-package` 使用 `<模块名>Mock` 格式的独立包名，与源包隔离

## 在测试中使用

```go
// domain/cdn/cdn_test.go
package cdn

import (
    "testing"

    "rtc/rtc-service/domain/model"
    roomMock "rtc/rtc-service/domain/room/mock"
    redisMock "rtc/rtc-service/infra/redis/mock"
    "github.com/golang/mock/gomock" // 替换为项目实际使用的版本路径
)

func TestUnitClient_StartPublishCdn(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    // 使用别名导入，避免不同 mock 包的命名冲突
    mockRoom := roomMock.NewMockClient(ctrl)
    mockRedis := redisMock.NewMockRTC(ctrl)

    mockRoom.EXPECT().
        GetRoomInfo(gomock.Any(), "room-123").
        Return(&model.RoomInfo{}, nil).
        Times(1)

    // 测试逻辑...
}
```

## 执行测试

```bash
GOARCH=amd64 go test ./domain/cdn -v \
  -gcflags=all=-l \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn"
```

**参数说明**：
- `GOARCH=amd64`：gomonkey 依赖 x86/x64 指令集修改机器码，在 ARM（Apple M 芯片）上须显式指定
- `-gcflags=all=-l`：禁用编译器内联优化；gomonkey 通过替换函数入口地址实现 patch，内联会消除该地址导致 mock 失效
- `-ldflags "...conflictPolicy=warn"`：抑制 protobuf 注册表冲突 panic，测试中多个包注册同一 proto 时触发

## 常见问题

### Q: go:generate 指令写在哪里？

A: **紧贴 interface 定义上方，与 interface 在同一文件**。

```go
// ✅ 正确：指令与 interface 同文件，接口变更时更容易同步更新
//go:generate mockgen -source=service.go -destination=./mock/service_mock.go -package=xxxMock

type Service interface {
    Foo() error
}
```

```go
// ⚠️ 不推荐：指令放在独立文件（如 mock.go）
// go generate 可以找到并执行，但接口变更时指令容易被遗忘，维护成本高
package xxx
//go:generate mockgen ...
```

### Q: 如何在测试中导入？

A: 使用别名导入，避免多个 mock 包同名冲突：

```go
import (
    roomMock "xxx/domain/room/mock"
    redisMock "xxx/infra/redis/mock"
)
```

### Q: 生成文件的 import 路径与项目不一致怎么办？

A: 这是工具版本（`mockgen` 来源）与项目依赖版本不一致导致的。根据项目 `go.mod` 中的版本，执行对应的替换：

```bash
# 项目使用 github.com/golang/mock，但生成了 go.uber.org/mock 路径
# macOS（BSD sed）
sed -i '' 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g' **/mock/*_mock.go
# Linux（GNU sed）
sed -i 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g' **/mock/*_mock.go

# 项目使用 go.uber.org/mock，但生成了 github.com/golang/mock 路径
# macOS（BSD sed）
sed -i '' 's|github.com/golang/mock/gomock|go.uber.org/mock/gomock|g' **/mock/*_mock.go
# Linux（GNU sed）
sed -i 's|github.com/golang/mock/gomock|go.uber.org/mock/gomock|g' **/mock/*_mock.go
```

根本解决：安装与项目依赖版本对应的 `mockgen`（见「前置条件」），生成后无需替换。
