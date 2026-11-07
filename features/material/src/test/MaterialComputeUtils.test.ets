import { describe, it, expect } from '@ohos/hypium';
import { MaterialComputeUtils } from '../main/ets/model/service/MaterialComputeUtils';
import { MaterialComputeResult } from '../main/ets/model/service/MaterialComputeResult';

export default function materialComputeUtilsTest() {
  describe('MaterialComputeUtils', () => {

    it('clampLevel 限制在 1 ~ max', 0, () => {
      expect(MaterialComputeUtils.clampLevel(50, 90)).assertEqual(50);
      expect(MaterialComputeUtils.clampLevel(0, 90)).assertEqual(1);
      expect(MaterialComputeUtils.clampLevel(-10, 90)).assertEqual(1);
      expect(MaterialComputeUtils.clampLevel(100, 90)).assertEqual(90);
    });

    it('有成功时返回 SUCCESS', 0, () => {
      expect(MaterialComputeUtils.toResult(1, 0, 1)).assertEqual(MaterialComputeResult.SUCCESS);
      expect(MaterialComputeUtils.toResult(2, 1, 3)).assertEqual(MaterialComputeResult.SUCCESS);
    });

    it('全部已达成目标时返回 NO_NEEDS', 0, () => {
      expect(MaterialComputeUtils.toResult(0, 2, 2)).assertEqual(MaterialComputeResult.NO_NEEDS);
      expect(MaterialComputeUtils.toResult(0, 3, 3)).assertEqual(MaterialComputeResult.NO_NEEDS);
    });

    it('没有成功且未全部达成时返回 FAILED', 0, () => {
      expect(MaterialComputeUtils.toResult(0, 1, 2)).assertEqual(MaterialComputeResult.FAILED);
      expect(MaterialComputeUtils.toResult(0, 0, 3)).assertEqual(MaterialComputeResult.FAILED);
      expect(MaterialComputeUtils.toResult(0, 0, 0)).assertEqual(MaterialComputeResult.FAILED);
    });

    it('parseObject 空串返回 null', 0, () => {
      expect(MaterialComputeUtils.parseObject('')).assertNull();
    });

    it('parseObject 合法 JSON 返回对象', 0, () => {
      const parsed = MaterialComputeUtils.parseObject('{"level":80,"name":"test"}');
      expect(parsed !== null).assertTrue();
      expect(parsed !== null ? parsed['level'] : null).assertEqual(80);
      expect(parsed !== null ? parsed['name'] : null).assertEqual('test');
    });

    it('parseObject 非法 JSON 返回 null', 0, () => {
      expect(MaterialComputeUtils.parseObject('not-json')).assertNull();
      expect(MaterialComputeUtils.parseObject('{')).assertNull();
    });

    it('getErrorMessage 提取 Error.message', 0, () => {
      expect(MaterialComputeUtils.getErrorMessage(new Error('boom'))).assertEqual('boom');
    });

    it('getErrorMessage 处理非 Error 值', 0, () => {
      expect(MaterialComputeUtils.getErrorMessage('plain')).assertEqual('plain');
      expect(MaterialComputeUtils.getErrorMessage(404)).assertEqual('404');
    });

  });
}
