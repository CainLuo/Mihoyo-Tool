import homeViewModelTest from './HomeViewModel.test';
import homeCardPresenterTest from './HomeCardPresenter.test';
import homeDataLoaderTest from './HomeDataLoader.test';
import homeSyncCoordinatorTest from './HomeSyncCoordinator.test';
import homeListDataSourceTest from './HomeListDataSource.test';

export default function testsuite() {
  homeViewModelTest();
  homeCardPresenterTest();
  homeDataLoaderTest();
  homeSyncCoordinatorTest();
  homeListDataSourceTest();
}
