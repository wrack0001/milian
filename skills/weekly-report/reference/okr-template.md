# Q1 2026 OKR

<!-- OKR_SEASON: Q1 2026 -->
<!-- OKR_YEAR: 2026 -->
<!-- OKR_START: 2026-01-01 -->
<!-- OKR_END: 2026-03-31 -->

## 🐸1 发布系统重构

<!-- OKR_META
priority: 🐸1
title: 发布系统重构
objective: 完成发布系统 v2 上线，提升发布效率和稳定性
owner: wanghaidong
start_date: 2026-01-01
end_date: 2026-03-31
status: in_progress
progress: 60%
-->

**目标**：完成发布系统 v2 上线，提升发布效率和稳定性

**关键结果**：
- 覆盖 100% 服务的发布流程
- 发布时间降低 50%
- 零故障上线率达到 99.9%

**负责人**：wanghaidong  
**开始日期**：2026-01-01  
**截止日期**：2026-03-31  
**状态**：进行中  
**进度**：60%  
**备注**：当前完成了权限控制和通知模块，正在做性能优化

---

## 🐸2 稳定性提升

<!-- OKR_META
priority: 🐸2
title: 稳定性提升
objective: 降低 P0 故障率，提升系统可靠性
owner: team-stability
start_date: 2026-01-01
end_date: 2026-03-31
status: in_progress
progress: 40%
-->

**目标**：降低 P0 故障率，提升系统可靠性

**关键结果**：
- P0 故障率降低 50%
- 建立完整的监控告警体系
- 故障恢复时间 < 5 分钟

**负责人**：team-stability  
**开始日期**：2026-01-01  
**截止日期**：2026-03-31  
**状态**：进行中  
**进度**：40%  
**备注**：监控体系已搭建，正在优化告警规则

---

## 🐸3 团队效能

<!-- OKR_META
priority: 🐸3
title: 团队效能
objective: 完成新人 onboarding 体系搭建
owner: hr-team
start_date: 2026-01-01
end_date: 2026-03-31
status: planned
progress: 0%
-->

**目标**：完成新人 onboarding 体系搭建

**关键结果**：
- 编写完整的 onboarding 文档
- 新人上手时间从 2 周降低到 1 周
- 建立 mentor 制度

**负责人**：hr-team  
**开始日期**：2026-01-01  
**截止日期**：2026-03-31  
**状态**：计划中  
**进度**：0%  
**备注**：计划 2 月开始

---

## 使用说明

### 如何维护这个文件

1. **季度初**：复制此模板到 `{year}/Q{quarter}/okr.md`
2. **填写内容**：
   - 修改 `<!-- OKR_SEASON -->` 等顶部注释
   - 修改每个 OKR 的 `<!-- OKR_META -->` 注释
   - 修改 Markdown 部分的内容（目标、关键结果、备注等）
3. **季度中期**：更新 `progress`、`status`、`备注` 字段
4. **提交 Git**：每次修改后提交，Git 历史自动记录演变

### 字段说明

| 字段 | 说明 | 示例 |
|:---|:---|:---|
| `priority` | 优先级（🐸1/🐸2/🐸3） | 🐸1 |
| `title` | KR 标题 | 发布系统重构 |
| `objective` | 目标描述 | 完成发布系统 v2 上线 |
| `owner` | 负责人 | wanghaidong |
| `start_date` | 开始日期 | 2026-01-01 |
| `end_date` | 截止日期 | 2026-03-31 |
| `status` | 状态 | planned / in_progress / completed / paused |
| `progress` | 进度百分比 | 60% |

### 注意事项

- ✅ 注释部分（`<!-- OKR_META ... -->`）必须保持格式一致，Skill 依赖此解析
- ✅ Markdown 部分可以自由调整，只要注释部分不变
- ✅ 每个 OKR 的 `title` 必须唯一，Skill 用它来匹配周报中的 KR
- ✅ 优先级必须是 🐸1、🐸2、🐸3，不支持其他格式
- ✅ 一个季度通常 3 个 OKR（三只青蛙），可以根据需要增减

### 示例：如何修改进度

```markdown
<!-- OKR_META
priority: 🐸1
title: 发布系统重构
objective: 完成发布系统 v2 上线，提升发布效率和稳定性
owner: wanghaidong
start_date: 2026-01-01
end_date: 2026-03-31
status: in_progress
progress: 75%  ← 从 60% 改为 75%
-->

**备注**：完成了性能优化，正在做灰度发布测试  ← 更新备注
```

---

## 常见问题

**Q: 如果中途需要调整 OKR 怎么办？**  
A: 直接编辑此文件，修改相关字段，提交 Git。Git 历史会记录所有变化。

**Q: 如果某个 OKR 没有完成怎么办？**  
A: 在季度末将 `status` 改为 `paused` 或 `completed`，在下一季度的 OKR 中继续跟进。

**Q: 可以有超过 3 个 OKR 吗？**  
A: 可以，但建议不超过 5 个。三只青蛙（🐸1/🐸2/🐸3）是最重要的，其他可以用 4️⃣5️⃣ 等标记。

**Q: 周报中提到的 KR 不在 OKR 中怎么办？**  
A: Skill 会标记为 `❓ 未知 KR`，提示你确认是否需要添加到 OKR 中。
