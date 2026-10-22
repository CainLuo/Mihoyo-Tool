# 签名材料说明

本项目有三个运行环境，签名必须彼此独立：

| 环境 | Bundle ID | signingConfig | 当前状态 |
| --- | --- | --- | --- |
| Release | `com.cainluo.miyoyo.tools` | `release` | 已有正式证书 / Profile，可构建签名 HAP |
| UAT | `com.cainluo.miyoyo.tools.uat` | `uat` | **缺失**，构建为 unsigned |
| Mock | `com.cainluo.miyoyo.tools.mock` | `mock` | **缺失**，构建为 unsigned |

> 不允许把 `uat` / `mock` 指向 `release`，也不允许用修改旧证书、旧 Profile 的方式绕过签名。

## 1. 在 AGC 创建 UAT / Mock 材料

对 `com.cainluo.miyoyo.tools.uat` 和 `com.cainluo.miyoyo.tools.mock` 分别执行：

1. 在 Huawei AGC 创建对应 Bundle ID 的应用。
2. 创建 **调试证书**（Debug Certificate）。可以上传新的 CSR，也可以使用 DevEco Studio 生成的调试证书。
3. 创建 **调试 Profile**（Debug Profile），绑定：
   - 对应 Bundle ID；
   - 对应调试证书；
   - 需要安装的模拟器 / 真机 UDID。
4. 下载 `.cer` 和 `.p7b`，放到：
   - `Certificates/uat/`
   - `Certificates/mock/`

模拟器 UDID 可通过以下命令获取：

```bash
hdc shell bm get -u
```

## 2. 填写 build-profile.json5

在根目录 `build-profile.json5` 的 `app.signingConfigs` 中补入 `uat` / `mock`。字段与现有 `release` 配置一致：

```json5
{
  name: "uat",
  type: "HarmonyOS",
  material: {
    certpath: "/绝对路径/Certificates/uat/<uat>.cer",
    keyAlias: "<keyAlias>",
    keyPassword: "<DevEco 加密后的密码>",
    profile: "/绝对路径/Certificates/uat/<uat>.p7b",
    signAlg: "SHA256withECDSA",
    storeFile: "/绝对路径/Certificates/uat/<uat>.p12",
    storePassword: "<DevEco 加密后的密码>",
  },
},
{
  name: "mock",
  type: "HarmonyOS",
  material: {
    certpath: "/绝对路径/Certificates/mock/<mock>.cer",
    keyAlias: "<keyAlias>",
    keyPassword: "<DevEco 加密后的密码>",
    profile: "/绝对路径/Certificates/mock/<mock>.p7b",
    signAlg: "SHA256withECDSA",
    storeFile: "/绝对路径/Certificates/mock/<mock>.p12",
    storePassword: "<DevEco 加密后的密码>",
  },
},
```

`keyPassword` / `storePassword` 是 DevEco Studio 生成的加密值，不要手写明文密码。最稳妥的方式是在 DevEco Studio 的 **File → Project Structure → Signing Configs** 中为 `uat` / `mock` 分别配置，让 IDE 写入这两个条目。

## 3. 验证

```bash
# UAT
bash run.sh uat
# 期望：entry/build/uat/outputs/uat/entry-uat-signed.hap

# Mock
bash run.sh mock
# 期望：entry/build/mock/outputs/mock/entry-mock-signed.hap

# Release
bash run.sh release
# 期望：entry/build/release/outputs/release/entry-release-signed.hap
```

安装后确认三个包的 Bundle ID 分别为：

```bash
hdc shell bm dump -n com.cainluo.miyoyo.tools.uat
hdc shell bm dump -n com.cainluo.miyoyo.tools.mock
hdc shell bm dump -n com.cainluo.miyoyo.tools
```

## 4. 常见错误

| 现象 | 原因 |
| --- | --- |
| `Will skip sign 'hos_hap'` | 对应 `signingConfigs` 条目不存在，Hvigor 生成 unsigned HAP |
| `The bundleName in the profile does not match` | Profile 绑定的 Bundle ID 与 product 不一致 |
| `The device is not in the profile` | Profile 没有加入当前模拟器 / 真机 UDID |
| `Signature verification failed` | `.cer`、`.p7b`、`.p12` 不是同一套材料，或 keyAlias 填错 |
