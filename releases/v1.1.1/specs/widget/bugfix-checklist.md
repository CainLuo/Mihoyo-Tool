# Widget 黑屏问题修复清单

创建时间：2026-05-11
最后更新：2026-05-11 22:30
状态：**编译通过，待运行时验证**

---

## 问题分析历程

### 第一阶段：错误假设 LocalStorage 实例隔离

**最初假设**：Widget 页面创建 `new LocalStorage()` 会导致数据隔离，应该使用 `@Entry` 不传参数。

**修正**：用户找到官方示例 [CardInfoRefresh](https://gitee.com/harmonyos_samples/CardInfoRefresh/blob/master/entry/src/main/ets/widget/pages/WidgetCard.ets)，证明 Widget 必须使用 `let storage = new LocalStorage();` 和 `@Entry(storage)`。

**官方示例代码**：
```typescript
let storageLocal = new LocalStorage();

@Entry(storageLocal)
@Component
struct WidgetCard {
  @LocalStorageProp('formTime') formTime: string = '';
  @LocalStorageProp('formId') formId: string = '';
  @LocalStorageProp('cardList') cardList: Array<CardListItemData> = [];
}
```

### 第二阶段：真正的根因分析

**数据流对比**：

| 项目 | 官方示例 | 本项目 |
|------|---------|--------|
| FormExtensionAbility 返回 | `formBindingData.createFormBindingData(formData)` | `formBindingData.createFormBindingData(record)` |
| 数据结构 | `FormData` 对象（字段：formId、formTime、cardList） | `Record<string, string>`（单一 payload 字段） |
| Widget 接收方式 | `@LocalStorageProp('formTime')`、`@LocalStorageProp('cardList')` | `@LocalStorageProp('payload')` |

**关键发现**：
- `createFormBindingData()` 可以接受对象或 Record
- 对象的字段会自动注入到 Widget 的 LocalStorage
- 我们的实现传递 `{ payload: '...' }` 是正确的

**可能的问题点**：
1. ✅ `onAddForm()` 使用同步 API 读取 Preferences（已修复）
2. ⏳ Preferences 中可能没有数据（需要验证）
3. ⏳ `payload` JSON 格式问题（需要验证）

---

## 已完成的修复

### 任务 1：添加同步 API 到 `WidgetDataStoreManager`

**文件**：`entry/src/main/ets/widget/utils/WidgetDataStoreManager.ets`

- [x] 添加 `loadSync()` 静态方法
- [x] 添加 `initSync()` 静态方法
- [x] 修复 `getPreferencesSync()` 参数签名（使用 Options 对象）

### 任务 2：修改 `onAddForm()` 使用同步 API

**文件**：`entry/src/main/ets/entryformability/EntryFormAbility.ets`

- [x] 调用 `WidgetDataStoreManager.loadSync(this.context)` 同步读取数据
- [x] 返回真实数据（即使 `accounts: []`）

### 任务 3：修复 Widget 页面 LocalStorage 写法

**文件**：
- `entry/src/main/ets/widget/pages/Widget2x2.ets` ✅
- `entry/src/main/ets/widget/pages/Widget2x4.ets` ✅
- `entry/src/main/ets/widget/pages/Widget4x4.ets` ✅
- `entry/src/main/ets/widget/pages/Widget1x2Genshin.ets` ✅
- `entry/src/main/ets/widget/pages/Widget1x2StarRail.ets` ✅
- `entry/src/main/ets/widget/pages/Widget1x2ZZZ.ets` ✅

**修改内容**：
- [x] 添加 `let storage: LocalStorage = new LocalStorage();`
- [x] 将 `@Entry` 改为 `@Entry(storage)`
- [x] 消除编译警告

---

## 验证任务

### 编译验证 ✅

```
> hvigor BUILD SUCCESSFUL in 7 s 67 ms
```

**警告状态**：无 `@Entry should have a parameter` 警告

### 运行时验证 ⏳

**测试场景**：

1. **无账号时添加 Widget**
   - [ ] 删除 App
   - [ ] 不登录，直接在桌面添加 Widget 卡片
   - [ ] 预期：Widget 显示占位文字"请在应用内添加账号"（不是黑屏）

2. **有账号时添加 Widget**
   - [ ] 登录成功后添加 Widget
   - [ ] 预期：Widget 显示真实体力数据

3. **设备重启后**
   - [ ] 重启设备
   - [ ] 预期：Widget 数据正确显示（不是空数据）

---

## 待验证问题

### 问题 1：Preferences 中是否有数据？

**检查方法**：在 `onAddForm()` 中打印日志，查看 `loadSync()` 返回的 `accounts.length`

**可能原因**：
- 主应用没有调用 `WidgetDataStoreManager.save()` 保存数据
- 数据保存到了不同的 Preferences 文件

### 问题 2：payload 格式是否正确？

**检查方法**：在 `onAddForm()` 中打印 `payload` JSON 内容

**可能原因**：
- JSON 序列化失败
- 字段名不匹配

---

## 验证记录

| 日期 | 任务 | 结果 | 备注 |
|------|------|------|------|
| 2026-05-11 | 编译验证 | ✅ 通过 | 无警告 |
| 2026-05-11 | 运行验证 | ⏳ 待测试 | 需在 Windows 电脑上验证 |

---

## 相关文档

- `.kiro/specs/widget/research-notes.md` — 完整调研报告
- `design/research/FormKit-Notes.md` — FormKit 技术笔记（第 14-16 节）
- `.kiro/steering/04-harmonyos-api.md` — 新增文档查询多模式重试规则

---

## 官方参考

- [CardInfoRefresh 示例](https://gitee.com/harmonyos_samples/CardInfoRefresh) — Widget 最佳实践
- [FormKit 开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-formextensionability) — 卡片开发文档
