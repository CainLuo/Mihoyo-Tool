import { describe, it, expect } from '@ohos/hypium';
import { display } from '@kit.ArkUI';
import { isLandscapeOrientation, resolveNavigationMode } from '../main/ets/utils/MainNavigationMode';

export default function mainNavigationModeTest() {
  describe('MainNavigationMode', () => {

    it('横屏与反向横屏判定为横屏', 0, () => {
      expect(isLandscapeOrientation(display.Orientation.LANDSCAPE)).assertTrue();
      expect(isLandscapeOrientation(display.Orientation.LANDSCAPE_INVERTED)).assertTrue();
    });

    it('竖屏与反向竖屏判定为非横屏', 0, () => {
      expect(isLandscapeOrientation(display.Orientation.PORTRAIT)).assertFalse();
      expect(isLandscapeOrientation(display.Orientation.PORTRAIT_INVERTED)).assertFalse();
    });

    it('横屏非分屏使用分栏', 0, () => {
      expect(resolveNavigationMode(true, 400, 1)).assertEqual(NavigationMode.Split);
    });

    it('横屏分屏使用堆叠', 0, () => {
      expect(resolveNavigationMode(true, 900, 4)).assertEqual(NavigationMode.Stack);
    });

    it('竖屏窄窗口使用堆叠', 0, () => {
      expect(resolveNavigationMode(false, 400, 1)).assertEqual(NavigationMode.Stack);
      expect(resolveNavigationMode(false, 519, undefined)).assertEqual(NavigationMode.Stack);
    });

    it('竖屏宽窗口使用分栏', 0, () => {
      expect(resolveNavigationMode(false, 520, 1)).assertEqual(NavigationMode.Split);
      expect(resolveNavigationMode(false, 800, undefined)).assertEqual(NavigationMode.Split);
    });

  });
}
