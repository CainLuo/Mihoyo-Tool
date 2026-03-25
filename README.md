# Mihoyo-Tool

HarmonyOS NEXT 米游社工具箱，基于 ArkTS + ArkUI V2 开发。

## 开发环境

- DevEco Studio 6.0.2
- HarmonyOS NEXT API 18（SDK 6.0.2）
- 目标设备：Phone / Tablet / 2in1

## 已知问题

### 修改 Bundle Name 后 DevEco Studio 无法启动应用

**现象**：修改 `AppScope/app.json5` 中的 `bundleName` 后，执行 Clean Project + Run，应用能正常安装到模拟器，但 DevEco Studio 报错：

```
error: failed to start ability. Error Code: 10104001
Error Message: The specified ability does not exist
```

**根因**：DevEco Studio 6.0 存在缓存 bug，改完 bundle name 后 IDE 内部的启动命令仍然使用旧的 bundle name，即使清除项目缓存（`Build → Clean Project`）和 IDE 系统缓存（`~/Library/Caches/DevEco Studio/`）也无法解决。

**验证方式**：用 hdc 手动启动新 bundle name 完全正常：

```bash
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc \
  -t 127.0.0.1:5555 shell aa start -b <新bundleName> -a EntryAbility
```

**临时解决方案**：在 `Run → Edit Configurations → entry → Launch Flags` 中填入：

```
-b <新bundleName> -a EntryAbility
```

这样 DevEco Studio 会用指定的 bundle name 启动，绕过缓存问题。

**正式修改 Bundle Name 的完整流程**（上线前执行）：

1. 修改 `AppScope/app.json5` 中的 `bundleName`
2. `Build → Clean Project`
3. 模拟器/真机上卸载旧应用
4. 在 Run Configuration 的 `Launch Flags` 填入新 bundle name
5. 重新 Run
