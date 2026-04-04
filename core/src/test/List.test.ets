import localUnitTest from './LocalUnit.test';
import queryBuilderTest from './QueryBuilder.test';
import modelsTest from './Models.test';
import dsUtilV2Test from './DSUtilV2.test';
import mockServiceBaseTest from './MockServiceBase.test';
import genshinDailyNoteParserTest from './GenshinDailyNoteParser.test';
import starRailDailyNoteParserTest from './StarRailDailyNoteParser.test';
import zzzDailyNoteParserTest from './ZZZDailyNoteParser.test';
import syncDataTypeTest from './SyncDataType.test';
import rowModelsTest from './RowModels.test';

export default function testsuite() {
  localUnitTest();
  queryBuilderTest();
  modelsTest();
  dsUtilV2Test();
  mockServiceBaseTest();
  genshinDailyNoteParserTest();
  starRailDailyNoteParserTest();
  zzzDailyNoteParserTest();
  syncDataTypeTest();
  rowModelsTest();
}
