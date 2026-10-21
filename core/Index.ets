// Core library export file

// Network module
export * from './src/main/ets/base/network/APIs';
export * from './src/main/ets/base/network/HttpTypes';
export * from './src/main/ets/base/network/BaseApiService';
export * from './src/main/ets/base/network/CookieManager';
export * from './src/main/ets/base/network/GeetestService';

// Database module

// Models

// Repository
export * from './src/main/ets/MihoyoKit/repository/AuthRepository';

// Constants
export * from './src/main/ets/common/constants/ApiErrorCodes';
export * from './src/main/ets/GenshinKit/constants/GenshinPropertyType';

// Parsers
export * from './src/main/ets/GenshinKit/parser/GenshinDailyNoteParser';
export * from './src/main/ets/GenshinKit/parser/GenshinComputeParser';
export * from './src/main/ets/StarRailKit/parser/StarRailDailyNoteParser';
export * from './src/main/ets/StarRailKit/parser/StarRailComputeParser';
export * from './src/main/ets/ZZZKit/parser/ZZZDailyNoteParser';
export * from './src/main/ets/ZZZKit/parser/ZZZComputeParser';

// ── 核心导出 ──────────────────────────────────────────────────

// 核心初始化器
export * from './src/main/ets/CoreInitializer';

// 数据库层
export * from './src/main/ets/database/RdbManager';
export * from './src/main/ets/MihoyoKit/db/BBSDao';
export * from './src/main/ets/GenshinKit/db/GenshinDao';
export * from './src/main/ets/StarRailKit/db/StarRailDao';
export * from './src/main/ets/StarRailKit/db/StarRailDBManager';
export * from './src/main/ets/ZZZKit/db/ZZZDao';
export * from './src/main/ets/sync/db/SyncMetaDao';
export * from './src/main/ets/common/material/db/MaterialBagDao';
export * from './src/main/ets/GenshinKit/db/MaterialBagDao';
export * from './src/main/ets/StarRailKit/db/MaterialBagDao';
export * from './src/main/ets/ZZZKit/db/MaterialBagDao';
export * from './src/main/ets/common/material/db/MaterialTargetConfigDao';
export * from './src/main/ets/GenshinKit/db/MaterialTargetConfigDao';
export * from './src/main/ets/StarRailKit/db/MaterialTargetConfigDao';
export * from './src/main/ets/ZZZKit/db/MaterialTargetConfigDao';
// 数据模型
export * from './src/main/ets/MihoyoKit/model/AccountRow';
export * from './src/main/ets/MihoyoKit/model/GameRoleRow';
export * from './src/main/ets/GenshinKit/model/GenshinRows';
export * from './src/main/ets/StarRailKit/model/StarRailRows';
export * from './src/main/ets/ZZZKit/model/ZZZRows';
export * from './src/main/ets/sync/model/GameDataSummary';
export * from './src/main/ets/sync/model/SyncMetaRow';
export * from './src/main/ets/sync/model/SyncTask';
export * from './src/main/ets/GenshinKit/model/GenshinCharacterDetailRaw';
export * from './src/main/ets/StarRailKit/model/StarRailAvatarDetailRaw';
export * from './src/main/ets/ZZZKit/model/ZZZAvatarDetailRaw';
export * from './src/main/ets/common/material/model/MaterialBagRow';
export * from './src/main/ets/common/material/model/MaterialTargetConfigRow';
// Repository 层
export * from './src/main/ets/sync/GameRepository';
export * from './src/main/ets/MihoyoKit/repository/BBSRepository';
export * from './src/main/ets/GenshinKit/repository/GenshinRepository';
export * from './src/main/ets/StarRailKit/repository/StarRailRepository';
export * from './src/main/ets/ZZZKit/repository/ZZZRepository';
export * from './src/main/ets/MihoyoKit/repository/SignRepository';
export * from './src/main/ets/sync/SyncQueueRunner';
export * from './src/main/ets/common/material/repository/MaterialBagRepository';
export * from './src/main/ets/common/material/repository/MaterialTargetConfigRepository';

