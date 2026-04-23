# Geetest 验证逻辑对比：三项目

> 仅针对便笺接口触发的 Geetest 流程，逐步骤对比代码实现。
> 来源文件已全部读取，无猜测。

---

## 一、createVerification 接口

### 1.1 接口地址

| 项目              | URL                                                                                 |
| ----------------- | ----------------------------------------------------------------------------------- |
| 本项目            | `https://bbs-api.miyoushe.com/misc/api/createVerification`                          |
| PizzaHelperUnited | `https://api-takumi-record.mihoyo.com/game_record/app/card/wapi/createVerification` |
| TeyvatGuide       | `https://bbs-api.miyoushe.com/misc/api/createVerification`                          |

**关键差异**：PizzaHelperUnited 用的是 `api-takumi-record.mihoyo.com/game_record/app/card/wapi/` 路径，本项目和 TeyvatGuide 用的是 `bbs-api.miyoushe.com/misc/api/`。这是两个不同的接口端点。

### 1.2 createVerification 请求头

| 字段                   | 本项目                                        | PizzaHelperUnited                                | TeyvatGuide                                        |
| ---------------------- | --------------------------------------------- | ------------------------------------------------ | -------------------------------------------------- |
| `x-rpc-app_version`    | `2.104.0`                                     | `2.40.1`                                         | `2.102.1`                                          |
| `x-rpc-client_type`    | `2`（CLIENT_ANDROID）                         | `5`（defaultHeaders 默认）                       | `2`（覆盖）                                        |
| `x-rpc-device_fp`      | ✅ 有                                         | ✅ 有（additionalHeaders）                       | ✅ 有                                              |
| `x-rpc-device_id`      | ✅ 有                                         | ✅ 有（additionalHeaders）                       | ✅ 有                                              |
| `x-rpc-challenge_path` | ❌ 无                                         | ✅ 有（writeXRPCChallengeHeaders4DailyNote）     | ❌ 无                                              |
| `x-rpc-challenge_game` | ❌ 无                                         | ✅ 有（writeXRPCChallengeHeaders4DailyNote）     | ❌ 无                                              |
| `DS`                   | K2 Sign（salt_v1，不含 b/q，字母数字 random） | X4（defaultHeaders 生成，含 b/q，纯数字 random） | K2（isSign=true，不含 b/q，字母数字 random）       |
| `User-Agent`           | `miHoYoBBS/2.104.0`（iPhone iOS 16.3.1）      | `miHoYoBBS/2.40.1`（iPhone iOS 17.6）            | `miHoYoBBS/2.102.1`（Linux Android 12，移动端 UA） |
| `Referer`              | 无                                            | `https://webstatic.mihoyo.com`                   | 无                                                 |
| `query`                | `is_high=true`                                | `is_high=true`                                   | `is_high=true`                                     |

### 1.3 createVerification 返回值模型

| 字段          | 本项目（GeetestCreateResult） | PizzaHelperUnited（Verification） | TeyvatGuide |
| ------------- | ----------------------------- | --------------------------------- | ----------- |
| `gt`          | ✅                            | ✅                                | ✅          |
| `challenge`   | ✅                            | ✅                                | ✅          |
| `new_captcha` | ✅                            | ✅（newCaptcha）                  | ✅          |
| `risk_type`   | ✅（v4 字段）                 | ❌ 无                             | ❌ 无       |
| `success`     | ❌ 无                         | ✅                                | ❌ 无       |

---

## 二、verifyVerification 接口

### 2.1 接口地址

| 项目              | URL                                                                                 |
| ----------------- | ----------------------------------------------------------------------------------- |
| 本项目            | `https://bbs-api.miyoushe.com/misc/api/verifyVerification`                          |
| PizzaHelperUnited | `https://api-takumi-record.mihoyo.com/game_record/app/card/wapi/verifyVerification` |
| TeyvatGuide       | `https://bbs-api.miyoushe.com/misc/api/verifyVerification`                          |

同 createVerification，PizzaHelperUnited 用不同的端点。

### 2.2 verifyVerification 请求 body

| 字段                | 本项目                  | PizzaHelperUnited                                         | TeyvatGuide             |
| ------------------- | ----------------------- | --------------------------------------------------------- | ----------------------- |
| `geetest_challenge` | ✅                      | ✅（geetestChallenge，snake_case 编码）                   | ✅                      |
| `geetest_validate`  | ✅                      | ✅（geetestValidate）                                     | ✅                      |
| `geetest_seccode`   | ✅（直接用 SDK 返回值） | ✅（`"\(validate)\|jordan"`，**拼接了 `\|jordan` 后缀**） | ✅（直接用 SDK 返回值） |

**关键差异**：PizzaHelperUnited 的 `geetest_seccode` 是 `validate + "|jordan"`，而本项目和 TeyvatGuide 直接使用 SDK 返回的 seccode 原始值。

