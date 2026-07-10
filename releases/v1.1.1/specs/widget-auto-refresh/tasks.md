# Widget 自动刷新任务清单

## 阶段 1：主应用联动更新（简单优先）

### 任务 1.1：创建 WidgetUpdateNotifier

**文件**：`entry/src/main/ets/widget/utils/WidgetUpdateNotifier.ets`

**内容**：
- `notifyAllWidgets()` — 遍历所有 formId，调用 `formProvider.updateForm()`
- `notifyWidget(formId)` — 推送单个 Widget 更新
- 从 `WidgetFormIdStore` 读取所有已安装的 formId

**依赖**：
- `WidgetFormIdStore.ets`（已存在）
- `formProvider` API

**验收**：
- `notifyAllWidgets()` 被调用时，所有 Widget 刷新显示最新数据

---

### 任务 1.2：修改 WidgetDataStoreBuilder

**文件**：`entry/src/main/ets/widget/utils/WidgetDataStoreBuilder.ets`

**修改**：
- 在 `refreshAndSave()` 成功后，调用 `WidgetUpdateNotifier.notifyAllWidgets()`
- 添加可选参数 `pushUpdate: boolean = true`

**验收**：
- `refreshAndSave()` 后 Widget 自动刷新

---

### 任务 1.3：更新 StaminaNotificationService

**文件**：`entry/src/main/ets/notification/StaminaNotificationService.ets`

**修改**：
- `onDailyNotesSynced()` 中 `refreshAndSave()` 后确保调用 `WidgetUpdateNotifier.notifyAllWidgets()`

**验收**：
- 体力满额通知触发同步后，Widget 更新

---

## 阶段 2：后台定时刷新

### 任务 2.1：创建 WidgetBackgroundSyncService

**文件**：`entry/src/main/ets/widget/utils/WidgetBackgroundSyncService.ets`

**内容**：
- `syncAllAndRefresh(context)` — 遍历所有账号角色，同步便笺数据
- 调用 `Repository.syncDailyNote()`（需要处理 Cookie 过期）
- 同步完成后调用 `refreshAndSave()` 和 `notifyAllWidgets()`

**约束**：
- 不能使用 `GeetestService`（后台无法弹出验证）
- Cookie 过期时静默失败

**验收**：
- 后台同步成功后 Widget 显示最新数据

---

### 任务 2.2：修改 EntryFormAbility.onUpdateForm()

**文件**：`entry/src/main/ets/entryformability/EntryFormAbility.ets`

**修改**：
- `onUpdateForm()` 使用 `postCardAction()` 拉起主应用
- 传递参数 `{ action: 'refresh_widget', formId }`

**约束**：
- `postCardAction()` 只能在 Widget 进程调用
- 拉起主应用不会打开 UI

**验收**：
- 系统定时触发 `onUpdateForm()` 后，主应用执行同步

---

### 任务 2.3：修改 EntryAbility.onNewWant()

**文件**：`entry/src/main/ets/entryability/EntryAbility.ets`

**修改**：
- 新增 `onNewWant()` 方法
- 检查参数 `action === 'refresh_widget'`
- 调用 `WidgetBackgroundSyncService.syncAllAndRefresh()`

**验收**：
- 主应用收到后台刷新请求后执行同步

---

### 任务 2.4：处理 formProvider.updateForm() 错误

**文件**：`entry/src/main/ets/widget/utils/WidgetUpdateNotifier.ets`

**修改**：
- 捕获 `updateForm()` 抛出的错误
- 如果 Widget 已删除，从 `WidgetFormIdStore` 移除 formId

**验收**：
- 删除 Widget 后，下次刷新不会报错

---

## 阶段 3：测试

### 任务 3.1：单元测试

**文件**：
- `entry/src/test/WidgetUpdateNotifier.test.ets`
- `entry/src/test/WidgetBackgroundSyncService.test.ets`

**内容**：
- `WidgetUpdateNotifier.notifyAllWidgets()` 遍历 formId
- `WidgetBackgroundSyncService.syncAllAndRefresh()` 调用 Repository

**验收**：
- 测试通过

---

### 任务 3.2：设备端测试

**文件**：`entry/src/ohosTest/ets/test/WidgetAutoRefreshTest.test.ets`

**内容**：
- 后台刷新测试（模拟 `onUpdateForm()` 触发）
- 联动刷新测试（App 内同步后 Widget 更新）

**验收**：
- 测试通过

---

## 执行顺序

```
阶段 1 (联动更新)
    │
    ├─▶ 1.1 WidgetUpdateNotifier
    │
    ├─▶ 1.2 WidgetDataStoreBuilder
    │
    └─▶ 1.3 StaminaNotificationService
    
阶段 2 (后台刷新)
    │
    ├─▶ 2.1 WidgetBackgroundSyncService
    │
    ├─▶ 2.2 EntryFormAbility.onUpdateForm()
    │
    ├─▶ 2.3 EntryAbility.onNewWant()
    │
    └─▶ 2.4 错误处理
    
阶段 3 (测试)
    │
    ├─▶ 3.1 单元测试
    │
    └─▶ 3.2 设备端测试
```
