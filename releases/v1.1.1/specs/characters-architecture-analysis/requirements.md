# Characters 模块架构分析需求文档

## 背景

Home 模块检查完成后，继续检查 Characters 模块，发现违反编码规范的问题：

**`CharacterCard.ets` 中存在 6 个内联 `@Builder` 方法**：
- `genshinTopLeft()` — 原神左上角元素图标
- `starrailTopLeft()` — 星铁左上角属性+命途图标
- `zzzTopLeft()` — 绝区零左上角稀有度+属性+特性图标
- `genshinBottomBar()` — 原神底部等级+好感度
- `starrailBottomBar()` — 星铁底部等级
- `zzzBottomBar()` — 绝区零底部等级+阵营图标

## 规范引用

根据 `03-coding-standards.md` 第五节：

> **禁止**在 page 或 component 文件中用 `@Builder` 函数替代独立组件。`@Builder` 只允许用于极简的布局片段（无状态、无逻辑、3 行以内），凡是有独立语义的 UI 块必须拆成独立的组件文件。

这些 `@Builder` 方法：
1. 有独立的语义名称（如"原神左上角元素图标"、"原神底部等级+好感度"）
2. 代码超过 3 行
3. 是可复用的 UI 块

## 目标

1. 将 6 个 `@Builder` 方法拆成独立的组件文件
2. 保持 `CharacterCard.ets` 只负责组合子组件，不包含内联布局实现

## 验收标准

- [ ] `CharacterCard.ets` 中不再有 `@Builder` 方法
- [ ] 拆分后的组件放在 `components/characters/` 子目录下
- [ ] 编译通过
- [ ] 更新 CHANGELOG.md
