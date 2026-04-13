import abilityTest from './Ability.test';
// core 本地单元测试（在 entry@ohosTest 中编译验证）
import dsUtilTest from './core/DSUtilV2.test';
import mockServiceBaseTest from './core/MockServiceBase.test';
import syncDataTypeTest from './core/SyncDataType.test';
import rowModelsTest from './core/RowModels.test';
import starRailAvatarBasicParserTest from './core/StarRailAvatarBasicParser.test';
import genshinDailyNoteParserTest from './core/GenshinDailyNoteParser.test';
import starRailDailyNoteParserTest from './core/StarRailDailyNoteParser.test';
import zzzDailyNoteParserTest from './core/ZZZDailyNoteParser.test';

export default function testsuite() {
  abilityTest();
  dsUtilTest();
  mockServiceBaseTest();
  syncDataTypeTest();
  rowModelsTest();
  starRailAvatarBasicParserTest();
  genshinDailyNoteParserTest();
  starRailDailyNoteParserTest();
  zzzDailyNoteParserTest();
}