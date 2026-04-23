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

| retcode  | 含义                       | 处理方式                                                     |
| -------- | -------------------------- | ------------------------------------------------------------ |
| `0`      | 成功                       | 正常处理 data                                                |
| `-100`   | 未登录 / Cookie 失效       | 提示用户重新登录，清除本地 Cookie                            |
| `-10001` | 请求参数错误 / DS 签名错误 | 检查 DS 算法和 salt 版本是否匹配                             |
| `-10002` | 请求频率过高               | 降低请求频率，加入延迟重试                                   |
| `1008`   | 账号不存在                 | 提示用户账号异常                                             |
| `1034`   | 需要极验验证               | 触发极验流程（`miscReq.challenge()`），获取 challenge 后重试 |
| `10001`  | Cookie 无效                | 同 -100，提示重新登录                                        |
| `10101`  | 请求过于频繁               | 同 -10002                                                    |
| `10102`  | 账号被封禁                 | 提示账号异常                                                 |

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

> `useK2` 参数：签到接口使用 `useK2=false`（X4 salt），其他接口使用 `useK2=true`（K2 salt）。

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

| 场景           | TeyvatGuide 处理                | 本项目处理                                         |
| -------------- | ------------------------------- | -------------------------------------------------- |
| retcode=1034   | 触发极验，获取 challenge 后重试 | 同，通过 `GeetestService` 处理                     |
| retcode=-100   | 提示重新登录                    | 抛出 `AuthExpiredError`，触发 Cookie 刷新          |
| retcode=-10001 | 显示错误提示                    | 抛出 `AuthExpiredError`（-10001 也视为 auth 失效） |
| 网络超时       | 显示错误提示                    | 抛出异常，ViewModel 捕获后更新 errorMsg            |
| DS 签名错误    | 显示错误提示                    | 检查 salt 版本和算法                               |
