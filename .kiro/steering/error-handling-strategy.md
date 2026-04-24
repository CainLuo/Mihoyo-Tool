---
inclusion: manual
---

# 错误处理与用户反馈策略

## 核心原则

1. **日志必须记录**：所有场景、所有错误类型，无论是否展示 UI，都必须写日志
2. **打扰程度匹配严重程度**：需要用户操作才能解决的错误用 Dialog，其余用 Snackbar 或静默
3. **自动触发 ≠ 用户关心**：后台自动同步失败是常态，不应打断用户

---

## 错误分级与处理方式

| 错误类型                     | 触发来源                       | 日志级别 | UI 反馈                        |
| ---------------------------- | ------------------------------ | -------- | ------------------------------ |
| Cookie 过期（-100 / 10001）  | 任何                           | warn     | Dialog（需要用户重新登录）     |
| Geetest 验证（1034 / 10035） | 任何                           | warn     | Dialog（需要用户完成验证）     |
| 网络/服务器错误              | Home 冷启动自动同步            | error    | 静默（只记日志）               |
| 网络/服务器错误              | Home 30 分钟自动刷新           | error    | 静默（只记日志）               |
| 网络/服务器错误              | Home 手动点刷新按钮            | error    | Snackbar（轻量提示，自动消失） |
| 网络/服务器错误              | Characters 进入页面 / 手动刷新 | error    | Snackbar                       |
| 网络/服务器错误              | 角色详情页（原神/星铁/绝区零） | error    | Snackbar                       |

---

## 实现要点

### HomeViewModel

- 新增 `isAutoSync: boolean` 标志，区分自动/手动触发
- `loadData()` 和 `startAutoRefresh()` 里设置 `isAutoSync = true`
- `refresh()` 和 `forceRefresh()` 里设置 `isAutoSync = false`
- `syncDailyNote` 的 else 分支：
  - `isAutoSync = true` → 只记日志，不设置 `networkErrorMsg`
  - `isAutoSync = false` → 记日志 + 触发 Snackbar

### CharactersViewModel

- 所有 API 错误（非 Cookie/Geetest）→ 记日志 + 触发 Snackbar

### 角色详情 ViewModel（Genshin / StarRail / ZZZ）

- 所有 API 错误（非 Cookie/Geetest）→ 记日志 + 触发 Snackbar

### UI 反馈实现

- **Dialog**：保持现有 `promptAction.showDialog`，用于 Cookie 过期和 Geetest
- **Snackbar**：使用项目现有的 `showFeedback(ctx, FeedbackType.ERROR, message)`，替换原来的 `networkErrorMsg` Dialog
- **静默**：只调用 `Logger.error()`，不设置任何 UI 状态

---

## 变更记录

| 日期       | 变更内容                                      |
| ---------- | --------------------------------------------- |
| 2026-04-25 | 初版策略确定，替换原有"所有错误弹 Dialog"方案 |
