import staminaThresholdCalculatorTest from './StaminaThresholdCalculator.test';
import staminaNotificationServiceTest from './StaminaNotificationService.test';
import coalescingRunnerTest from './CoalescingRunner.test';
import notificationSettingsViewModelTest from './NotificationSettingsViewModel.test';
import notificationSettingsStoreTest from './NotificationSettingsStore.test';
import notificationStateStoreTest from './NotificationStateStore.test';

export default function testsuite() {
  staminaThresholdCalculatorTest();
  staminaNotificationServiceTest();
  coalescingRunnerTest();
  notificationSettingsViewModelTest();
  notificationSettingsStoreTest();
  notificationStateStoreTest();
}