// 网络层（抽象基类）
export * from './src/main/ets/base/network/MihoyoApiService';

// 环境枚举和管理器（统一入口）
export * from './src/main/ets/common/constants/AppEnv';
export * from './src/main/ets/common/constants/AppEnvManager';

// 日志工具（core/entry 共用）
export * from './src/main/ets/base/utils/Logger';

// API 错误处理工具
export * from './src/main/ets/base/utils/ApiErrorHandler';

// 日志系统
export * from './src/main/ets/base/log/ApiLogEntry';
export * from './src/main/ets/base/log/ApiLogSystem';
export * from './src/main/ets/base/log/LogFileManager';
export * from './src/main/ets/base/log/LogExporter';

// 常量
export * from './src/main/ets/common/constants/SyncDataType';
export * from './src/main/ets/GenshinKit/constants/GenshinPropertyType';
export * from './src/main/ets/StarRailKit/constants/StarRailPropertyType';
export * from './src/main/ets/ZZZKit/constants/ZZZPropertyId';
export * from './src/main/ets/common/constants/GameServer';
export * from './src/main/ets/common/constants/GameId';
export * from './src/main/ets/common/constants/ApiConstants';
export * from './src/main/ets/GenshinKit/constants/GenshinElement';
export * from './src/main/ets/StarRailKit/constants/StarRailElement';
export * from './src/main/ets/ZZZKit/constants/ZZZElement';
export * from './src/main/ets/ZZZKit/constants/ZZZEnums';
export * from './src/main/ets/database/TableSchema';

// ── 网络层完整导出 ──────────────────────────────────────────

// 请求头常量
export * from './src/main/ets/base/network/MihoyoHeaderKey';

// Domain 和 Path 枚举
export * from './src/main/ets/base/network/MihoyoDomain';
export * from './src/main/ets/MihoyoKit/api/MihoyoAccountApiPath';
export * from './src/main/ets/MihoyoKit/api/PassportApiPath';
export * from './src/main/ets/MihoyoKit/api/QRCodeApiPath';
export * from './src/main/ets/GenshinKit/api/GenshinApiPath';
export * from './src/main/ets/StarRailKit/api/StarRailApiPath';
export * from './src/main/ets/ZZZKit/api/ZZZApiPath';
export * from './src/main/ets/MihoyoKit/api/SignApiPath';

// 请求头构建器
export * from './src/main/ets/base/network/MihoyoHeaderBuilder';

// 配置和工具
export * from './src/main/ets/base/network/ApiConfig';
export * from './src/main/ets/base/network/DSUtil';

// Service 工厂
export * from './src/main/ets/ApiServiceFactory';

// Release Service 实现
export * from './src/main/ets/MihoyoKit/api/MihoyoAccountApiService';
export * from './src/main/ets/GenshinKit/api/GenshinApiService';
export * from './src/main/ets/StarRailKit/api/StarRailApiService';
export * from './src/main/ets/ZZZKit/api/ZZZApiService';
export * from './src/main/ets/MihoyoKit/api/SignApiService';

// 业务错误类型（新的统一错误类）
export {
  SyncErrorKind,
  SyncError,
  SyncErrorFactory
} from './src/main/ets/base/errors/ApiErrors';

// 旧的错误类（deprecated，保留兼容）
export {
  GeetestCreateResult,
  GeetestVerifyInput,
  AuthExpiredErrorClass,
  AuthExpiredError,
  GeetestRequiredErrorClass,
  GeetestRequiredError,
  RoleNotPublicErrorClass,
  RoleNotPublicError
} from './src/main/ets/base/errors/ApiErrors';

// Cookie 刷新
export * from './src/main/ets/base/cookie/ColdStartCookieChecker';
export * from './src/main/ets/base/cookie/CookieRefreshCoordinator';

