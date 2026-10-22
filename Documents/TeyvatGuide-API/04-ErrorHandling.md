# TeyvatGuide 错误处理机制

---

## 一、通用响应结构

所有 API 响应均遵循以下结构：

```typescript
type Resp<T> = {
  retcode: number; // 0 = 成功，非 0 = 错误
  message: string; // 错误描述
  data: T; // 响应数据（retcode=0 时有效）
};
```

---

## 二、已知 retcode 及处理方式

TeyvatGuide 没有统一的 retcode → 错误类型映射；除极验外，多数错误由调用方直接 `showSnackbar.error()` 展示服务端 `message`。

| retcode  | 含义                                                     | 处理方式                                                     |
| -------- | -------------------------------------------------------- | ------------------------------------------------------------ |
| `0`      | 成功                                                     | 正常处理 data                                                |
| `-100`   | 未登录 / Cookie 失效                                     | 提示用户重新登录                                             |
| `10001`  | Please login / Cookie 无效                               | 同 `-100`                                                    |
| `-10001` | 请求无效（`invalid request`）/ header / DS 签名错误      | 显示服务端错误；不刷新 Cookie，检查 DS、salt、请求头         |
| `1008`   | 用户信息不匹配（例如无效 `role_id` / UID）               | 显示服务端错误；不是“账号不存在”                             |
| `1034`   | 需要极验验证                                             | 触发极验流程（`miscReq.challenge()`），获取 challenge 后重试 |
| `10102`  | 数据可见性不足 / 战绩未公开                              | 提示用户开启公开战绩                                         |
| `-106`   | 二维码已过期                                             | 游戏扫码登录组件单独处理，提示重新获取二维码                 |
| `5003`   | TeyvatGuide 没有统一映射                                 | 本项目按设备指纹无效 / 账号异常单独处理                      |
| `10041`  | TeyvatGuide 没有统一映射                                 | 同上                                                         |

> `-10001` **不是**登录失效。把它和 `-100` / `10001` 一起刷新 Cookie，会在 Cookie 实际有效时误弹“登录已过期”。本项目通过 `MihoyoRetcode.INVALID_REQUEST` + `RetcodeKind.INVALID_REQUEST` 单独处理。

---

## 三、极验验证流程（retcode=1034）

当接口返回 `retcode=1034` 时，需要触发极验人机验证：

```
1. 调用 miscReq.create(cookie, useK2)
   → POST bbs-api.miyoushe.com/misc/api/createVerification
   → 返回 { gt, challenge, new_captcha }

2. 展示极验验证组件，用户完成验证
   → 返回 { geetest_challenge, geetest_validate, geetest_seccode }

3. 调用 miscReq.verify(gtRes, cookie, useK2)
   → POST bbs-api.miyoushe.com/misc/api/verifyVerification
   → 返回 { challenge }（验证通过后的 challenge）

4. 将 challenge 附加到原始请求的 header 中重试
   → header["x-rpc-challenge"] = challenge
```

> `useK2` 参数：`create` / `verify` 默认 `true`（K2 salt）；部分调用方传 `false` 改用 X4 salt。游戏签到本身走 `lunaReq` 的 X6 salt，不走 K2 / X4 分支。

---

## 四、TeyvatGuide 的错误处理实现

TeyvatGuide 使用 `showSnackbar` 展示错误提示，不做自动重试（极验除外）：

```typescript
// miscReq.ts 中的错误处理示例
if (createResp.retcode !== 0) {
  showSnackbar.error(`[${createResp.retcode}] ${createResp.message}`);
  return false;
}
```

### 网络层错误

通过 `TGHttps.getErrMsg(e)` 统一提取错误信息：

```typescript
try {
  createResp = await createVerification(cookie, useK2);
} catch (e) {
  const errMsg = TGHttps.getErrMsg(e);
  showSnackbar.error(`创建验证失败：${errMsg}`);
  return false;
}
```

---

## 五、与本项目（HarmonyOS）的对比

| 场景             | TeyvatGuide 处理                    | 本项目处理                                                           |
| ---------------- | ----------------------------------- | -------------------------------------------------------------------- |
| retcode=1034     | 触发极验，获取 challenge 后重试     | 同，通过 `GeetestService` 处理                                       |
| retcode=-100     | 提示重新登录                        | 抛出 `AuthExpiredError`，触发 Cookie 刷新                            |
| retcode=10001    | 提示重新登录                        | 同 `-100`                                                            |
| retcode=-10001   | 显示错误提示                        | `INVALID_REQUEST`，普通业务错误，**不触发登录失效**                  |
| retcode=5003/10041 | 无统一映射                        | `FingerprintReporter` 上报；`SyncQueueRunner` 归为 `fingerprint` 失败 |
| retcode=10102    | 提示战绩未公开                      | `RoleNotPublicError` / `ROLE_NOT_PUBLIC`                             |
| retcode=10307    | 无专门映射                          | 当前按普通业务错误处理；PizzaHelperUnited 有维护中专门映射，待补     |
| retcode=-1002    | 无专门映射                          | `ACCOUNT_NOT_FOUND = -1002` 常量未使用；含义是游戏账号未绑定，不是 `1008` |
| 网络超时         | 显示错误提示                        | 抛出 `HttpError`（`statusCode = 0`），ViewModel 捕获后更新 `errorMsg` |
| DS 签名错误      | 显示错误提示，检查 salt / 请求头    | 同；`-10001` 不按 Cookie 失效处理                                    |

> 2026-10-21 修正：旧版本本文把 `-10001` 写成“本项目视为 auth 失效”，把 `10102` 写成“账号被封禁”，均与当前代码和参考项目不符，已更正。
