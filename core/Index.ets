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
