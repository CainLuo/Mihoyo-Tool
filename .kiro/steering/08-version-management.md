# 版本管理与归档规范

## 一、两个阶段的文件位置

### 开发中（版本未完成）

所有工作文件放在原位，不放 `releases/`：

```
design/                    ← 设计文档、原型、技术调研笔记
  research/                ← 技术调研笔记（如 FormKit-Notes.md）
  prototypes/              ← 原型文件
  HoYoLab_Toolkit_*.md     ← 设计规格文档
.kiro/specs/               ← 进行中的 Spec
```

### 已完成（版本发布后归档）

版本功能全部完成、代码合并到主分支、GitHub Release 发布后，执行归档：

```
releases/
└── vX.Y/
    ├── README.md          ← 版本说明（发布日期、主要功能、文件索引）
    ├── design/            ← 从 design/ 整体移过来
    └── specs/             ← 从 .kiro/specs/ 整体移过来
```

## 二、归档操作步骤

版本完成后执行：

1. 将 `design/` 目录整体移动到 `releases/vX.Y/design/`
2. 将 `.kiro/specs/` 目录整体移动到 `releases/vX.Y/specs/`
3. 在 `releases/vX.Y/README.md` 写版本说明
4. 更新 `CHANGELOG.md` 添加该版本条目

## 三、新版本开始时

归档完成后，新版本的工作文件从空白开始：

- `design/` 为空，新版本设计文档和调研笔记按需创建
- `.kiro/specs/` 为空，新功能按需创建新 Spec
- `.kiro/steering/` **不归档、不移动**，持续有效

## 四、CHANGELOG.md 格式

每个版本在 `CHANGELOG.md` 顶部追加，格式：

```markdown
## vX.Y.Z (YYYY-MM-DD)

### 新功能

- ...

### 说明

- ...
```
