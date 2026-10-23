# 签名材料说明

## 环境与构建方式

| 环境 | Bundle ID | 构建产物 | 签名材料 |
| --- | --- | --- | --- |
| Release | `com.cainluo.miyoyo.tools` | signed HAP | `Certificates/release/` |
| UAT | `com.cainluo.miyoyo.tools.uat` | unsigned HAP | 模拟器不需要 |
| Mock | `com.cainluo.miyoyo.tools.mock` | unsigned HAP | 模拟器不需要 |

UAT / Mock 保留自己的后缀包名，`run.sh` 会优先找 signed HAP；没有时回退到 `*-unsigned.hap`。当前模拟器允许直接安装 unsigned HAP。

> 一套 `.p7b` 只能对应一个 `bundleName`。如果 UAT / Mock 要装到真机，必须为每个后缀包名单独准备调试 Profile；证书和私钥可以共用一套。

## 1. 模拟器运行

```bash
bash run.sh uat
bash run.sh mock
```

预期产物：

```text
entry/build/uat/outputs/uat/entry-uat-unsigned.hap
entry/build/mock/outputs/mock/entry-mock-unsigned.hap
```

## 2. Release

```bash
bash run.sh release
```

Release 必须生成签名 HAP：

```text
entry/build/release/outputs/release/entry-release-signed.hap
```

签名材料在 `Certificates/release/`，不要指向 UAT / Mock 的 Profile。

## 3. 真机安装 UAT / Mock（可选）

模拟器可以 unsigned 安装，真机通常不行。需要签名时：

1. 在 AGC 为对应后缀 Bundle ID 创建调试 Profile。
2. Profile 绑定同一套调试证书和真机 UDID（`hdc shell bm get -u`）。
3. 下载 `.p7b` 放到 `Certificates/dev/`，例如 `uat.p7b`、`mock.p7b`。
4. 在 `build-profile.json5` 给对应 product 增加 `signingConfig`，每个 product 指向自己的 `.p7b`。

示例：

```json5
{
  name: "uat",
  type: "HarmonyOS",
  material: {
    certpath: "/绝对路径/Certificates/dev/miyoyo-dev.cer",
    keyAlias: "Miyoyo",
    keyPassword: "<DevEco 加密后的密码>",
    profile: "/绝对路径/Certificates/dev/uat.p7b",
    signAlg: "SHA256withECDSA",
    storeFile: "/绝对路径/Certificates/Miyoyo.p12",
    storePassword: "<DevEco 加密后的密码>",
  },
}
```

Mock 同理，只改 `name` 和 `profile`。一套 Profile 不能同时给 `.uat` 和 `.mock` 使用。

## 4. 常见错误

| 现象 | 原因 |
| --- | --- |
| `Will skip sign` / `No signingConfig found` | 当前 product 没有配置签名，生成 unsigned HAP；UAT / Mock 模拟器运行属正常 |
| `The bundleName ... does not match` | Profile 的 `bundle-name` 与 product 的 `bundleName` 不一致 |
| 真机安装 unsigned HAP 失败 | 真机需要签名；按第 3 节准备对应 Profile |
| `Signature verification failed` | `.cer`、`.p7b`、`.p12` 不是同一套材料，或 keyAlias 填错 |
