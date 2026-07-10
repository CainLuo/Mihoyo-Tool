# v1.1.1 版本说明

**发布日期**：2026-07-10

## 主要功能

### 扫码登录迁移到新版 passport API

- 从旧的 `hk4e-sdk.mihoyo.com` API 迁移到 `passport-api.mihoyo.com`
- 新版 API 一次请求直接返回 stoken、ltoken、mid，无需二次换取
- 请求头与官方客户端一致，兼容性更好

### Widget 桌面小组件

- 支持 1×2、2×2、2×4、4×4 四种尺寸
- 多账号多游戏混合显示
- 游戏专属 1×2 卡片（原神 / 星穹铁道 / 绝区零）
- Widget 配置页（尺寸选择 → 游戏选择 → 角色选择）
- 数据自动同步与刷新

### 代码架构优化

- 重构 Home、Characters、My、chardetail、widgetconfig 多个模块
- 删除冗余 `@Builder` 内联方法，拆分为独立组件

## 文件索引

### 设计文档

```
design/
├── prototypes/       ← UI 原型（v1.0）
└── research/         ← 技术调研笔记
    └── FormKit-Notes.md  ← Widget 开发笔记
```

### Specs

```
specs/
├── widget/                           ← Widget 功能 Spec
├── widget-refactor/                  ← Widget 重构 Spec
├── widget-auto-refresh/              ← Widget 自动刷新 Spec
├── widget-extra-rows/                ← Widget 额外数据行 Spec
├── zzz-widget-note-merge/            ← 绝区零便笺合并 Spec
├── home-architecture-analysis/       ← Home 模块架构分析
├── characters-architecture-analysis/ ← Characters 模块架构分析
├── my-architecture-analysis/         ← My 模块架构分析
└── widget-architecture-analysis/     ← Widget 模块架构分析
```

## 已修复问题

- Widget 2x2 白屏问题（`@Prop` 装饰器修复）
- Widget 配置数据结构重构（扁平化结构）
- 硬编码问题修复（颜色和字符串资源化）
- 多语言资源同步（74 个 Widget 资源翻译）
- 2x4 单游戏 UI 修复
- 4x4 多游戏预览修复
- ColorUtil deprecated API 警告修复

## 构建验证

最后构建状态：**成功** ✅
