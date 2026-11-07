import characterSortUtilTest from './CharacterSortUtil.test';
import gameIdUtilTest from './GameIdUtil.test';
import dialogDedupUtilTest from './DialogDedupUtil.test';
import colorUtilTest from './ColorUtil.test';
import accountRoleModelsTest from './AccountRoleModels.test';

export default function testsuite() {
  characterSortUtilTest();
  gameIdUtilTest();
  dialogDedupUtilTest();
  colorUtilTest();
  accountRoleModelsTest();
}
