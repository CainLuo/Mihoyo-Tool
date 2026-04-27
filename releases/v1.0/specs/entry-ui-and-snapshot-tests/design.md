# Design Document

## Overview

本 Spec 在 `entry/src/ohosTest/` 下新增两类测试：

1. **页面级 UI 测试**：使用 Hypium + `@ohos/uitest`，通过 `Driver`/`Component`/`ON` API 在模拟器上验证页面交互流程。
2. **组件截图测试**：使用 `componentSnapshot` API 对关键页面各状态截图，首次运行生成基准图，后续运行对比像素差异（容忍度 1%）。

所有测试均在模拟器（127.0.0.1:5555）上运行，使用 `product=mock` 构建确保数据可预测。

## Architecture

### 文件结构

```
entry/src/ohosTest/
├── ets/
│   └── test/
│       ├── List.test.ets                        ← 入口，注册所有套件
│       ├── MainPageTest.test.ets                ← Main 页 UI 测试
│       ├── HomePageTest.test.ets                ← Home 页 UI 测试
│       ├── CharactersPageTest.test.ets          ← Characters 页 UI 测试
│       ├── MyPageTest.test.ets                  ← My 页 UI 测试
│       ├── LoginPageTest.test.ets               ← Login 页 UI 测试
│       ├── AccountDetailPageTest.test.ets       ← AccountDetail 页 UI 测试
│       ├── GenshinDailyDetailPageTest.test.ets  ← GenshinDailyDetail 页 UI 测试
│       ├── GenshinCharacterDetailPageTest.test.ets ← GenshinCharacterDetail 页 UI 测试
│       ├── SnapshotHelper.ets                   ← 截图工具类
│       ├── HomeSnapshotTest.test.ets            ← Home 页截图测试
│       ├── CharactersSnapshotTest.test.ets      ← Characters 页截图测试
│       ├── LoginSnapshotTest.test.ets           ← Login 页截图测试
│       └── CharDetailSnapshotTest.test.ets      ← GenshinCharacterDetail 页截图测试
└── snapshots/
    └── baseline/                                ← 基准截图存放目录
        ├── home_empty.png
        ├── home_skeleton.png
        ├── home_data.png
        ├── characters_empty.png
        ├── characters_skeleton.png
        ├── characters_data.png
        ├── login_phone_tab.png
        ├── login_qrcode_tab.png
        ├── login_cookie_tab.png
        ├── char_detail_portrait.png
        ├── char_detail_wide.png
        └── char_detail_empty.png
```

### 技术方案

#### UI 测试（Hypium + @ohos/uitest）

```typescript
import { Driver, Component, ON } from "@ohos.uitest";

// 标准测试结构
it("用例名称", 0, async (done: Function) => {
  const driver = Driver.create();
  await driver.delayMs(500); // 等待页面渲染
  const comp = await driver.findComponent(ON.text("xxx"));
  expect(comp).assertNotNull();
  done();
});
```

#### 截图测试（componentSnapshot）

```typescript
import componentSnapshot from '@ohos.arkui.componentSnapshot';

// SnapshotHelper 核心逻辑
async compareOrSave(componentId: string, baselineName: string): Promise<boolean> {
  await driver.delayMs(500);
  const pixelMap = await componentSnapshot.get(componentId);
  const baselinePath = `entry/src/ohosTest/snapshots/baseline/${baselineName}.png`;
  if (!fileExists(baselinePath)) {
    savePixelMap(pixelMap, baselinePath);
    return true;  // 首次运行，生成基准图
  }
  const baseline = loadPixelMap(baselinePath);
  const diffRatio = comparePixelMaps(pixelMap, baseline);
  return diffRatio <= 0.01;  // 1% 容忍度
}
```

## Components and Interfaces

### SnapshotHelper

| 方法                                       | 说明                                           |
| ------------------------------------------ | ---------------------------------------------- |
| `get(componentId)`                         | 调用 `componentSnapshot.get` 截取组件 PixelMap |
| `saveToFile(pixelMap, path)`               | 将 PixelMap 保存为 PNG 文件                    |
| `compareOrSave(componentId, baselineName)` | 对比或生成基准图，返回是否通过                 |
| `comparePixelMaps(a, b)`                   | 逐像素对比，返回差异百分比                     |

### List.test.ets 注册顺序

```typescript
// UI 测试（先注册）
mainPageTest();
homePageTest();
charactersPageTest();
myPageTest();
loginPageTest();
accountDetailPageTest();
genshinDailyDetailPageTest();
genshinCharDetailPageTest();

// 截图测试（后注册）
homeSnapshotTest();
charactersSnapshotTest();
loginSnapshotTest();
charDetailSnapshotTest();
```

## Correctness Properties

### P1：截图对比幂等性

对同一页面同一状态连续截图两次，两次截图的像素差异应 ≤ 1%（渲染稳定性）。

### P2：基准图生成后对比通过

首次运行生成基准图后，立即再次运行截图测试，差异应为 0%（基准图与自身对比）。

### P3：UI 测试独立性

每个 `it` 用例独立运行，不依赖其他用例的状态（通过 `beforeEach` 重置导航栈）。
