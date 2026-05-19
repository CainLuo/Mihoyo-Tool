# Widget 白屏问题排查记录

**日期**: 2025-05-13
**状态**: 已定位根因，待修复数据链路

---

## 一、问题现象

在桌面添加卡片时，所有 Widget（1x2、2x2、2x4、4x4）预览页面全部显示白屏。

---

## 二、排查过程

### 2.1 初步假设

根据官方文档「如何定位并解决卡片白屏展示的问题」：
> 一个卡片报错后会导致应用的所有卡片渲染全部挂掉成为白屏

因此排查方向是：找出哪个 Widget 组件有运行时错误。

### 2.2 排除法测试

在 `Widget2x2.ets` 中逐个测试 `WidgetCardContent` 的各个分支：

| 测试项 | 结果 |
|--------|------|
| `WidgetSlotRenderer` 单独使用 | ✅ 正常 |
| `WidgetCardContent`（空数据） | ✅ 正常 |
| `Widget4x4MultiGame` | ✅ 正常 |
| `WidgetMultiGameCompact` | ✅ 正常 |
| `WidgetCardContent` 单角色分支 | ✅ 正常 |
| `WidgetCardContent` 单游戏多角色分支 | ✅ 正常 |
| `WidgetCardContent` 多游戏分支 | ✅ 正常 |

**结论**: `WidgetCardContent` 组件本身没有问题，所有分支都能正常渲染。

### 2.3 硬编码数据测试

将 `Widget2x2.ets` 改为使用硬编码测试数据：

```typescript
private buildTestRoles(): ParsedRole[] {
  const roles: ParsedRole[] = [];
  
  // 原神角色
  const role1 = new ParsedRole();
  role1.roleId = '123456789';
  role1.nickname = '旅行者';
  role1.server = 'cn_gf01';
  role1.rawJson = '{"current_resin":140,"max_resin":160,"resin_recovery_time":"18000"}';
  role1.currentStamina = 140;
  role1.maxStamina = 160;
  role1.recoverySeconds = 18000;
  roles.push(role1);

  return roles;
}

build() {
  Column() {
    WidgetCardContent({
      cardSize: WidgetCardSize.SIZE_2x2,
      allRoles: this.buildTestRoles(),
      gameIds: [WIDGET_GAME_ID.GENSHIN],
      isSingleGame: true,
    })
  }
  // ...
}
```

**结果**: 桌面添加卡片预览正常显示。

### 2.4 根因确认

**问题根因**: `EntryFormAbility.onAddForm()` 返回的 `formBindingData` 中 payload 为空。

数据链路：
```
EntryFormAbility.onAddForm()
  → WidgetDataStoreManager.loadSync()
    → 返回空 WidgetDataStore
      → WidgetPayloadBuilder.buildPayload() 返回空 payload
        → @LocalStorageProp('payload') 收到空字符串
          → parsePayload('') 返回空 ParsedPayload
            → WidgetCardContent 收到空 allRoles
              → 显示空态占位（但实际是白屏，可能是空态占位也有问题）
```

---

## 三、已修复的问题

在排查过程中，修复了以下 ArkTS 严格模式兼容性问题：

### 3.1 `WidgetPayloadBuilder.ets`

**问题**: 使用 `Array.from(map.values())`

**修复**: 使用 `for` 循环手动转换

```typescript
// 错误
const result = Array.from(map.values());

// 正确
private static mapToArray(map: Map<string, WidgetAccountPayloadItem>): WidgetAccountPayloadItem[] {
  const result: WidgetAccountPayloadItem[] = [];
  const keys = WidgetPayloadBuilder.getMapKeys(map);
  for (let i = 0; i < keys.length; i++) {
    const value = map.get(keys[i]);
    if (value !== undefined) {
      result.push(value);
    }
  }
  return result;
}
```

### 3.2 `WidgetPayloadParser.ets`

**问题**: `getUniqueGameIds()` 使用 `Set<string>` 和 `Array.from()`

**修复**: 手动去重

```typescript
getUniqueGameIds(): string[] {
  const gameIds: string[] = [];
  for (let i = 0; i < this.accounts.length; i++) {
    const account = this.accounts[i];
    for (let j = 0; j < account.games.length; j++) {
      const gameId = account.games[j].gameId;
      // 手动去重
      let found = false;
      for (let k = 0; k < gameIds.length; k++) {
        if (gameIds[k] === gameId) {
          found = true;
          break;
        }
      }
      if (!found) {
        gameIds.push(gameId);
      }
    }
  }
  return gameIds;
}
```

### 3.3 `WidgetTheme.ets`

**问题**: 依赖 `DefaultTheme.makeFont()` 方法

**修复**: 创建纯数据类，使用数字常量替代 `makeFont()`

---

## 四、待修复问题

### 4.1 数据链路问题

**问题**: `WidgetDataStoreManager.loadSync()` 返回空数据

**已确认的根因分析**:

| 场景 | 数据来源 | 结果 |
|------|----------|------|
| 硬编码测试数据 | `this.buildTestRoles()` 直接构造 | ✅ 正常显示 |
| 原始版本 | `@LocalStorageProp('payload')` → `parsePayload()` | ❌ 白屏 |

