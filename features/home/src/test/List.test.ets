import homeViewModelTest from './HomeViewModel.test';
import homeCardPresenterTest from './HomeCardPresenter.test';
import homeDataLoaderTest from './HomeDataLoader.test';
import homeSyncCoordinatorTest from './HomeSyncCoordinator.test';

export default function testsuite() {
  homeViewModelTest();
  homeCardPresenterTest();
  homeDataLoaderTest();
  homeSyncCoordinatorTest();
}
