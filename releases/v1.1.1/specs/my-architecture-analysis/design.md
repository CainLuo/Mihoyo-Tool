# My 模块架构分析 — 设计文档

## 一、重构方案

将 `WidgetSection.ets` 中的 `AccountWidgetBlock` 拆分为独立组件 `AccountWidgetBlock.ets`。

## 二、文件结构

```
components/my/
├── AccountWidgetBlock.ets  ← 新建
└── WidgetSection.ets       ← 删除 @Builder，导入新组件
```

## 三、组件职责

### AccountWidgetBlock

- **参数**：`account: MyAccountVM`
- **职责**：渲染单个账号的 Widget 入口区块（账号信息 + 游戏按钮）
