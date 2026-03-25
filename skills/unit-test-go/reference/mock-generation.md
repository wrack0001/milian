# Mock 生成规范

所有接口 mock 通过 `mockgen` 生成到 `./mock/` 子目录，**禁止手写 mock**，生成文件提交到 git 与源码一起维护。

## 安装 mockgen

统一使用新版 `go.uber.org/mock`：

```bash
go install go.uber.org/mock/mockgen@latest
```

> `github.com/golang/mock` 是已停止维护的旧版，`go.uber.org/mock` 是其官方接续版本，API 完全兼容。若项目 `go.mod` 仍依赖旧版，生成后需对齐导入路径（见下文）。

## 添加 go:generate 指令

在 interface 定义**上方**、同一文件中添加 `//go:generate` 指令：

```go
// domain/room/client.go
package room

import "context"

//go:generate mockgen -source=client.go -destination=./mock/client_mock.go -package=roomMock

type Client interface {
    GetRoomInfo(ctx context.Context, roomID string) (*model.RoomInfo, error)
}
```

| 参数 | 说明 |
|---|---|
| `-source=client.go` | 当前文件，使用相对路径，不写绝对路径 |
| `-destination=./mock/client_mock.go` | 输出到 `./mock/` 子目录 |
| `-package=roomMock` | 包名格式：`<模块名>Mock`（驼峰，与源包隔离） |

生成后的目录结构：

```
domain/room/
├── client.go           # interface 定义 + go:generate 指令（同一文件）
├── room.go
├── room_test.go
└── mock/
    └── client_mock.go  # package roomMock
```

## 执行生成

```bash
go generate ./...
```

接口变更后重新执行，将更新后的 mock 文件一并提交。

## 对齐导入路径（按需）

若项目 `go.mod` 依赖 `github.com/golang/mock`，生成文件的 import 路径会是 `go.uber.org/mock/gomock`，需替换：

```bash
# macOS（BSD sed）
sed -i '' 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g' domain/room/mock/*.go

# Linux（GNU sed）
sed -i 's|go.uber.org/mock/gomock|github.com/golang/mock/gomock|g' domain/room/mock/*.go
```