**数据链路**:
```
主应用进程（EntryAbility.onCreate）
  → WidgetDataStoreBuilder.initAndSave()
    → WidgetDataStoreManager.save()
      → Preferences 文件（widget_data_store）

FormExtension 进程（EntryFormAbility.onAddForm）
  → WidgetDataStoreManager.loadSync()
    → Preferences 文件（widget_data_store）
      → 返回 WidgetDataStore
        → WidgetPayloadBuilder.buildPayload()
          → formBindingData.createFormBindingData({ payload: '...' })
            → @LocalStorageProp('payload') 接收
              → parsePayload() 解析
                → WidgetCardContent 渲染
```

**Preferences 文件名检查**（✅ 一致）:
| 文件 | Preferences 文件名 | 用途 |
|------|-------------------|------|
| `WidgetDataStoreManager.ets` | `widget_data_store` | 存储全局数据 |
| `WidgetConfigStore.ets` | `widget_configs` | 存储卡片配置 |
| `EntryFormAbility.ets` | `widget_prefs` | 未使用（遗留定义） |

**可能原因**（按可能性排序）:
1. **主应用进程未成功保存数据**：`WidgetDataStoreBuilder.initAndSave()` 调用失败
2. **数据为空**：DB 中没有账号或角色数据
3. **进程隔离导致数据不可见**：Preferences 在 FormExtension 进程中看不到主应用写入的数据

**验证方法**:
1. 查看 hilog 日志，确认 `[WIDGET_DEBUG]` 标签的日志输出：
   - `buildFromDB: found X accounts` — 确认 DB 有数据
   - `save: payload json length=X` — 确认数据保存成功
   - `loadSync: payload json length=X` — 确认数据读取成功
2. 在 `EntryFormAbility.onAddForm()` 打印 `dataStore.accounts.length`
3. 检查 `payloadStr.length` 是否为 0

**修复方案**:
1. 如果 DB 无数据 → 需要先登录账号并同步数据
2. 如果 `loadSync` 返回空 → 检查 Preferences 是否正确初始化
3. 如果 payload 为空 → 返回默认占位数据而非空字符串

### 4.2 Widget 页面文件状态

当前 `Widget2x2.ets` 使用硬编码测试数据，需要恢复为使用 `@LocalStorageProp('payload')` 接收真实数据：

```typescript
// 当前（测试版本）
WidgetCardContent({
  cardSize: WidgetCardSize.SIZE_2x2,
  allRoles: this.buildTestRoles(),  // 硬编码
  gameIds: [WIDGET_GAME_ID.GENSHIN],
  isSingleGame: false,
})

// 最终版本
WidgetCardContent({ 
  cardSize: WidgetCardSize.SIZE_2x2,
  allRoles: this.parsed.getAllRoles(),  // 从 payload 解析
  gameIds: this.parsed.getUniqueGameIds(),
  isSingleGame: this.parsed.isSingleGame,
})
```

---

## 五、关键约束（来自官方文档）

1. **FormExtensionAbility 不能导入 HSP 模块**（core 是 HSP）
2. **FormExtension 进程与主应用进程内存隔离**
3. **数据共享只能通过 Preferences 传递**
4. **Widget 使用 `@Component`（V1 体系），不支持 `@ComponentV2`**
5. **ArkTS 严格模式禁止 `Array.from()`、`Set`、`Map.keys()` 迭代器**

---

## 六、最终结论

### 根因确认

**问题**：`@LocalStorageProp('payload')` 收到空字符串，导致 `parsePayload('')` 返回空数据，Widget 渲染空态时白屏。

**数据链路验证**（需通过 hilog 确认）：

| 步骤 | 检查点 | hilog 关键词 |
|------|--------|-------------|
| 1 | 主应用 DB 有账号数据 | `buildFromDB: found X accounts` |
| 2 | 数据成功保存到 Preferences | `save: payload json length=X` |
| 3 | loadSync 读取到数据 | `loadSync: payload json length=X` |
| 4 | payload 传递给 Widget | `returning real data, payload len=X` |

### 修复方案

**方案 A：确认数据存在**
1. 运行 App，确保已登录账号并同步数据
2. 查看 hilog 确认 `[WIDGET_DEBUG]` 日志输出
3. 确认 `buildFromDB` 和 `save` 都成功

**方案 B：恢复原始代码并添加调试日志**
1. 将 `Widget2x2.ets` 恢复为使用 `@LocalStorageProp`
2. 在 `build()` 中添加空态占位（payload 为空时显示提示）
3. 添加 hilog 打印 `payloadJson.length`

**方案 C：兜底处理**
1. 如果 `payloadJson` 为空，显示"请先登录"占位
2. 确保 Widget 不会因为空数据而白屏

---

## 六、文件清单

### 已修改文件

| 文件 | 修改内容 |
|------|----------|
| `entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets` | 移除 `Array.from()` |
| `entry/src/main/ets/widget/utils/WidgetPayloadParser.ets` | 移除 `Set` 和 `Array.from()` |
| `entry/src/main/ets/widget/utils/WidgetTheme.ets` | 创建纯数据类 |
| `entry/src/main/ets/widget/utils/WidgetLog.ets` | 新增，使用 hilog |
| `entry/src/main/ets/widget/utils/WidgetGameId.ets` | 新增，Widget 专用 GameId 枚举 |
| `entry/src/main/ets/widget/pages/Widget2x2.ets` | 当前使用硬编码测试数据 |

### 待检查文件

| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/widget/utils/WidgetDataStoreManager.ets` | 数据存储管理器 |
| `entry/src/main/ets/entryformability/EntryFormAbility.ets` | Widget 生命周期 |
| `entry/src/main/ets/widget/models/WidgetDataStore.ets` | 数据模型 |
