import widgetConfigModelsTest from './WidgetConfigModels.test';
import widgetDataStoreModelsTest from './WidgetDataStoreModels.test';
import widgetPayloadBuilderTest from './WidgetPayloadBuilder.test';
import widgetSettingsViewModelTest from './WidgetSettingsViewModel.test';
import widgetSettingsSizeConfigTest from './WidgetSettingsSizeConfig.test';
import widgetPreviewUtilTest from './WidgetPreviewUtil.test';
import widgetGameSnapshotModelTest from './WidgetGameSnapshotModel.test';
import widgetPreviewModelsTest from './WidgetPreviewModels.test';
import widgetMockPayloadTest from './WidgetMockPayload.test';
import widgetSettingsModelsTest from './WidgetSettingsModels.test';
import widgetUpdateNotifierTest from './WidgetUpdateNotifier.test';
import widgetConfigStoreTest from './WidgetConfigStore.test';
import widgetFormIdStoreTest from './WidgetFormIdStore.test';

export default function testsuite() {
  widgetConfigModelsTest();
  widgetDataStoreModelsTest();
  widgetPayloadBuilderTest();
  widgetSettingsViewModelTest();
  widgetSettingsSizeConfigTest();
  widgetPreviewUtilTest();
  widgetGameSnapshotModelTest();
  widgetPreviewModelsTest();
  widgetMockPayloadTest();
  widgetSettingsModelsTest();
  widgetUpdateNotifierTest();
  widgetConfigStoreTest();
  widgetFormIdStoreTest();
}
