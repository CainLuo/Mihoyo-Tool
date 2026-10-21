# Core Kits 已知问题与暂缓项

> 状态：**已记录，暂不改代码**
> 更新时间：2026-10-21
> 原则：当前构建和既有功能可运行；header / retcode 未采集项保持现状，不用静态推断修改行为。任何修复必须等真机、抓包或明确需求，不把“参考项目这样做”直接当成线上结论。
>
> 相关文档：[`API-Baseline.md`](API-Baseline.md) §2.2 静态参考矩阵、[`APIService.md`](APIService.md) §8.6 / §8.7、[`Mock.md`](Mock.md)。

---

## 1. 运行时未采集（不阻塞 Phase 1.2）

| ID | 项目 | 当前状态 | 为什么暂不改 | 后续动作 |
| --- | --- | --- | --- | --- |
| R-01 | header / DS / retcode 实际抓包 | 只有静态参考；`API-Baseline.md` 仍为“运行时未采集” | 当前代码可运行，静态参考存在冲突 | 任务完成后用 Proxyman + debug 包补采；见 `APIService.md` §8.6 |
| R-02 | BBS 账号 / 角色 / 战绩卡片 header | `client_type=1` + DS v2 + `Referer: app.mihoyo.com` | 本项目历史 App 抓包支持 `client_type=1`；TeyvatGuide / Pizza 用 `5` + X4 | 真机确认 `getUserFullInfo` / `getGameRoles` / `getGameRecordCard`；不要仅凭 SDK 推断 |
| R-03 | 二维码登录 header | `ddxf5dufpuyo` + `HYPContainer/1.3.3.182` + `client_type=3`、无 DS | Pizza / 当前实现与 TeyvatGuide 当前源码（`bll8iq97cem8` + Capture/2.2.0 + X4）冲突 | 真机扫码验证；两组不要混用 |
| R-04 | `cookie_token` 的 client_type | 当前 `getCookieAccountInfoBySToken` 用 `5` | TeyvatGuide 默认 `2`，Pizza 用 `5`；两边都有依据 | 失败时再对比；暂不改 |
| R-05 | 便笺 / Widget header | `buildPizza`：app 2.40.1、UA 2.40.1、page `3.1.3_#/rpg` | 与 Pizza 一致；历史 App 抓包是 2.102.0 / 2.115.0 + tool_verison / 按游戏 page + device_name | 真机确认便笺和 Widget；`addNoteCaptureHeaders` 当前未调用，不要顺手启用 |
| R-06 | HTTP 非 200 / 超时 | `HttpError` 已实现；`statusCode=0` 表示无响应 | 没有真实 401/500/断网记录 | 在真机或本地代理制造 401/500/超时各一次 |
| R-07 | Mock 数据链路 | `mock` product 可构建，但仍走真实 API | Swift-Vapor local service / base URL 覆盖未实现 | 见 `Mock.md`；Phase 4 处理，不要误判为已可用 |
| R-08 | 真机功能回归 | 登录、便笺、角色、养成计算、签到未在本轮真机验证 | 只有构建和 grep 验收 | 有 `hdc` target 时按第 5 节清单跑一轮 |

---

## 2. 已知参考差异（当前保持原样）

| ID | 项目 | 差异 | 当前决定 |
| --- | --- | --- | --- |
| D-01 | `getSignInfo` / `getSignReward` 参数 | 当前没有 `lang` / `act_id` 等参数，与 TeyvatGuide 不同；目前无业务调用方 | 保持原样，不修改；等签到功能真正接入时再处理 |
| D-02 | `10307` 服务器维护 | PizzaHelperUnited 有专门映射；当前按普通业务错误处理 | 暂不加常量 / 分支，避免无调用方代码 |
| D-03 | `-1002` / `1008` | `ACCOUNT_NOT_FOUND=-1002` 表示游戏账号未绑定，不是 `1008` 用户信息不匹配；当前无调用方 | 常量值和注释已纠正，不新增行为 |
| D-04 | 指纹错误类型 | `ApiErrorHandler` 没有专门的指纹错误类型；`FingerprintReporter` + `SyncQueueRunner` 已处理 5003 / 10041 | 保持现状；不在迁移收尾阶段扩展错误体系 |
| D-05 | `getGameRecordCard` 路径 | 当前用 SDK 的 `/game_record/app/card/wapi/...`；历史 App 抓包是 `/game_record/card/api/...` | 保留 SDK 路径；只记录，不改 |
| D-06 | `addNoteCaptureHeaders` | 方法存在但未被调用 | 保留为后续真机对照项；不要因静态参考直接启用 |
| D-07 | `HttpService` 默认 header / Cookie 覆盖 | 旧 transport 已删除；现在由具体 API 显式设置 header | 以 service 显式 header 为准；真机验证账号 / BBS 路径 |

> 这些问题只记录，不在 Phase 1.2 目录重组时顺手修改。目录重组必须保持请求行为不变。

---

## 3. 下一步：Phase 1.2（目录骨架，不改业务行为）

按 `Plan.md` 的顺序，Phase 1.1 BaseApiService 已收尾；下一步不是继续改 header / retcode，而是做 **Phase 1.2 结构整理**：

1. 建 `base/`、`common/`、`db/`、`sync/` 目录骨架。
2. 按 `Plan.md` §3.3 的共享文件清单，用 `git mv` 迁移网络基础设施、`log/`、`errors/`、`utils/`、`cookie/` 等公共文件。
3. 更新相对 import 和 `core/Index.ets`，不改 URL / header / DS / retcode / 上报逻辑。
4. 每迁移一组就构建四个 product；最后跑 `test-core.sh` / `test-entry.sh`。
5. 用 `git grep` 检查旧路径 / 旧 transport 残留。
6. Phase 1.2 完成后再进入 Phase 2：Genshin → StarRail → ZZZ → Mihoyo 拆 Kit。

### Phase 1.2 的边界

- 不动 `entry` 页面 / ViewModel / 路由。
- 不动业务 Service 的 URL / header / DS / Cookie / 上报逻辑。
- 不动 `Mock.md` 涉及的 base URL 方案；`baseUrlType` 继续保持 no-op。
- 根目录 `internal/core` 历史副本不动。
- 已知问题 R-01 ~ R-08、D-01 ~ D-07 继续挂起，不阻塞目录整理。

---

## 4. 完成 Phase 1.2 后的检查

- [ ] `core/src` 下共享文件只在 `base/`（或约定目录）出现，没有重复副本
- [ ] `core/Index.ets` 导出符号不变
- [ ] 四个 product 构建通过
- [ ] `test-core.sh` / `test-entry.sh` 通过
- [ ] `grep` 无旧路径 / 旧 transport 引用
- [ ] 没有修改业务请求行为
- [ ] 已知问题仍保留在本文件，未因搬文件而丢失

---

## 5. 真机回归清单（有设备时执行）

- [ ] 手机号登录 / 二维码登录 / Cookie 登录
- [ ] 账号详情、游戏角色列表、战绩卡片
- [ ] 原神 / 星铁 / 绝区零便笺与 Widget
- [ ] 原神 / 星铁 / 绝区零角色列表与详情
- [ ] 原神 / 星铁 / 绝区零养成计算
- [ ] 签到信息 / 签到（当前有调用方时）
- [ ] HTTP 401 / 500 / 断网 / 超时各一次
- [ ] 1034 / 10035 的 Geetest 提示，5003 / 10041 的指纹提示

> 回归结果只记录脱敏摘要；Cookie、token、`device_fp`、`device_id`、完整 HAR 不进入仓库。
