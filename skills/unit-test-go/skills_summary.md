# Go 单元测试技能 (unit-test-go)

## 功能概述

`unit-test-go` 是一个专门为 Go 语言项目设计的单元测试编写规范与模板技能。它提供了：

- **标准化的测试命名规范**：所有测试函数以 `TestUnit` 开头，便于统一筛选执行
- **表驱动测试模板**：提供 `table-driven + t.Run` 的标准模板，覆盖多种测试场景
- **Mock 生成规范**：统一的 Mock 文件组织结构和生成命令
- **多场景测试指南**：包含基础测试、结构体方法测试、并发测试、基准测试、错误处理等多种场景

## 使用方法

### 1. 激活技能

在对话中提及以下关键词时，技能将自动激活：
- "单元测试"、"unit test"、"UT"
- "表驱动测试"、"table-driven"
- "mock 生成"、"测试用例"

### 2. 常用指令

```
# 为某个函数生成单元测试
请为 xxx.go 中的 Foo 函数生成单元测试

# 生成 Mock 文件
请为 service.go 中的接口生成 Mock

# 检查测试规范
请检查这个测试文件是否符合规范
```

### 3. 执行测试

```bash
GOARCH=amd64 go test ./... -gcflags=all=-l \
  -ldflags "-X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=warn" \
  -run=TestUnit
```

## 预期输出

使用此技能后，你将获得：

1. **规范的测试代码**：符合 `TestUnit_` 命名规范，可被统一筛选执行
2. **高覆盖率的测试用例**：涵盖正常流程、边界情况、错误处理
3. **清晰的子用例输出**：通过 `t.Run` 组织，日志输出清晰易读
4. **可维护的 Mock 结构**：统一的 Mock 目录和命名规范

## 技能文件结构

```
unit-test-go/
├── SKILL.md              # 技能核心定义
├── LICENSE.txt           # MIT 开源许可证
├── skills_summary.md     # 本文件 - 技能摘要
├── README.md             # 详细使用说明
├── reference/            # 参考文档
│   ├── basic-test.md         # 基础测试示例
│   ├── table-driven-test.md  # 表驱动测试示例
│   ├── struct-method-test.md # 结构体方法测试示例
│   ├── concurrent-test.md    # 并发测试示例
│   ├── benchmark-test.md     # 基准测试示例
│   └── error-handling.md     # 错误处理示例
├── assets/               # 资源文件目录
└── scripts/              # 脚本文件目录
```