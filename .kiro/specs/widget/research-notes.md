# Widget 黑屏问题调研报告

调研日期：2026-05-11
调研目的：排查 Widget 黑屏问题的根本原因及解决方案

---

## 一、问题现象

Widget 添加到桌面后显示黑屏，但日志显示数据已正确保存到 Preferences。

---

## 二、关键发现（来自官方文档）

### 2.1 FormExtensionAbility 进程生命周期限制

> **来源**：[管理ArkTS卡片生命周期（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle)
>
> **原文**：FormExtensionAbility 进程不能常驻后台，即在卡片生命周期回调函数中无法处理长时间的任务，在生命周期调度完成后会继续存在 **10 秒**，若在 10 秒内未收到新的生命周期回调，则进程将自动退出。

**影响**：
- `onAddForm()` 返回后，FormExtension 进程只有 10 秒存活时间
- 如果异步操作（如 `saveConfigAndUpdate()`）未在 10 秒内完成，进程会被杀掉
- 进程被杀后，异步回调中的 `formProvider.updateForm()` 不会执行

### 2.2 设备重启后数据不一致问题

> **来源**：[卡片数据同步异常（官方）](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c80-0000002411768157)
>
> **原文**：卡片框架在重启时是使用 `onAddForm()` 回调方法的返回值，若应用重启前调用 `updateForm()` 更新的数据和 `onAddForm()` 方法返回的数据不一致，会导致设备重启前后卡片数据不一致的现象。

**修改建议**：
> 需要对数据做持久化处理。例如使用关系型数据库存储卡片最新数据，在 FormExtensionAbility 的 `onAddForm()` 生命周期回调中，获取数据库中的最新数据后，使用 `updateForm()` 方法更新卡片。

**关键结论**：
- `onAddForm()` 返回的数据是卡片初始化显示的数据
- 必须在 `onAddForm()` 中**同步**读取并返回真实数据
- 不能依赖异步 `updateForm()` 来更新初始数据

### 2.3 卡片数据传递限制

> **来源**：[ArkTS卡片页面刷新概述（官方）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)
>
> **原文**：由于卡片提供方和卡片为相互独立的进程，两者间的数据共享**只能通过 `LocalStorageProp` 传递**，不能使用 getContext 方法。且接收数据时，**卡片数据会被转换成 string 类型**。

**影响**：
- 传给卡片的数字会变成字符串 `"160"`
- 需要在卡片 UI 里用 `parseInt()` 或 `Number()` 转换

---

## 三、当前代码问题分析

### 3.1 `EntryFormAbility.onAddForm()` 问题

```typescript
onAddForm(want: Want): formBindingData.FormBindingData {
  // ...
  
  // 异步保存配置并更新卡片
  this.saveConfigAndUpdate(formId, config);  // ❌ 异步调用，可能不执行

  // 立即返回占位数据（稍后异步更新）
  hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] returning placeholder data`);
  return this.createPlaceholderData(config);  // ❌ 返回空数据 `{"version":1,"updatedAt":0,"accounts":[]}`
}
```

**问题**：
1. `onAddForm()` 返回的是占位数据 `{"version":1,"updatedAt":0,"accounts":[]}`
2. 异步调用 `saveConfigAndUpdate()` 可能在 FormExtension 进程被杀掉前未完成
3. 即使完成，`formProvider.updateForm()` 也可能因为进程被杀而未执行

### 3.2 `createPlaceholderData()` 问题

```typescript
private createPlaceholderData(config: WidgetConfig): formBindingData.FormBindingData {
  const data: Record<string, string> = {};
  // 返回空 payload，卡片会显示默认 UI
  data['payload'] = '{"version":1,"updatedAt":0,"accounts":[]}';
  return formBindingData.createFormBindingData(data);
}
```

**问题**：
- 返回的是空 payload（`accounts: []`）
- 如果 Widget 组件没有正确处理空数据，会显示黑屏

---

## 四、解决方案

### 方案 A：使用同步 API 读取 Preferences（推荐）

**原理**：
- Preferences API 10+ 提供同步方法：`getPreferencesSync()`、`getSync()`、`getAllSync()`
- 在 `onAddForm()` 中**同步**读取 Preferences 并返回真实数据

**代码修改**：

```typescript
onAddForm(want: Want): formBindingData.FormBindingData {
  const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
  const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '';
  const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number ?? 2;
  const widgetConfigRaw = want.parameters?.['widgetConfig'] as string ?? '';

  hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] onAddForm: formId=${formId} formName=${formName} dimension=${dimension}`);

  // 解析配置
  let config: WidgetConfig | null = null;
  if (widgetConfigRaw.length > 0) {
    config = WidgetConfig.fromJson(widgetConfigRaw);
    config.formId = formId;
    config.formName = formName;
  }

  if (config === null) {
    config = new WidgetConfig();
    config.formId = formId;
    config.formName = formName;
    config.size = this.dimensionToSize(dimension);
    config.slots = [];
  }

  // ✅ 同步读取数据并返回
  try {
    // 同步初始化 Preferences
    const prefs = preferences.getPreferencesSync(this.context, PREFS_NAME);
    const json = prefs.getSync(KEY_GLOBAL_DATA, '') as string;
    
    if (json.length > 0) {
      const dataStore = WidgetDataStore.fromJson(json);
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();
      
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] returning real data, accounts=${dataStore.accounts.length}`);
      return formBindingData.createFormBindingData(record);
    }
  } catch (e) {
    hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] sync read failed: ${JSON.stringify(e)}`);
  }

  // 异步保存配置（用于后续刷新）
  this.saveConfigAsync(formId, config);

  // 返回空数据（兜底）
  return this.createPlaceholderData(config);
}
```

