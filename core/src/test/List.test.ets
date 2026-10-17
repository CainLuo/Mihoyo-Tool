import dsUtilTest from './DSUtilV2.test';
import mockServiceBaseTest from './MockServiceBase.test';
import syncDataTypeTest from './SyncDataType.test';
import rowModelsTest from './RowModels.test';
import starRailAvatarBasicParserTest from './StarRailAvatarBasicParser.test';
import genshinDailyNoteParserTest from './GenshinDailyNoteParser.test';
import starRailDailyNoteParserTest from './StarRailDailyNoteParser.test';
import zzzDailyNoteParserTest from './ZZZDailyNoteParser.test';
import coldStartCookieCheckerTest from './ColdStartCookieChecker.test';
import genshinComputeParserTest from './GenshinComputeParser.test';
import starRailComputeParserTest from './StarRailComputeParser.test';
import zzzComputeParserTest from './ZZZComputeParser.test';

export default function testsuite() {
  dsUtilTest();
  mockServiceBaseTest();
  syncDataTypeTest();
  rowModelsTest();
  starRailAvatarBasicParserTest();
  genshinDailyNoteParserTest();
  starRailDailyNoteParserTest();
  zzzDailyNoteParserTest();
  coldStartCookieCheckerTest();
  genshinComputeParserTest();
  starRailComputeParserTest();
  zzzComputeParserTest();
}
