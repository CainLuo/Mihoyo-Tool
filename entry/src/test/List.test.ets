import localUnitTest from './LocalUnit.test';
import homeViewModelTest from './HomeViewModel.test';
import charactersViewModelTest from './CharactersViewModel.test';
import loginViewModelTest from './LoginViewModel.test';
import myViewModelTest from './MyViewModel.test';
import accountDetailViewModelTest from './AccountDetailViewModel.test';
import genshinDailyDetailViewModelTest from './GenshinDailyDetailViewModel.test';
import genshinCharDetailViewModelTest from './GenshinCharacterDetailViewModel.test';
import privacyConsentViewModelTest from './PrivacyConsentViewModel.test';
import widgetPayloadParserTest from './WidgetPayloadParser.test';
import widgetDataHelperTest from './WidgetDataHelper.test';
import widget2x2ViewModelTest from './Widget2x2ViewModel.test';
import staminaThresholdCalculatorTest from './StaminaThresholdCalculator.test';
import staminaNotificationServiceTest from './StaminaNotificationService.test';
import widgetExtraRowTypeTest from './WidgetExtraRowType.test';
import widgetExtraRowConfigTest from './WidgetExtraRowConfig.test';
import widgetDataHelperExtraRowsTest from './WidgetDataHelperExtraRows.test';

export default function testsuite() {
  localUnitTest();
  homeViewModelTest();
  charactersViewModelTest();
  loginViewModelTest();
  myViewModelTest();
  accountDetailViewModelTest();
  genshinDailyDetailViewModelTest();
  genshinCharDetailViewModelTest();
  privacyConsentViewModelTest();
  widgetPayloadParserTest();
  widgetDataHelperTest();
  widget2x2ViewModelTest();
  staminaThresholdCalculatorTest();
  staminaNotificationServiceTest();
  widgetExtraRowTypeTest();
  widgetExtraRowConfigTest();
  widgetDataHelperExtraRowsTest();
}