### 方案 B：确保空数据也能正确渲染

**原理**：
- 确保 Widget 组件能正确处理 `accounts: []` 的情况
- 显示"暂无数据"占位 UI，而不是黑屏

**修改 Widget 组件**：

```typescript
// Widget2x2.ets / Widget4x4.ets
build() {
  Column() {
    if (this.parsedPayload.accounts.length === 0) {
      // 显示占位 UI
      Column() {
        Text('暂无数据')
          .fontSize(12)
          .fontColor($r('app.color.colorTextSecondary'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      // 正常渲染
      // ...
    }
  }
  .width('100%')
  .height('100%')
}
```

### 方案 C：组合使用（最佳实践）

1. **同步返回真实数据**（方案 A）
2. **同时确保空数据能渲染**（方案 B）
3. **异步保存配置**用于后续刷新

---

## 五、Preferences 同步 API 参考

> **来源**：[@ohos.data.preferences API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-preferences)

### 可用的同步方法（API 10+）

| 方法 | 说明 | 可用版本 |
|-----|------|---------|
| `preferences.getPreferencesSync(context, name)` | 同步获取 Preferences 实例 | API 10+ |
| `prefs.getSync(key, defaultValue)` | 同步读取数据 | API 10+ |
| `prefs.getAllSync()` | 同步获取所有数据 | API 10+ |
| `prefs.putSync(key, value)` | 同步写入数据 | API 10+ |
| `prefs.hasSync(key)` | 同步检查 key 是否存在 | API 10+ |
| `prefs.deleteSync(key)` | 同步删除数据 | API 10+ |
| `prefs.flushSync()` | 同步刷新到磁盘 | API 14+ |
| `prefs.clearSync()` | 同步清空数据 | API 10+ |

### 使用示例

```typescript
import { preferences } from '@kit.ArkData';

// 同步获取 Preferences 实例
const prefs = preferences.getPreferencesSync(context, 'widget_data_store');

// 同步读取数据
const json = prefs.getSync('global_data', '') as string;

// 同步写入数据
prefs.putSync('global_data', jsonString);
prefs.flush(); // 异步刷新（或用 flushSync 在 API 14+）
```

---

## 六、注意事项

### 6.1 Preferences 多进程安全

> **来源**：Preferences API 文档
>
> **原文**：首选项无法保证进程并发安全，会有文件损坏和数据丢失的风险，**不支持在多进程场景下使用**。

**影响**：
- 主应用进程（UIAbility）和 FormExtension 进程共享同一份 Preferences 文件
- 理论上存在并发写入风险
- 对于本项目：主应用写入，FormExtension 只读取，风险可控

### 6.2 FormExtension 不能导入 HSP 模块

> **来源**：FormKit-Notes.md 第 12.15 节
>
> **原文**：ArkTS 卡片可以导入 HAR，但**不能导入 HSP**。本项目的 `core` 模块是 HSP，卡片代码不能直接 import core 模块的任何内容。

**影响**：
- `EntryFormAbility.ets` 不能导入 core 模块
- 数据读取逻辑必须在 entry 模块内实现
- Parser、数据模型等需要复制或重新实现

### 6.3 FormExtension 不能导入的模块

> **来源**：FormKit-Notes.md 第 12.9 节
>
> **原文**：`FormExtensionAbility` **不支持**加载以下模块，强行导入会导致 JS crash：
> - `particleAbility`
> - `audio`
> - `camera`
> - `media`
> - `backgroundTaskManager`

**影响**：
- 确保导入链中不包含这些模块

---

## 七、验证步骤

### 7.1 日志验证

使用 `./export-widget-logs.sh` 导出日志，检查：

1. `onAddForm` 返回的真实数据结构
2. Preferences 同步读取是否成功
3. payload 内容是否正确

### 7.2 功能验证

1. 添加 Widget 到桌面
2. 检查是否立即显示真实数据（不是黑屏）
3. 重启设备，检查 Widget 数据是否一致

---

## 八、参考资料

### 官方文档

1. [管理ArkTS卡片生命周期](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-lifecycle)
2. [卡片数据同步异常](https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c80-0000002411768157)
3. [ArkTS卡片页面刷新概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-interaction-overview)
4. [@ohos.data.preferences API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-data-preferences)
5. [ArkTS卡片进程模型](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-process)
6. [ArkTS卡片适配常见问题](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-adapt-faq)

### 本地文档

1. `design/research/FormKit-Notes.md` - FormKit 技术调研笔记（30 节内容）
2. `.kiro/specs/widget/design.md` - Widget 多账号混合显示设计文档
