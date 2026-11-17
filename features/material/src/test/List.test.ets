import toolsViewModelTest from './ToolsViewModel.test';
import materialCalcViewModelTest from './MaterialCalcViewModel.test';
import materialTargetConfigModelsTest from './MaterialTargetConfigModels.test';
import genshinMaterialListViewModelTest from './GenshinMaterialListViewModel.test';
import starRailMaterialListViewModelTest from './StarRailMaterialListViewModel.test';
import zzzMaterialListViewModelTest from './ZZZMaterialListViewModel.test';
import genshinMaterialTargetConfigViewModelTest from './GenshinMaterialTargetConfigViewModel.test';
import starRailMaterialTargetConfigViewModelTest from './StarRailMaterialTargetConfigViewModel.test';
import zzzMaterialTargetConfigViewModelTest from './ZZZMaterialTargetConfigViewModel.test';
import materialCharacterSelectViewModelTest from './MaterialCharacterSelectViewModel.test';
import materialAmountUtilTest from './MaterialAmountUtil.test';
import materialListAggregatorTest from './MaterialListAggregator.test';
import materialRouteUtilTest from './MaterialRouteUtil.test';
import materialComputeUtilsTest from './MaterialComputeUtils.test';

export default function testsuite() {
  toolsViewModelTest();
  materialCalcViewModelTest();
  materialTargetConfigModelsTest();
  genshinMaterialListViewModelTest();
  starRailMaterialListViewModelTest();
  zzzMaterialListViewModelTest();
  genshinMaterialTargetConfigViewModelTest();
  starRailMaterialTargetConfigViewModelTest();
  zzzMaterialTargetConfigViewModelTest();
  materialCharacterSelectViewModelTest();
  materialAmountUtilTest();
  materialListAggregatorTest();
  materialRouteUtilTest();
  materialComputeUtilsTest();
}
