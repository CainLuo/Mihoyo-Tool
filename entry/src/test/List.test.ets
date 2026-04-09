import localUnitTest from './LocalUnit.test';
import homeViewModelTest from './HomeViewModel.test';
import charactersViewModelTest from './CharactersViewModel.test';
import loginViewModelTest from './LoginViewModel.test';
import myViewModelTest from './MyViewModel.test';
import accountDetailViewModelTest from './AccountDetailViewModel.test';
import genshinDailyDetailViewModelTest from './GenshinDailyDetailViewModel.test';
import genshinCharDetailViewModelTest from './GenshinCharacterDetailViewModel.test';

export default function testsuite() {
  localUnitTest();
  homeViewModelTest();
  charactersViewModelTest();
  loginViewModelTest();
  myViewModelTest();
  accountDetailViewModelTest();
  genshinDailyDetailViewModelTest();
  genshinCharDetailViewModelTest();
}