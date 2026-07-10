# Widget 自动刷新需求

## 一、背景

当前 Widget 只在以下情况更新数据：
1. App 启动时调用 `WidgetDataStoreBuilder.initAndSave()`
2. 数据同步完成后调用 `WidgetDataStoreBuilder.refreshAndSave()`

**问题**：如果用户不打开 App，Widget 数据永远不会更新。

## 二、需求

### 需求 1：后台定时刷新

**描述**：App 不打开时，Widget 自动调用 API 刷新数据

**触发条件**：
- 系统定时调用 `FormExtensionAbility.onUpdateForm()`
- 当前配置 `updateDuration: 1`，即每 **1 小时**触发一次

**约束**：
- `FormExtensionAbility` 不能导入 HSP 模块（core 是 HSP）
- `FormExtensionAbility` 进程只有 **10 秒**存活时间
- 不能直接调用 `Repository.syncDailyNote()`

**解决方案**：
- `onUpdateForm()` 通过 `postCardAction()` 拉起主应用 `UIAbility`
- 主应用 `UIAbility` 收到请求后调用 API 同步数据
- 数据同步完成后调用 `WidgetDataStoreBuilder.refreshAndSave()`
- 通过 `formProvider.updateForm()` 推送更新到 Widget

### 需求 2：主应用联动更新

**描述**：App 打开并更新数据时，Widget 同步刷新

**当前状态**：
- ✅ `SyncQueueRunner.registerOnComplete()` 已注册 → 调用 `refreshAndSave()`
- ✅ `StaminaNotificationService.onDailyNotesSynced()` 已调用 `refreshAndSave()`

**需要补充**：
- `refreshAndSave()` 后需要主动调用 `formProvider.updateForm()` 推送到所有 Widget

## 三、验收标准

### 后台定时刷新

1. Widget 添加到桌面后，每 1 小时自动刷新一次数据
2. 刷新时调用真实 API（非 mock）
3. 刷新失败不影响现有数据显示
4. 刷新成功后 Widget 立即更新

### 主应用联动更新

1. App 内手动刷新 → Widget 立即更新
2. App 内自动同步 → Widget 立即更新
3. 体力满额通知触发同步 → Widget 立即更新

## 四、技术方案

### 4.1 后台定时刷新流程

```
FormExtensionAbility.onUpdateForm(formId)
    │
    ├─ 从 Preferences 读取现有数据
    │
    └─ postCardAction() 拉起 UIAbility
           │
           └─ UIAbility.onNewWant()
                  │
                  ├─ 检查参数 action='refresh_widget'
                  │
                  ├─ 调用 API 同步数据
                  │
                  ├─ WidgetDataStoreBuilder.refreshAndSave()
                  │
                  └─ formProvider.updateForm(formId)
```

### 4.2 主应用联动更新流程

```
数据同步完成
    │
    ├─ WidgetDataStoreBuilder.refreshAndSave()
    │
    └─ WidgetUpdateNotifier.notifyAllWidgets()
           │
           └─ 遍历所有 formId
                  │
                  └─ formProvider.updateForm(formId)
```

## 五、影响范围

### 新增文件

1. `entry/src/main/ets/widget/utils/WidgetUpdateNotifier.ets` — 主动推送更新到所有 Widget
2. `entry/src/main/ets/widget/utils/WidgetBackgroundSyncService.ets` — 后台同步服务

### 修改文件

1. `EntryFormAbility.ets` — `onUpdateForm()` 拉起主应用
2. `EntryAbility.ets` — `onNewWant()` 处理后台刷新请求
3. `WidgetDataStoreBuilder.ets` — 添加 `refreshAndPushUpdate()` 方法
4. `StaminaNotificationService.ets` — 调用 `WidgetUpdateNotifier.notifyAllWidgets()`

### 配置修改

1. `form_config.json` — `updateDuration` 保持 1（1 小时刷新间隔）
