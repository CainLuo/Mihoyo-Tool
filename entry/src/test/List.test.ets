import localUnitTest from './LocalUnit.test';
import widget1x2ViewModelTest from './Widget1x2ViewModel.test';
import widget2x2ViewModelTest from './Widget2x2ViewModel.test';
import widget2x4ViewModelTest from './Widget2x4ViewModel.test';
import widget4x4ViewModelTest from './Widget4x4ViewModel.test';
import mainNavigationModeTest from './MainNavigationMode.test';
import mainDialogLabelsTest from './MainDialogLabels.test';

export default function testsuite() {
  localUnitTest();
  widget1x2ViewModelTest();
  widget2x2ViewModelTest();
  widget2x4ViewModelTest();
  widget4x4ViewModelTest();
  mainNavigationModeTest();
  mainDialogLabelsTest();
}
