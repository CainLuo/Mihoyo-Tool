// Core library export file

// Network module
export * from './src/main/ets/network/APIs';
export * from './src/main/ets/network/NetworkFactory';
export * from './src/main/ets/network/CookieManager';
export * from './src/main/ets/network/GeetestService';

// Database module

// Models

// Repository
export * from './src/main/ets/repository/AuthRepository';

// Constants
export * from './src/main/ets/constants/ApiErrorCodes';
export * from './src/main/ets/constants/GenshinPropertyType';

// Parsers
export * from './src/main/ets/parsers/genshin/GenshinDailyNoteParser';
export * from './src/main/ets/parsers/genshin/GenshinComputeParser';
export * from './src/main/ets/parsers/starrail/StarRailDailyNoteParser';
export * from './src/main/ets/parsers/starrail/StarRailComputeParser';
export * from './src/main/ets/parsers/zzz/ZZZDailyNoteParser';
export * from './src/main/ets/parsers/zzz/ZZZComputeParser';

// ── 核心导出 ──────────────────────────────────────────────────

// 核心初始化器
export * from './src/main/ets/CoreInitializer';

// 数据库层
export * from './src/main/ets/database/RdbManager';
export * from './src/main/ets/database/BBSDao';
export * from './src/main/ets/database/GenshinDao';
export * from './src/main/ets/database/StarRailDao';
export * from './src/main/ets/database/StarRailDBManager';
export * from './src/main/ets/database/ZZZDao';
export * from './src/main/ets/database/SyncMetaDao';
export * from './src/main/ets/database/MaterialBagDao';
export * from './src/main/ets/database/MaterialTargetConfigDao';
// 数据模型
export * from './src/main/ets/models/AccountRow';
export * from './src/main/ets/models/GameRoleRow';
export * from './src/main/ets/models/GenshinRows';
export * from './src/main/ets/models/StarRailRows';
export * from './src/main/ets/models/ZZZRows';
export * from './src/main/ets/models/GameDataSummary';
export * from './src/main/ets/models/SyncMetaRow';
export * from './src/main/ets/models/SyncTask';
export * from './src/main/ets/models/GenshinCharacterDetailRaw';
export * from './src/main/ets/models/StarRailAvatarDetailRaw';
export * from './src/main/ets/models/ZZZAvatarDetailRaw';
export * from './src/main/ets/models/MaterialBagRow';
export * from './src/main/ets/models/MaterialTargetConfigRow';
// Repository 层
export * from './src/main/ets/repository/GameRepository';
export * from './src/main/ets/repository/BBSRepository';
export * from './src/main/ets/repository/GenshinRepository';
export * from './src/main/ets/repository/StarRailRepository';
export * from './src/main/ets/repository/ZZZRepository';
export * from './src/main/ets/repository/SignRepository';
export * from './src/main/ets/repository/SyncQueueRunner';
export * from './src/main/ets/repository/MaterialBagRepository';
export * from './src/main/ets/repository/MaterialTargetConfigRepository';

// 网络层（抽象基类）
export * from './src/main/ets/network/MihoyoApiService';

// 环境枚举和管理器（统一入口）
export * from './src/main/ets/constants/AppEnv';
export * from './src/main/ets/constants/AppEnvManager';

// 日志工具（core/entry 共用）
export * from './src/main/ets/utils/Logger';

// API 错误处理工具
export * from './src/main/ets/utils/ApiErrorHandler';

// 日志系统
export * from './src/main/ets/log/ApiLogEntry';
export * from './src/main/ets/log/ApiLogSystem';
export * from './src/main/ets/log/LogFileManager';
export * from './src/main/ets/log/LogExporter';

// 常量
export * from './src/main/ets/constants/SyncDataType';
export * from './src/main/ets/constants/GenshinPropertyType';
export * from './src/main/ets/constants/StarRailPropertyType';
export * from './src/main/ets/constants/ZZZPropertyId';
export * from './src/main/ets/constants/GameServer';
export * from './src/main/ets/constants/GameId';
export * from './src/main/ets/constants/ApiConstants';
export * from './src/main/ets/constants/GenshinElement';
export * from './src/main/ets/constants/StarRailElement';
export * from './src/main/ets/constants/ZZZElement';
export * from './src/main/ets/constants/ZZZEnums';
export * from './src/main/ets/database/TableSchema';

// ── 网络层完整导出 ──────────────────────────────────────────

// 请求头常量
export * from './src/main/ets/network/MihoyoHeaderKey';

// Domain 和 Path 枚举
export * from './src/main/ets/network/MihoyoDomain';
export * from './src/main/ets/network/MihoyoAccountApiPath';
export * from './src/main/ets/network/PassportApiPath';
export * from './src/main/ets/network/QRCodeApiPath';
export * from './src/main/ets/network/GenshinApiPath';
export * from './src/main/ets/network/StarRailApiPath';
export * from './src/main/ets/network/ZZZApiPath';
export * from './src/main/ets/network/SignApiPath';

// 请求头构建器
export * from './src/main/ets/network/MihoyoHeaderBuilder';

// 配置和工具
export * from './src/main/ets/network/ApiConfig';
export * from './src/main/ets/network/DSUtil';

// Service 工厂
export * from './src/main/ets/network/MihoyoApiServiceFactory';

// Release Service 实现
export * from './src/main/ets/network/MihoyoAccountApiService';
export * from './src/main/ets/network/GenshinApiService';
export * from './src/main/ets/network/StarRailApiService';
export * from './src/main/ets/network/ZZZApiService';
export * from './src/main/ets/network/SignApiService';

// 业务错误类型
export { AuthExpiredError, GeetestRequiredError, RoleNotPublicError } from './src/main/ets/errors/ApiErrors';
export { GeetestCreateResult, GeetestVerifyInput } from './src/main/ets/errors/ApiErrors';

// Cookie 刷新
export * from './src/main/ets/cookie/ColdStartCookieChecker';
export * from './src/main/ets/cookie/CookieRefreshCoordinator';

// Mock Service 实现
export * from './src/main/ets/network/mock/MockServiceBase';
export * from './src/main/ets/network/mock/MihoyoAccountMockService';
export * from './src/main/ets/network/mock/GenshinMockService';
export * from './src/main/ets/network/mock/StarRailMockService';
export * from './src/main/ets/network/mock/ZZZMockService';
export * from './src/main/ets/network/mock/SignMockService';
