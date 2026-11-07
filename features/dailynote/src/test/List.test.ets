import genshinDailyDetailViewModelTest from './GenshinDailyDetailViewModel.test';
import starRailDailyDetailViewModelTest from './StarRailDailyDetailViewModel.test';
import zzzDailyDetailViewModelTest from './ZZZDailyDetailViewModel.test';
import dailyNoteLoaderTest from './DailyNoteLoader.test';
import expeditionMapperTest from './ExpeditionMapper.test';
import dailyNoteModelsTest from './DailyNoteModels.test';

export default function testsuite() {
  genshinDailyDetailViewModelTest();
  starRailDailyDetailViewModelTest();
  zzzDailyDetailViewModelTest();
  dailyNoteLoaderTest();
  expeditionMapperTest();
  dailyNoteModelsTest();
}
