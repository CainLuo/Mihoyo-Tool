// Core library export file

// Core initializer
export * from './src/main/ets/CoreInitializer';

// Network module
export * from './src/main/ets/network/APIs';
export * from './src/main/ets/network/ApiConfig';
export * from './src/main/ets/network/NetworkFactory';
export * from './src/main/ets/network/CookieManager';
export * from './src/main/ets/network/GeetestService';

// Database module
export * from './src/main/ets/database/RdbManager';
export * from './src/main/ets/database/QueryBuilder';
export * from './src/main/ets/database/GameDataDao';
export * from './src/main/ets/database/GameStatsDao';
export * from './src/main/ets/database/SyncMetaDao';

// Models
export * from './src/main/ets/models/GameDataRow';
export * from './src/main/ets/models/GameStatsRow';
export * from './src/main/ets/models/SyncMetaRow';

// Repository
export * from './src/main/ets/repository/AccountRepository';
export * from './src/main/ets/repository/AuthRepository';
export * from './src/main/ets/repository/CharacterRepository';
export * from './src/main/ets/repository/ActivityRepository';
export * from './src/main/ets/repository/GachaRepository';
export * from './src/main/ets/repository/DailyNoteRepository';

// Constants
export * from './src/main/ets/constants/ApiErrorCodes';
export * from './src/main/ets/constants/GenshinPropertyType';

// Utils module
export * from './src/main/ets/utils/TaskPoolUtil';

// Parsers
export * from './src/main/ets/parsers/genshin/GenshinDailyNoteParser';
export * from './src/main/ets/parsers/starrail/StarRailDailyNoteParser';
export * from './src/main/ets/parsers/zzz/ZZZDailyNoteParser';

// ── V2 新架构导出 ──────────────────────────────────────────────

// V2 核心初始化器
export * from './src/main/ets/CoreInitializerV2';

// V2 数据库层
export * from './src/main/ets/database/v2/RdbManagerV2';
export * from './src/main/ets/database/v2/BBSDao';
export * from './src/main/ets/database/v2/GenshinDao';
export * from './src/main/ets/database/v2/StarRailDao';
export * from './src/main/ets/database/v2/ZZZDao';
export * from './src/main/ets/database/v2/SyncMetaDaoV2';

// V2 数据模型
export * from './src/main/ets/models/v2/AccountRowV2';
export * from './src/main/ets/models/v2/GameRoleRowV2';
export * from './src/main/ets/models/v2/GenshinRows';
export * from './src/main/ets/models/v2/StarRailRows';
export * from './src/main/ets/models/v2/ZZZRows';
// 新版 SyncMetaRow 与旧版类名相同，使用具名导出避免冲突
export { SyncMetaRow as SyncMetaRowV2 } from './src/main/ets/models/v2/SyncMetaRow';

// V2 Repository 层
export * from './src/main/ets/repository/v2/GameRepository';
export * from './src/main/ets/repository/v2/BBSRepository';
export * from './src/main/ets/repository/v2/GenshinRepository';
export * from './src/main/ets/repository/v2/StarRailRepository';
export * from './src/main/ets/repository/v2/ZZZRepository';
export * from './src/main/ets/repository/v2/SignRepository';

// V2 网络层（抽象基类和环境枚举）
export * from './src/main/ets/network/v2/MihoyoApiService';
export * from './src/main/ets/network/v2/MihoyoEnvironment';

// V2 常量
export * from './src/main/ets/constants/SyncDataType';
export * from './src/main/ets/constants/GenshinPropertyType';
export * from './src/main/ets/constants/StarRailPropertyType';
export * from './src/main/ets/constants/ZZZPropertyId';
export * from './src/main/ets/constants/GameServer';
export * from './src/main/ets/database/v2/TableSchema';

// ── V2 网络层完整导出 ──────────────────────────────────────────

// Domain 和 Path 枚举
export * from './src/main/ets/network/v2/MihoyoDomain';
export * from './src/main/ets/network/v2/MihoyoAccountApiPath';
export * from './src/main/ets/network/v2/PassportApiPath';
export * from './src/main/ets/network/v2/GenshinApiPath';
export * from './src/main/ets/network/v2/StarRailApiPath';
export * from './src/main/ets/network/v2/ZZZApiPath';
export * from './src/main/ets/network/v2/SignApiPath';

// 请求头构建器
export * from './src/main/ets/network/v2/MihoyoHeaderBuilder';

// 配置和工具
export * from './src/main/ets/network/v2/ApiConfigV2';
export * from './src/main/ets/network/v2/DSUtilV2';

// Service 工厂
export * from './src/main/ets/network/v2/MihoyoApiServiceFactory';

// Release Service 实现
export * from './src/main/ets/network/v2/MihoyoAccountApiService';
export * from './src/main/ets/network/v2/GenshinApiService';
export * from './src/main/ets/network/v2/StarRailApiService';
export * from './src/main/ets/network/v2/ZZZApiService';
export * from './src/main/ets/network/v2/SignApiService';

// 业务错误类型（具名导出避免与旧版 GeetestService 冲突）
export { AuthExpiredError, GeetestRequiredError, GeetestSignRequiredError, RoleNotPublicError } from './src/main/ets/errors/ApiErrors';
export { GeetestCreateResult as GeetestCreateResultV2, GeetestVerifyInput as GeetestVerifyInputV2 } from './src/main/ets/errors/ApiErrors';

// Mock Service 实现
export * from './src/main/ets/network/v2/mock/MockServiceBase';
export * from './src/main/ets/network/v2/mock/MihoyoAccountMockService';
export * from './src/main/ets/network/v2/mock/GenshinMockService';
export * from './src/main/ets/network/v2/mock/StarRailMockService';
export * from './src/main/ets/network/v2/mock/ZZZMockService';
export * from './src/main/ets/network/v2/mock/SignMockService';
