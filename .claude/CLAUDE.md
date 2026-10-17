# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

# 本项目

SHKP React Native Content Hub —— 嵌入 SHKP 原生 App（The Point）的 RN 内容中心，承载首页发现页、商场探索、租户 Web 内容。页面结构由 SDUI schema + 模板驱动；用户、语言、定位、认证、分析由原生/KMM bridge 提供。

**纯 JS/JSX，非 TypeScript。** React 19.2 / RN 0.84.1，Node >= 24。

## 仓库结构

这是一个父仓库套两个 submodule 的结构：

| 路径 | 内容 | 归属仓库 |
|---|---|---|
| `src/`、`App.jsx`、`index.js` | React Native 侧 | 本仓库 |
| `ios/` | iOS 原生（Swift + UIKit） | **submodule** `thepoint/mobile/ios` |
| `android/` | Android 原生（Kotlin + Compose） | **submodule** `thepoint/mobile/android` |

**在 `ios/` 或 `android/` 里改代码是提交到另一个仓库**，需要单独 commit，再更新父仓库的 submodule 指针。业务逻辑主要在 KMM 共享模块里，那是第三个独立仓库。

## 常用命令

```bash
npm install
npm run start:dev              # Metro（还有 start:uat / start:prod）
npm run android:dev            # Android（还有 android:uat / android:prod）
npm run ios                    # iOS，先在 ios/ 下 bundle exec pod install
npm run lint                   # 提交前必跑
npx jest --runInBand --watchman=false   # 跑测试（package.json 里没有 test script）
```

`npm run lint` 里 **prettier 违规是 error 不是 warning**，CI 会挂。

## 全局约定

- **路径别名 `@/` → `src/`**，三处配置必须同步：`babel.config.js`、`jsconfig.json`、`jest.config.js` 的 `moduleNameMapper`。
- **`.env` 由 `react-native-dotenv` 按 `APP_ENV` 注入**，配置了 `allowUndefined: false` —— 用了 `@env` 里不存在的 key 会直接构建失败。新增变量要同时补 `.env` / `.env.dev` / `.env.uat` / `.env.prod` 四份。
- **绝不提交或打印 API 签名密钥、生产凭据**（`.env` 里有 `API_SIGN_SECRET_KEY`、`API_SIGN_ACCESS_KEY`）。
- **`src/data/*.json` 里的 URL 在 CI 打包时会被就地替换**（`scripts/replace-urls-in-place.js` + `scripts/ci/url-replacements.<env>.json`）。改这些 JSON 的域名时要同步更新替换规则，否则 UAT 会打到生产域名。
- **新增域名、SDUI 组件或 action 前，先同步审查原生 bridge 和安全策略** —— Content Hub 的配置生命周期与回调由 Native/KMM 管理。

## 分层规则

按文件路径自动加载，写代码前会自动进上下文：

| 规则 | 管什么 | 生效范围 |
|---|---|---|
| `javascript.md` | JS 编码约定、theme token、列表性能、i18n、测试 | `src/**`、`App.jsx`、`index.js`、根目录各配置文件 |
| `react-native.md` | RN 版本、对应版本文档、废弃 API、新架构 | 同上 |
| `sdui.md` | SDUI 双系统、引擎模块、schema 写法 | `src/sdui/**`、`src/components/ui/**`、`src/data/*.json` |
| `native-bridge.md` | 原生桥接契约、API 签名安全 | `src/native/**`、`apiClient.js`、`apiSignature.js` |
| `android.md` | Kotlin/Compose/Gradle、版本目录、KMM | `android/**` |
| `ios.md` | iOS 平台、UIKit、API 可用性 | `ios/**` |
| `swift.md` | Swift 语言版本与写法演进 | `ios/**` |
| `swift-concurrency.md` | 线程、`async`/`await`、Swift 6 准备 | `ios/**` |
| `ios-dependencies.md` | CocoaPods / SPM、KMM 接入 | `ios/**` |

参考文档：`docs/SDUI_ARCHITECTURE_GUIDE.md`、`docs/SDUI_JSON_REFERENCE.md`、`JSON_URL_BUILD_TIME_REPLACEMENT.md`、`docs/KMM_MAINTHREAD_AUDIT.md`。
