import { describe, it, expect } from '@ohos/hypium';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { AppearanceSettingsParam, getThemeModeLabel, ThemeModeItem } from '../main/ets/model/AppearanceSettingsModels';

export default function appearanceSettingsModelsTest() {
  describe('AppearanceSettingsModels', () => {

    it('AppearanceSettingsParam 默认值', 0, () => {
      const param = new AppearanceSettingsParam();
      expect(param.themeMode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      param.onThemeChange(1);
      expect(true).assertTrue();
    });

    it('ThemeModeItem 默认值', 0, () => {
      const item = new ThemeModeItem();
      expect(item.mode).assertEqual(0);
      expect(item.label !== null).assertTrue();
      expect(item.desc !== null).assertTrue();
    });

    it('getThemeModeLabel 按模式返回资源', 0, () => {
      const light = getThemeModeLabel(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      const dark = getThemeModeLabel(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      const system = getThemeModeLabel(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      expect(light !== null).assertTrue();
      expect(dark !== null).assertTrue();
      expect(system !== null).assertTrue();
      expect(light.id !== dark.id).assertTrue();
      expect(system.id !== light.id).assertTrue();
    });

  });
}
