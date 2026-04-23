# Error Codes（错误码）

## 一、MiHoYoAPIError 枚举映射

PizzaHelperUnited 将所有 retcode 映射为 `MiHoYoAPIError` 枚举，源码位于：
`PZKit/Sources/PZAccountKit/HoYoAPIs/Common/HoYo_Models/APIError.swift`

```swift
public init(retcode: Int, message: String) {
    self = switch retcode {
    case 1034, 10035: .verificationNeeded
    case 5003, 10041: .fingerPrintInvalidOrMissing
    case 10102: .insufficientDataVisibility
    case -100, 10001: .reloginRequired
    case 10307: .serverUnderMaintenanceUpgrade
    case 403 where message.contains("Our services are not available in your country or region"):
        .countryRegionRestriction
    default: .other(retcode: retcode, message: message)
    }
}
```

---

## 二、错误码详细说明

### retcode = 1034 / 10035 → `.verificationNeeded`（需要 Geetest 验证）

**含义**：米游社服务端检测到异常请求，要求完成人机验证。

**触发场景**：

- 短时间内频繁请求 game_record 接口
- device_fp 为初始指纹（MD5 前 13 位），未通过真实设备验证
- 请求头中缺少必要的 Challenge 头

**处理方式**：

1. 调用 `createVerification` 接口申请 Geetest 任务（返回 gt + challenge）
2. 展示 Geetest 验证码 UI，等待用户完成验证
3. 调用 `verifyVerification` 接口提交验证结果，换取新 challenge
4. 携带新 challenge 重新发起原始请求（注入 `x-rpc-challenge` 头）

**降级方案**：

- 若 Cookie 中包含 `stoken=v2_xxx`，可降级到 Widget API（无 Geetest 验证）
- Widget API 返回数据是完整便笺的子集

---

### retcode = 5003 / 10041 → `.fingerPrintInvalidOrMissing`（设备指纹无效）

**含义**：`x-rpc-device_fp` 请求头缺失或无效。

**触发场景**：

- 未调用 `getDeviceFingerPrint` 接口获取真实指纹
- 使用了初始指纹（deviceId MD5 前 13 位）且被服务端识别

**处理方式**：

1. 调用 `/device-fp/api/getFp` 接口重新获取真实 device_fp
2. 更新缓存的 device_fp
3. 重新发起原始请求

---

### retcode = -100 / 10001 → `.reloginRequired`（需要重新登录）

**含义**：Cookie 已失效或过期，需要用户重新登录。

**触发场景**：

- ltoken / cookie_token 过期（通常 30 天）
- stoken 过期（通常 24-48 小时）
- Cookie 被手动清除或在其他设备上登出

**处理方式**：

1. 尝试用 stoken 刷新 ltoken 和 cookie_token
2. 若 stoken 也已过期，提示用户重新登录
3. 清除本地存储的 Cookie

> **本项目补充**：`-10001` 也表示 Cookie 无效，应与 `-100` / `10001` 同等处理。

---

### retcode = 10102 → `.insufficientDataVisibility`（数据可见性不足）

**含义**：用户未公开战绩，无法查看数据。

**触发场景**：

- 用户在米游社设置中关闭了"公开战绩"

**处理方式**：

- 提示用户前往米游社 App 开启"公开战绩"设置
- 不重试，直接展示错误提示

---

### retcode = 10307 → `.serverUnderMaintenanceUpgrade`（服务器维护中）

**含义**：米游社服务器正在维护或升级。

**处理方式**：

- 提示用户稍后重试
- 不重试，等待维护结束

---

### retcode = 403（含特定 message）→ `.countryRegionRestriction`（地区限制）

**含义**：当前国家/地区不支持访问该服务。

**触发条件**：`message` 包含 `"Our services are not available in your country or region"`

**处理方式**：

- 提示用户该地区不支持
- 建议使用 VPN 或切换到对应区域的账号

---

### retcode = -2 → 特殊处理（Ledger API）

**含义**：Ledger 数据不存在（账号从未使用过该功能）。

**处理方式**：

- 静默忽略，不向用户展示错误
- 源码：`case let MiHoYoAPIError.other(retCode, _) where retCode == -2: break`

---

### retcode = -9999 → URL 构建失败

**含义**：内部错误，URL 构建失败。

**处理方式**：

- 提示用户联系开发者
- 记录详细错误日志

---

### retcode = -114514 → JSON 解析失败

**含义**：内部错误，API 响应 JSON 解析失败（非标准格式）。

**处理方式**：

- 展示调试信息
- 记录原始响应内容

---

### retcode = -999 → 二维码 URL 解析失败

**含义**：二维码登录时，从响应 URL 中提取 ticket 失败。

**处理方式**：

- 提示用户重新获取二维码

---

### retcode = 其他 → `.other(retcode, message)`

**处理方式**：

- 展示服务器返回的 message 字符串
- 格式：`[HoYoAPIErr] Ret: {retcode}; Msg: {message}`

---

## 三、错误处理流程图

```
API 响应
  ↓
retcode == 0 → 解析 data 字段，返回成功结果
  ↓
retcode != 0
  ├─ 1034 / 10035 → 触发 Geetest 验证流程
  │     ├─ Cookie 含 stoken=v2_ → 降级 Widget API
  │     └─ 无 stoken_v2 → 展示 Geetest 验证码
  ├─ 5003 / 10041 → 重新获取 device_fp，重试
  ├─ -100 / 10001 / -10001 → 刷新 Cookie，失败则提示重新登录
  ├─ 10102 → 提示用户开启公开战绩
  ├─ 10307 → 提示服务器维护中
  ├─ 403（地区限制） → 提示地区不支持
  ├─ -2（Ledger 无数据） → 静默忽略
  └─ 其他 → 展示服务器错误信息
```
