import { describe, it, expect } from '@ohos/hypium';
import { applyAlpha, TransparentColorCache } from '../main/ets/utils/ColorUtil';

export default function colorUtilTest() {
  describe('ColorUtil', () => {

    it('applyAlpha 带 # 前缀', 0, () => {
      expect(applyAlpha('#000000', 0.5)).assertEqual('#80000000');
      expect(applyAlpha('#FFFFFF', 0.2)).assertEqual('#33FFFFFF');
    });

    it('applyAlpha 不带 # 前缀', 0, () => {
      expect(applyAlpha('3A6FD8', 0.15)).assertEqual('#263A6FD8');
    });

    it('applyAlpha 边界透明度', 0, () => {
      expect(applyAlpha('#000000', 0)).assertEqual('#00000000');
      expect(applyAlpha('#000000', 1)).assertEqual('#FF000000');
    });

    it('TransparentColorCache 默认值', 0, () => {
      expect(TransparentColorCache.blackWith80).assertEqual('#CC000000');
      expect(TransparentColorCache.blackWith60).assertEqual('#99000000');
      expect(TransparentColorCache.whiteWith10).assertEqual('#1AFFFFFF');
      expect(TransparentColorCache.whiteWith60).assertEqual('#99FFFFFF');
      expect(TransparentColorCache.blue500With15).assertEqual('#263A6FD8');
    });

  });
}
