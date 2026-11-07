import { describe, it, expect } from '@ohos/hypium';
import { AppearanceSettingsViewModel } from '../main/ets/viewmodel/AppearanceSettingsViewModel';
import { ConfigurationConstant } from '@kit.AbilityKit';

export default function appearanceSettingsViewModelTest() {
  describe('AppearanceSettingsViewModel', () => {

    it('初始主题为跟随系统', 0, () => {
      const vm = new AppearanceSettingsViewModel();
      expect(vm.themeMode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    });

    it('init 设置深色主题', 0, () => {
      const vm = new AppearanceSettingsViewModel();
      vm.init(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      expect(vm.themeMode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    });

    it('init 设置浅色主题', 0, () => {
      const vm = new AppearanceSettingsViewModel();
      vm.init(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      expect(vm.themeMode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    });

    it('getThemeItems 返回浅色 / 深色 / 跟随系统三项', 0, () => {
      const vm = new AppearanceSettingsViewModel();
      const items = vm.getThemeItems();
      expect(items.length).assertEqual(3);
      expect(items[0].mode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      expect(items[1].mode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      expect(items[2].mode).assertEqual(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    });

    it('getThemeItems 每项都有非空标签与描述资源', 0, () => {
      const vm = new AppearanceSettingsViewModel();
      const items = vm.getThemeItems();
      for (let i = 0; i < items.length; i++) {
        expect(items[i].label !== null && items[i].label !== undefined).assertTrue();
        expect(items[i].desc !== null && items[i].desc !== undefined).assertTrue();
      }
    });

    it('多次调用 getThemeItems 返回新数组', 0, () => {
      const vm = new AppearanceSettingsViewModel();
      const first = vm.getThemeItems();
      const second = vm.getThemeItems();
      expect(first === second).assertFalse();
      expect(first.length).assertEqual(second.length);
    });

  });
}
