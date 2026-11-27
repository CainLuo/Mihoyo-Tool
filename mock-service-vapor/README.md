# Mock Server（Swift + Vapor）

米游社 App 调试用的本地 Mock 服务。行为与 `mock-service/`（Node 版）逐接口对齐，
App 只需把 base URL 指向 `http://127.0.0.1:8787`，不需要任何 Mock 适配器。

数据直接复用仓库里的 `mock-service/fixtures`（224 份 JSON），**不复制**。

## 快速开始

```bash
cd mock-service-vapor
swift run mock-server
```

默认监听 `127.0.0.1:8787`，每个响应延迟 300ms。

```bash
swift run mock-server --port 9000 --host 0.0.0.0 --delay 0
swift run mock-server --fixtures ../mock-service/fixtures
swift run mock-server --help
```

| 参数 | 环境变量 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `--port` | `MOCK_PORT` | `8787` | 监听端口 |
| `--host` | `MOCK_HOST` | `127.0.0.1` | 监听地址，默认只允许本机 |
| `--delay` | `MOCK_DELAY` | `300` | 每个响应的模拟延迟（毫秒），`0` 关闭 |
| `--fixtures` | `MOCK_FIXTURES` | 自动查找 `mock-service/fixtures` | fixture 根目录 |

真机调试需要端口转发：

```bash
hdc rport tcp:8787 tcp:8787
```

## 端点

| 端点 | 说明 |
| --- | --- |
| `GET /` | 服务信息（名称、RPC / health 入口、当前延迟） |
| `GET /__health` | 健康检查：`ok`、fixture 数量、fixture 目录 |
| `POST /__mock/rpc` | 调试 RPC，见下 |
| `OPTIONS *` | CORS 预检，返回 204 |
| 其余 `GET` / `POST` | 按真实 API 路径直连 fixture |

### 直连代理

请求路径按 Node 版规则映射到 fixture 文件：

```
/game_record/app/genshin/api/dailyNote?role_id=109050292
→ 182692936/109050292/game_record_app_genshin_api_dailyNote.json
```

账号从 Cookie 的 `account_id`（其次 `stuid`，都没有回退 `1`）提取；
角色从 query 的 `role_id` / `uid` 或 body 的同名字段提取。
命中时原样回写文件字节；未命中返回 `{"retcode":0,"message":"success","data":{}}`，
不会用 404 让 App 走进错误分支。

### 调试 RPC

```bash
curl -s http://127.0.0.1:8787/__mock/rpc -d '{
  "kind": "fixture",
  "path": "/game_record/app/genshin/api/dailyNote?role_id=109050292",
  "cookie": "account_id=182692936"
}'
```

`kind` 取值：

- `fixture`：`path`（必填）、`cookie`、`roleId`、`avatarId`、`body`、`fallbackEmptyList`
- `account`：`method`、`mobile`、`captcha`、`stoken`
- `sign`：`method`、`cookie`、`gameBiz`

账号 Mock 固定数据（与 Node 版一致）：

| 手机号 | 账号 |
| --- | --- |
| `13800138000` | `182692936` |
| `13800138001` | `348366494` |

验证码固定 `111111`；stoken 形如 `mock_stoken_182692936`；
二维码固定返回账号 `182692936`。

## 目录结构

```
mock-service-vapor/
├── Package.swift
├── Sources/
│   ├── MockServerCLI/main.swift          命令行入口
│   └── MockServerCore/
│       ├── Configuration/                运行期配置
│       ├── Domain/                       JSON / 请求 / 响应 / 账号模型
│       ├── Fixtures/                     路径映射、解析、只读仓库
│       ├── Routing/                      query 解析、路由分类、直连代理与签到
│       ├── Validation/                   DS 生成/解析、请求校验
│       └── App/                          RPC 服务与 Vapor 装配
├── Tests/MockServerCoreTests/            204 个单元测试
└── docs/                                 设计与文件说明
```

核心层不 `import Vapor`，可以脱离网络单测；Vapor 只出现在 `App/`。

## 测试

```bash
cd mock-service-vapor
swift test
```

204 个用例，全部针对仓库内真实 fixture 断言（fixture 数量锁定为 224）。

## 说明

- 夹具只读且限制在根目录内，`../` 路径穿越会被拒绝。
- 请求体上限 8 MiB，超限返回 400。
- mock 服务**不校验** `DS` 签名，只提供解析与生成能力用于调试。
  标准公式生成的摘要与需求里给出的样本不一致，详见 `docs/Design.md`。
