import genshinCharDetailViewModelTest from './GenshinCharacterDetailViewModel.test';
import starRailCharacterDetailViewModelTest from './StarRailCharacterDetailViewModel.test';
import zzzCharacterDetailViewModelTest from './ZZZCharacterDetailViewModel.test';
import starRailPropertyUtilTest from './StarRailPropertyUtil.test';
import charDetailWindowSizeTest from './CharDetailWindowSize.test';

export default function testsuite() {
  genshinCharDetailViewModelTest();
  starRailCharacterDetailViewModelTest();
  zzzCharacterDetailViewModelTest();
  starRailPropertyUtilTest();
  charDetailWindowSizeTest();
}
