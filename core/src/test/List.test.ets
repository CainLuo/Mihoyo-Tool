import dsUtilTest from './DSUtilV2.test';
import mockServiceBaseTest from './MockServiceBase.test';
import syncDataTypeTest from './SyncDataType.test';
import rowModelsTest from './RowModels.test';
import starRailAvatarBasicParserTest from './StarRailAvatarBasicParser.test';

export default function testsuite() {
  dsUtilTest();
  mockServiceBaseTest();
  syncDataTypeTest();
  rowModelsTest();
  starRailAvatarBasicParserTest();
}