### 2.3 verifyVerification 请求头

| 字段                   | 本项目                                  | PizzaHelperUnited | TeyvatGuide                |
| ---------------------- | --------------------------------------- | ----------------- | -------------------------- |
| `x-rpc-challenge_path` | ❌ 无                                   | ✅ 有             | ❌ 无                      |
| `x-rpc-challenge_game` | ❌ 无                                   | ✅ 有             | ❌ 无                      |
| `DS`                   | K2（salt_v1，含 body，字母数字 random） | X4（含 body）     | K2（isSign=false，含 b/q） |

### 2.4 verifyVerification 返回值

| 项目              | 返回内容                                   |
| ----------------- | ------------------------------------------ |
| 本项目            | `challenge` 字符串                         |
| PizzaHelperUnited | `VerifyVerification { challenge: String }` |
| TeyvatGuide       | `challenge` 字符串                         |

三个项目返回值一致，都是新的 `challenge` 字符串。

---

## 三、完整 Geetest 流程对比

### 本项目

```
1. 便笺接口返回 retcode=1034/10035
2. HomeViewModel.handleGeetest()
   → GeetestService.createVerification(cookie)
     → GET bbs-api.miyoushe.com/misc/api/createVerification
     → DS: K2 Sign（不含 b/q）
   → 设置 geetestTrigger，View 层弹 GeetestDialog
3. 用户完成验证，GeetestDialog 回调 onResult(GeetestVerifyInput)
4. HomeViewModel.onGeetestResult(result)
   → GeetestService.verifyVerification(result, cookie)
     → POST bbs-api.miyoushe.com/misc/api/verifyVerification
     → body: { geetest_challenge, geetest_validate, geetest_seccode }（SDK 原始值）
     → DS: K2（含 body）
   → 用新 challenge 重试便笺接口
     → headers 注入: x-rpc-challenge + x-rpc-challenge_path + x-rpc-challenge_game ✅
```

### PizzaHelperUnited

```
1. 便笺接口返回任何错误（try? 捕获）
2. 检查 cookie.contains("stoken=v2_")
   → 有：Widget 降级（不触发 Geetest）
   → 无：抛出 sTokenV2InvalidOrMissing（不触发 Geetest）

   注：PizzaHelperUnited 的 Geetest 流程不是在便笺接口失败时触发，
       而是在用户手动点击"验证"按钮时触发（UI 层主动调用）
3. HoYo.createVerification(region, cookie, deviceID, deviceFingerPrint)
   → GET api-takumi-record.mihoyo.com/game_record/app/card/wapi/createVerification
   → headers 包含: x-rpc-challenge_path + x-rpc-challenge_game ✅
   → DS: X4（defaultHeaders 生成）
4. 展示 Geetest 验证 UI
5. HoYo.verifyVerification(region, challenge, validate, cookie, deviceFingerPrint)
   → POST api-takumi-record.mihoyo.com/game_record/app/card/wapi/verifyVerification
   → body: { geetest_challenge, geetest_validate, geetest_seccode: validate+"|jordan" }
   → headers 包含: x-rpc-challenge_path + x-rpc-challenge_game ✅
   → DS: X4（含 body）
6. 用新 challenge 重试便笺接口
```

### TeyvatGuide

```
1. 便笺接口返回 retcode=1034
2. miscReq.getGeetestChallenge(cookie, useK2=false)
   → miscReq.create(cookie, useK2=false)
     → GET bbs-api.miyoushe.com/misc/api/createVerification
     → DS: X4（isSign=true，不含 b/q）
   → showGeetest(createResp.data)（展示验证 UI）
   → miscReq.verify(gtRes, cookie, useK2=false)
     → POST bbs-api.miyoushe.com/misc/api/verifyVerification
     → body: { geetest_challenge, geetest_validate, geetest_seccode }（SDK 原始值）
     → DS: X4（含 body）
3. 用新 challenge 重试便笺接口
   → header: x-rpc-challenge（无 challenge_path/game）
```

---

## 四、差异汇总

| 维度                              | 本项目                           | PizzaHelperUnited                                         | TeyvatGuide                      |
| --------------------------------- | -------------------------------- | --------------------------------------------------------- | -------------------------------- |
| createVerification 端点           | `bbs-api.miyoushe.com/misc/api/` | `api-takumi-record.mihoyo.com/game_record/app/card/wapi/` | `bbs-api.miyoushe.com/misc/api/` |
| verifyVerification 端点           | 同上                             | 同上                                                      | 同上                             |
| create 时携带 challenge_path/game | ❌                               | ✅                                                        | ❌                               |
| verify 时携带 challenge_path/game | ❌                               | ✅                                                        | ❌                               |
| geetest_seccode 格式              | SDK 原始值                       | `validate + "\|jordan"`                                   | SDK 原始值                       |
| create DS salt                    | K2 Sign（不含 b/q）              | X4（含 b/q）                                              | X4（isSign=true，不含 b/q）      |
| verify DS salt                    | K2（含 body）                    | X4（含 body）                                             | X4（含 body）                    |
| Geetest 触发时机                  | 便笺返回 1034/10035              | 用户手动触发（便笺失败走 Widget 降级）                    | 便笺返回 1034                    |
| 触发后先尝试 Widget 降级          | ✅                               | 不适用（Widget 在 Geetest 之前）                          | ❌                               |

