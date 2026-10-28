import widgetPayloadParserTest from './WidgetPayloadUtil.test';
import widgetDataHelperTest from './WidgetDataUtil.test';
import widgetExtraRowTypeTest from './WidgetExtraRowType.test';
import widgetExtraRowConfigTest from './WidgetExtraRowConstants.test';
import widgetDataHelperExtraRowsTest from './WidgetDataUtilExtraRows.test';

export default function testsuite() {
  widgetPayloadParserTest();
  widgetDataHelperTest();
  widgetExtraRowTypeTest();
  widgetExtraRowConfigTest();
  widgetDataHelperExtraRowsTest();
}
