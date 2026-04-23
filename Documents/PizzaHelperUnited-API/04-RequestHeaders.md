# Request Headers（请求头配置）

## 一、通用请求头

| Header Key          | 国服值                                                                                                             | 国际服值                                                                                                           | 说明                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------ | ----------------------------------- |
| `x-rpc-app_version` | `2.40.1`                                                                                                           | `2.55.0`                                                                                                           | 米游社 App 版本号                   |
| `x-rpc-client_type` | `5`                                                                                                                | `2`                                                                                                                | 客户端类型（5=Web/PC，2=安卓）      |
| `User-Agent`        | `Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.40.1` | `Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.55.0` | 模拟 iPhone 浏览器                  |
| `Referer`           | `https://webstatic.mihoyo.com`                                                                                     | `https://act.hoyolab.com`                                                                                          | 来源页面                            |
| `Origin`            | `https://webstatic.mihoyo.com`                                                                                     | `https://act.hoyolab.com`                                                                                          | 请求来源                            |
| `x-rpc-device_fp`   | 真实设备指纹（13位+）                                                                                              | 同左                                                                                                               | 设备指纹，需提前调用 getFp 接口获取 |
| `x-rpc-device_id`   | UUID 格式设备 ID                                                                                                   | 同左                                                                                                               | 设备唯一标识                        |
| `DS`                | X4 salt 生成                                                                                                       | OSX6 salt 生成                                                                                                     | 动态签名，防重放攻击                |

---

## 二、DS 签名

### 国服（X4 salt）

```
salt = "xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs"
```

**生成格式**：`{timestamp},{random},{md5}`

**MD5 内容**：`salt={salt}&t={timestamp}&r={random}&b={body}&q={query}`

- `timestamp`：Unix 秒级时间戳
- `random`：6 位随机字符串（字母数字混合）
- `body`：POST body 字符串（GET 请求为空）
- `query`：GET 参数按字典序排列的 `key=val&key=val` 字符串

### 国际服（OSX6 salt）

```
salt = "okr4obncj8bw5a65hbnn5oo6ixjc3l9w"
```

生成方式与国服相同。

---

## 三、便笺接口专用头（遇到 1034 时携带）

当便笺接口返回 1034 后，需要完成 Geetest 验证，然后在重试请求时携带以下头：

| Header Key             | 说明                                |
| ---------------------- | ----------------------------------- |
| `x-rpc-challenge`      | Geetest 验证通过后的新 challenge 值 |
| `x-rpc-challenge_path` | 触发验证的接口完整 URL              |
| `x-rpc-challenge_game` | 游戏 ID（原神=2，星铁=6，绝区零=8） |

**各游戏 challenge_path 值**：

| 游戏   | x-rpc-challenge_path                                                         |
| ------ | ---------------------------------------------------------------------------- |
| 原神   | `https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote` |
| 星铁   | `https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/note`        |
| 绝区零 | `https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/note`    |

---

## 四、Widget API 专用头

Widget API 使用特殊 User-Agent，不需要 DS 签名：

```
User-Agent: WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0
```

Cookie 格式：`stuid={uid};stoken=v2_{token};mid={mid}`

---

## 五、设备指纹请求体（getFp 接口）

```json
{
  "seed_id": "16位随机十六进制字符串",
  "device_id": "deviceId的MD5（加上时间戳扰动）",
  "platform": "1",
  "seed_time": "Unix毫秒时间戳字符串",
  "ext_fields": "固定的iPhone设备信息JSON字符串",
  "app_name": "account_cn",
  "device_fp": "deviceId的MD5前13位（初始指纹）"
}
```

**ext_fields 示例**（国服，iPhone 12 Pro Max）：

```json
{
  "ramCapacity": "3746",
  "hasVpn": "0",
  "proxyStatus": "0",
  "screenBrightness": "0.550",
  "packageName": "com.miHoYo.mhybbs",
  "romRemain": "100513",
  "deviceName": "iPhone",
  "isJailBreak": "0",
  "model": "iPhone12,5",
  "IDFV": "{deviceId大写}",
  "osVersion": "17.2.1",
  "packageVersion": "2.20.1",
  "networkType": "WIFI"
}
```

> **注意**：PizzaHelperUnited 使用 `packageVersion: "2.20.1"`，本项目使用 `"2.104.0"`，两者均可正常工作。
