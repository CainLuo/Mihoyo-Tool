# Widget 自动刷新设计

## 一、架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                        主应用进程 (UIAbility)                      │
│                                                                   │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │ EntryAbility    │    │ WidgetDataStore │    │ Repository   │ │
│  │                 │    │ Builder         │    │              │ │
│  │ onNewWant()     │───▶│ refreshAndSave()│───▶│ syncDailyNote│ │
│  │                 │    │                 │    │              │ │
│  └─────────────────┘    └────────┬────────┘    └──────────────┘ │
│                                  │                               │
│                                  ▼                               │
│                    ┌─────────────────────────┐                   │
│                    │ WidgetUpdateNotifier    │                   │
│                    │                         │                   │
│                    │ notifyAllWidgets()      │                   │
│                    └────────────┬────────────┘                   │
│                                 │                                │
└─────────────────────────────────┼────────────────────────────────┘
                                  │ formProvider.updateForm()
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Widget 进程 (FormExtensionAbility)             │
│                                                                   │
│  ┌─────────────────┐    ┌─────────────────┐                      │
│  │ onUpdateForm()  │───▶│ loadSync()      │                      │
│  │                 │    │                 │                      │
│  │ 拉起主应用       │    │ 渲染 Widget     │                      │
│  └─────────────────┘    └─────────────────┘                      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 二、组件设计

### 2.1 WidgetUpdateNotifier

**职责**：遍历所有已安装的 Widget，主动推送更新

**位置**：`entry/src/main/ets/widget/utils/WidgetUpdateNotifier.ets`

```typescript
export class WidgetUpdateNotifier {
  /**
   * 通知所有已安装的 Widget 刷新
   * 
   * 流程：
   * 1. 从 WidgetFormIdStore 读取所有 formId
   * 2. 遍历每个 formId，调用 formProvider.updateForm()
   */
  static async notifyAllWidgets(): Promise<void>;
  
  /**
   * 通知指定 Widget 刷新
   */
  static async notifyWidget(formId: string): Promise<void>;
}
```

### 2.2 WidgetBackgroundSyncService

**职责**：在主应用进程中执行后台同步

**位置**：`entry/src/main/ets/widget/utils/WidgetBackgroundSyncService.ets`

```typescript
export class WidgetBackgroundSyncService {
  /**
   * 执行后台同步
   * 
   * 流程：
   * 1. 遍历所有账号的所有角色
   * 2. 调用 Repository.syncDailyNote() 同步便笺
   * 3. 调用 WidgetDataStoreBuilder.refreshAndSave()
   * 4. 调用 WidgetUpdateNotifier.notifyAllWidgets()
   */
  static async syncAllAndRefresh(context: common.UIAbilityContext): Promise<void>;
}
```

### 2.3 EntryFormAbility 修改

**修改点**：`onUpdateForm()` 不再只读取本地数据，而是拉起主应用同步

```typescript
onUpdateForm(formId: string): void {
  // 使用 postCardAction 拉起主应用
  // 参数: { action: 'refresh_widget', formId: formId }
  postCardAction(this, formId, {
    action: 'refresh_widget',
    formId: formId
  });
}
```

**约束**：
- `postCardAction()` 只能在 Widget 进程中调用
- 拉起主应用时，主应用会在后台运行（不会打开 UI）

### 2.4 EntryAbility 修改

**修改点**：新增 `onNewWant()` 处理后台刷新请求

```typescript
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  const action = want.parameters?.['action'] as string;
  
  if (action === 'refresh_widget') {
    // 后台刷新 Widget
    WidgetBackgroundSyncService.syncAllAndRefresh(this.context);
    return;
  }
  
  // 其他情况...
}
```

## 三、数据流

### 3.1 后台定时刷新

```
系统定时器 (每 1 小时)
    │
    ▼
FormExtensionAbility.onUpdateForm(formId)
    │
    ▼
postCardAction({ action: 'refresh_widget', formId })
    │
    ▼
UIAbility.onNewWant()
    │
    ▼
WidgetBackgroundSyncService.syncAllAndRefresh()
    │
    ├─▶ Repository.syncDailyNote() (遍历所有角色)
    │
    ├─▶ WidgetDataStoreBuilder.refreshAndSave()
    │
    └─▶ WidgetUpdateNotifier.notifyAllWidgets()
            │
            ▼
        formProvider.updateForm(formId)
            │
            ▼
        FormExtensionAbility.onUpdateForm() (渲染最新数据)
```

### 3.2 主应用联动更新

```
App 内数据同步完成
    │
    ▼
WidgetDataStoreBuilder.refreshAndSave()
    │
    ▼
WidgetUpdateNotifier.notifyAllWidgets()
    │
    ▼
formProvider.updateForm(formId) (遍历所有 Widget)
    │
    ▼
Widget 刷新显示最新数据
```

## 四、错误处理

### 4.1 后台同步失败

- 网络错误：不影响现有数据，下次同步重试
- Cookie 过期：不处理，等待用户打开 App 时重新登录
- 进程被杀：系统会在下次定时刷新时重新触发

### 4.2 推送更新失败

- Widget 已被删除：`formProvider.updateForm()` 会抛出错误，捕获后从 `WidgetFormIdStore` 移除该 formId
- 进程异常：不影响下次刷新

## 五、性能优化

### 5.1 后台同步频率

- 当前配置：`updateDuration: 1`（1 小时）
- 可根据用户习惯调整：
  - 高频用户：30 分钟
  - 低频用户：2 小时

### 5.2 增量同步

- 当前方案：全量同步所有角色的便笺
- 优化方向：只同步即将恢复满的角色（如树脂 > 150）

## 六、测试策略

### 6.1 单元测试

**WidgetUpdateNotifier.test.ets** (`entry/src/test/`)
- `notifyAllWidgets()` 遍历所有 formId
- `notifyWidget()` 调用 `formProvider.updateForm()`

**WidgetBackgroundSyncService.test.ets** (`entry/src/test/`)
- `syncAllAndRefresh()` 调用 Repository 同步
- 同步完成后调用 `refreshAndSave()`

### 6.2 设备端测试

**WidgetAutoRefreshTest.test.ets** (`entry/src/ohosTest/`)
- 后台刷新：模拟 `onUpdateForm()` 触发
- 联动刷新：App 内同步后 Widget 更新

## 七、注意事项

### 7.1 FormExtension 进程限制

- `onUpdateForm()` 必须在 **10 秒内**完成
- 不能调用异步网络请求
- 只能拉起主应用处理

### 7.2 主应用后台运行

- `onNewWant()` 拉起主应用时，主应用在后台运行
- 不会打开 UI，用户无感知
- 完成后主应用自动进入后台

### 7.3 多 Widget 场景

- 一个 App 可以有多个 Widget
- 每个 Widget 有独立的 formId
- 刷新时需要遍历所有 formId 逐一推送
