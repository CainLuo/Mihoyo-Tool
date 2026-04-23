# TeyvatGuide 签到模块

来源：`TeyvatGuide/src/request/lunaReq.ts`

---

## 一、各游戏签到配置

基础域名：`https://api-takumi.mihoyo.com/event/luna/`

| 游戏           | gameBiz    | actId              | host    | 签到 URL              |
| -------------- | ---------- | ------------------ | ------- | --------------------- |
| 崩坏2          | `bh2_cn`   | `e202203291431091` | `bh2`   | `.../luna/bh2/sign`   |
| 崩坏3          | `bh3_cn`   | `e202306201626331` | `bh3`   | `.../luna/bh3/sign`   |
| 原神           | `hk4e_cn`  | `e202311201442471` | `hk4e`  | `.../luna/hk4e/sign`  |
| 崩坏：星穹铁道 | `hkrpg_cn` | `e202304121516551` | `hkrpg` | `.../luna/hkrpg/sign` |
| 未定事件簿     | `nxx_cn`   | `e202202251749321` | `nxx`   | `.../luna/nxx/sign`   |
| 绝区零         | `nap_cn`   | `e202406242138391` | `zzz`   | `.../luna/zzz/sign`   |

> 注意：绝区零的 `host` 是 `zzz`，不是 `nap`。

---

## 二、签到接口路径

所有路径均相对于 `https://api-takumi.mihoyo.com/event/luna/`：

| 接口             | 方法 | 路径                 | 说明                 |
| ---------------- | ---- | -------------------- | -------------------- |
| 获取签到奖励列表 | GET  | `{host}/home`        | 无需登录             |
| 获取签到状态     | GET  | `{host}/info`        | 需要 Cookie          |
| 执行签到         | POST | `{host}/sign`        | 需要 Cookie + DS(X6) |
| 获取补签信息     | GET  | `{host}/resign_info` | 需要 Cookie          |
| 执行补签         | POST | `{host}/resign`      | 需要 Cookie + DS(X6) |

---

## 三、签到请求 Header

```
user-agent:        Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/2.102.1
referer:           https://act.mihoyo.com
cookie:            {完整 cookie 字符串}
x-rpc-signgame:    {host}   ← 游戏标识
x-rpc-client_type: 2        ← 签到接口固定为 2
ds:                {X6 签名}
x-rpc-challenge:   {challenge}   ← 极验验证后附加（可选）
```

> 签到接口使用**移动端 UA**（`BBS_UA_MOBILE`），而非 PC 端 UA。

---

## 四、签到请求 Body

```json
{
  "lang": "zh-cn",
  "act_id": "{actId}",
  "region": "{服务器区服}",
  "uid": "{游戏角色 UID}"
}
```

---

## 五、签到返回值

成功时 `retcode=0`，`data` 结构：

```typescript
type SignResp = {
  retcode: number;
  message: string;
  data: {
    code: string; // 签到结果码，如 "ok"
    risk_code: number; // 风控码，非 0 时需要极验
    gt: string; // 极验 gt（risk_code 非 0 时有值）
    challenge: string; // 极验 challenge（risk_code 非 0 时有值）
    success: number; // 1=成功，0=失败
  };
};
```

当 `risk_code !== 0` 时，需要触发极验验证后重试签到（附带 `x-rpc-challenge` header）。

---

## 六、社区签到（米游币）

与游戏签到不同，社区签到（获取米游币）使用 apihub 接口：

- **路径**：`POST https://bbs-api.miyoushe.com/apihub/app/api/signIn`
- **DS Salt**：X6
- **client_type**：2
- **Body**：`{ "gids": 2 }`（原神社区 gid=2）
- **说明**：需要验证码登录获取的 Cookie（`stoken` 类型）
