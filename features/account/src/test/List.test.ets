import loginViewModelTest from './LoginViewModel.test';
import myViewModelTest from './MyViewModel.test';
import accountDetailViewModelTest from './AccountDetailViewModel.test';

export default function testsuite() {
  loginViewModelTest();
  myViewModelTest();
  accountDetailViewModelTest();
}
