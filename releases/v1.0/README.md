# V1.0 归档

**归档日期**：2026-04-27

## 主要功能

- 多账号登录（扫码 / Cookie，release 包无手机号登录）
- 首页战绩总览（原神 / 星穹铁道 / 绝区零）
- 角色列表与详情页（三款游戏独立结构）
- 便笺详情页（三款游戏）
- 我的页（账号管理 / 外观设置 / 通知设置 / 关于）
- 首屏隐私合规（用户协议 + 隐私政策两步确认）
- 体力满额本地通知
- 全设备自适应（手机 / 折叠屏 / 平板 / PC 分栏布局）
- 多语言（简体中文 / 繁体中文 / 英文）
- 多主题（浅色 / 深色 / 跟随系统）
- 四环境构建（mock / debug / internal / release）

## 目录结构

```
releases/v1.0/
├── README.md                              ← 本文件
├── design/                                ← 设计文档与原型
│   ├── HoYoLab_Toolkit_SRS_Spec_v1.0.md  ← 需求规格说明书
│   ├── HoYoLab_Toolkit_Technical_Spec_v1.0.md  ← 技术规格说明书
│   ├── HoYoLab_Toolkit_UI_Spec_v1.0.md   ← 页面细节规范
│   ├── HoYoLab_Toolkit_UI_UX_Color_Spec_v1.0.md  ← UI/UX 颜色规范
│   └── prototypes/v1.0/                  ← HTML 原型文件
└── specs/                                 ← 功能 Spec（已完成）
    ├── privacy-compliance/
    ├── navigation-multi-device/
    ├── appearance-settings-page/
    ├── game-stamina-notification/
    ├── global-operation-feedback/
    ├── char-detail-pages/
    ├── starrail-zzz-daily-detail/
    ├── game-data-database-redesign/
    ├── sync-queue/
    ├── mihoyo-api-redesign/
    ├── mihoyo-mock-redesign/
    ├── build-env-config/
    ├── navigation-safearea-router/
    ├── cookie-refresh-and-expiry/
    ├── api-log-system/
    ├── core-api-tests/
    ├── core-db-tests/
    ├── entry-ui-and-snapshot-tests/
    ├── entry-viewmodel-tests/
    └── unit-and-viewmodel-tests/
```
