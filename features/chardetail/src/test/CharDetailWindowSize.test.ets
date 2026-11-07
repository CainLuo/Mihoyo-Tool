import { describe, it, expect } from '@ohos/hypium';
import { resolveCharDetailBreakpoint } from '../main/ets/utils/CharDetailWindowSize';

export default function charDetailWindowSizeTest() {
  describe('CharDetailWindowSize.resolveCharDetailBreakpoint', () => {

    it('小于 600vp 为 xs', 0, () => {
      expect(resolveCharDetailBreakpoint(0)).assertEqual('xs');
      expect(resolveCharDetailBreakpoint(599)).assertEqual('xs');
    });

    it('600 ~ 839vp 为 sm', 0, () => {
      expect(resolveCharDetailBreakpoint(600)).assertEqual('sm');
      expect(resolveCharDetailBreakpoint(839)).assertEqual('sm');
    });

    it('840 ~ 1199vp 为 md', 0, () => {
      expect(resolveCharDetailBreakpoint(840)).assertEqual('md');
      expect(resolveCharDetailBreakpoint(1199)).assertEqual('md');
    });

    it('1200vp 及以上为 lg', 0, () => {
      expect(resolveCharDetailBreakpoint(1200)).assertEqual('lg');
      expect(resolveCharDetailBreakpoint(2000)).assertEqual('lg');
    });

  });
}
