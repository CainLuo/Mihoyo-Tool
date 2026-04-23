# TeyvatGuide DS 签名机制

DS（Dynamic Secret）是米游社 API 的请求签名，用于防止接口被滥用。

---

## 一、Salt 值（BBS 版本 2.102.1）

来源：`TeyvatGuide/src/utils/TGBbs.ts`

| Salt 类型 | 值                                 | 用途                                   |
| --------- | ---------------------------------- | -------------------------------------- |
| `K2`      | `lX8m5VO5at5JG7hR8hzqFwzyL5aB1tYo` | 极验验证、action_ticket、社区点赞/分享 |
| `LK2`     | `yBh10ikxtLPoIhgwgPZSv5dmfaOTSJ6a` | authKey 生成（抽卡用）                 |
| `X4`      | `xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs` | 通用接口（默认值）                     |
| `X6`      | `t0qEgfub6cvueAPgR5m9aQWWVciEer7v` | 签到接口、社区签到                     |
| `PROD`    | `t0qEgfub6cvueAPgR5m9aQWWVciEer7v` | 与 X6 相同                             |

> X6 和 PROD 的值相同，均为 `t0qEgfub6cvueAPgR5m9aQWWVciEer7v`。

---

## 二、DS 算法

来源：`TeyvatGuide/src/utils/getRequestHeader.ts`

### 2.1 两种 DS 类型

**类型 1（isSign=true）**：用于需要"签名"的接口，random 为 6 位随机字母数字字符串。

```
hashStr = "salt={salt}&t={timestamp}&r={random6}"
```

**类型 2（isSign=false，默认）**：用于普通接口，random 为 6 位随机数字（100000~200000）。

```
GET 请求：  hashStr = "salt={salt}&t={timestamp}&r={random}&b=&q={query_string}"
POST 请求：  hashStr = "salt={salt}&t={timestamp}&r={random}&b={body_string}&q="
```

### 2.2 计算步骤

1. `timestamp` = `Math.floor(Date.now() / 1000)`（Unix 秒级时间戳）
2. `random`：
   - isSign=true：6 位随机字母数字（`getRandomString(6)`）
   - isSign=false：100000~200000 之间的随机整数
3. `query_string`：GET 请求的 query 参数，按**字典序**排序后拼接为 `key=value&key=value`
4. `body_string`：POST 请求的 body 字符串（JSON.stringify 后的结果）
5. `md5` = MD5(`hashStr`)
6. 最终 DS = `{timestamp},{random},{md5}`

### 2.3 query 参数序列化规则

```typescript
function transParams(obj): string {
  const keys = Object.keys(obj).sort(); // 字典序排序
  for (const key of keys) {
    res += `${key}=${obj[key].toString()}&`;
  }
  return res.slice(0, -1); // 去掉末尾 &
}
```

---

## 三、各接口使用的 Salt 类型

| Salt | isSign | 使用场景                                     |
| ---- | ------ | -------------------------------------------- |
| X4   | false  | 通用默认（大多数 GET 接口）                  |
| X4   | true   | BBS 用户信息、合集详情                       |
| K2   | true   | 极验创建/验证、action_ticket、帖子点赞/分享  |
| K2   | false  | 极验验证（POST body）                        |
| LK2  | true   | authKey 生成（抽卡）                         |
| X6   | false  | 签到（luna/sign）、社区签到（apihub/signIn） |

---

## 四、标准请求头

来源：`getRequestHeader()` 函数

```
user-agent:          Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.102.1
x-rpc-app_version:   2.102.1
x-rpc-client_type:   5
x-requested-with:    com.mihoyo.hyperion
referer:             https://webstatic.mihoyo.com
x-rpc-device_id:     {设备 UUID}
x-rpc-device_fp:     {设备指纹}
ds:                  {timestamp},{random},{md5}
cookie:              {cookie 字符串}
```

> `x-rpc-client_type` 默认为 `5`（PC 端），部分接口会覆盖为 `2`（移动端）或 `4`。

---

## 五、特殊接口的 Header 差异

### 极验接口（useK2=true）

```
x-rpc-client_type: 2   ← 覆盖默认的 5
ds: {K2 签名}
```

### 签到接口（luna/sign）

```
x-rpc-client_type: 2
x-rpc-signgame: {host}   ← 游戏标识（hk4e/hkrpg/zzz 等）
x-rpc-challenge: {challenge}   ← 极验 challenge（可选）
ds: {X6 签名}
```

### 手机号登录接口

```
x-rpc-aigis: {aigis 数据}
x-rpc-app_version: 2.102.1
x-rpc-client_type: 2
x-rpc-app_id: bll8iq97cem8
x-rpc-device_fp: {设备指纹}
x-rpc-device_name: {设备名}
x-rpc-device_id: {设备 UUID}
x-rpc-device_model: {设备型号}
user-agent: {移动端 UA}
```

### 二维码登录接口（passport）

```
x-rpc-device_id: {设备 UUID}
user-agent: HYPContainer/1.3.3.182
x-rpc-app_id: ddxf5dufpuyo
x-rpc-client_type: 3
```

### stoken 换取接口（getTokenByGameToken）

```
x-rpc-client_type: 4
x-rpc-app_id: bll8iq97cem8
x-rpc-game_biz: bbs_cn
x-rpc-sys_version: 12
ds: {X6 签名}
```

---

## 六、Cookie 字段说明

| 字段           | 说明               | 获取方式                          |
| -------------- | ------------------ | --------------------------------- |
| `account_id`   | 米游社账号 UID     | 登录后从 Cookie 中提取            |
| `cookie_token` | 通用 Cookie Token  | 登录后获得，可通过 stoken 刷新    |
| `ltoken`       | 长效 Token         | 登录后获得，可通过 stoken 刷新    |
| `ltuid`        | ltoken 对应的 UID  | 与 ltoken 配套                    |
| `stoken`       | 超级 Token（长效） | 手机号/二维码登录后获得           |
| `mid`          | 账号 mid           | 与 stoken 配套，verifyLtoken 返回 |

> `cookie_token` 和 `ltoken` 可通过 `stoken` 刷新，详见 `passportReq.ts`。