---

## 五、待决策方案

### 差异 A：createVerification / verifyVerification 端点

本项目和 TeyvatGuide 用 `bbs-api.miyoushe.com/misc/api/`，PizzaHelperUnited 用 `api-takumi-record.mihoyo.com/game_record/app/card/wapi/`。

**方案 A1：保持现状（bbs-api 端点）**

- 与 TeyvatGuide 一致，已知可用
- 风险：不确定两个端点的行为是否完全相同

**方案 A2：改用 PizzaHelperUnited 的端点（card/wapi）**

- 与 PizzaHelperUnited 一致
- 需要同时修改 `GeetestService.ets` 中的 URL 常量
- 风险：未知，需要实测

---

### 差异 B：create/verify 时是否携带 x-rpc-challenge_path 和 x-rpc-challenge_game

本项目在 createVerification 和 verifyVerification 请求头里**没有**这两个字段，PizzaHelperUnited 有。

**方案 B1：保持现状**

- 与 TeyvatGuide 一致，TeyvatGuide 也没有这两个字段
- 风险：低，这两个字段在 create/verify 阶段的作用不明确

**方案 B2：在 create/verify 请求头里也加入这两个字段**

- 与 PizzaHelperUnited 完全一致
- 需要 `GeetestService.createVerification` 和 `verifyVerification` 接收 gameId 参数，根据游戏注入对应的 path 和 game 值
- 改动较大，需要修改 `GeetestService`、`HomeViewModel.handleGeetest`、`GeetestTrigger` 模型

---

### 差异 C：geetest_seccode 格式

本项目直接用 SDK 返回的 seccode 原始值，PizzaHelperUnited 用 `validate + "|jordan"`。

**方案 C1：保持现状（SDK 原始值）**

- 与 TeyvatGuide 一致
- 风险：不确定服务器是否要求 `|jordan` 后缀

**方案 C2：改为 validate + "|jordan"**

- 与 PizzaHelperUnited 一致
- 只需修改 `GeetestService.verifyVerification` 中 body 的构造逻辑，改动极小：
  ```typescript
  geetest_seccode: verifyInput.geetest_validate + '|jordan',
  ```
- 风险：如果 SDK 已经在 seccode 里包含了 `|jordan`，会导致重复

---

### 推荐优先级

| 差异                                      | 推荐                      | 理由                                             |
| ----------------------------------------- | ------------------------- | ------------------------------------------------ |
| A（端点）                                 | A1 保持现状               | TeyvatGuide 用同一端点且已知可用，改端点风险未知 |
| B（challenge_path/game in create/verify） | B1 保持现状               | TeyvatGuide 也没有，影响不明确                   |
| C（seccode 格式）                         | C2 改为 validate+\|jordan | 改动极小，与 PizzaHelperUnited 对齐，风险低      |

---

## 六、修复后状态（已应用 A2 + B2 + C2）

基于 PizzaHelperUnited 是频繁请求 daily note 的完整移动端 App，TeyvatGuide 的 Geetest 仅用于签到场景，参考价值有限，因此全部对齐 PizzaHelperUnited 方案。

| 差异                                      | 修复前                           | 修复后                                                       |
| ----------------------------------------- | -------------------------------- | ------------------------------------------------------------ |
| A：接口端点                               | `bbs-api.miyoushe.com/misc/api/` | `api-takumi-record.mihoyo.com/game_record/app/card/wapi/` ✅ |
| B：create/verify 携带 challenge_path/game | ❌ 无                            | ✅ 有，按 gameId 注入对应路径和游戏 ID                       |
| C：geetest_seccode 格式                   | SDK 原始值                       | `validate + "\|jordan"` ✅                                   |
| DS salt                                   | K2 Sign                          | X4（与 PizzaHelperUnited 一致） ✅                           |

修改文件：

- `core/src/main/ets/network/MihoyoAccountApiPath.ets`：更新 CREATE_VERIFICATION / VERIFY_VERIFICATION 路径为 card/wapi
- `core/src/main/ets/network/GeetestService.ets`：重写，改端点、加 challenge_path/game、改 seccode、改 DS salt 为 X4
- `entry/src/main/ets/viewmodel/HomeViewModel.ets`：`createVerification` 和 `verifyVerification` 传入 `gameId`
