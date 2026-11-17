import { describe, it, expect } from '@ohos/hypium';
import { DialogDedup } from '../main/ets/utils/DialogDedupUtil';

export default function dialogDedupUtilTest() {
  describe('DialogDedup', () => {

    it('首次占用成功，重复占用失败', 0, () => {
      const key = 'test:acquire';
      DialogDedup.release(key);
      expect(DialogDedup.tryAcquire(key)).assertTrue();
      expect(DialogDedup.tryAcquire(key)).assertFalse();
      DialogDedup.release(key);
    });

    it('释放后可以再次占用', 0, () => {
      const key = 'test:release';
      DialogDedup.release(key);
      expect(DialogDedup.tryAcquire(key)).assertTrue();
      DialogDedup.release(key);
      expect(DialogDedup.tryAcquire(key)).assertTrue();
      DialogDedup.release(key);
    });

    it('重复释放不报错', 0, () => {
      const key = 'test:double-release';
      DialogDedup.release(key);
      DialogDedup.release(key);
      expect(true).assertTrue();
    });

    it('不同 key 互不影响', 0, () => {
      const keyA = 'test:a';
      const keyB = 'test:b';
      DialogDedup.release(keyA);
      DialogDedup.release(keyB);
      expect(DialogDedup.tryAcquire(keyA)).assertTrue();
      expect(DialogDedup.tryAcquire(keyB)).assertTrue();
      DialogDedup.release(keyA);
      DialogDedup.release(keyB);
    });

    it('从 retcode 文案推导错误码 key', 0, () => {
      expect(DialogDedup.getDedupKey('retcode=-3501: 二维码已过期')).assertEqual('code:-3501');
      expect(DialogDedup.getDedupKey('请求失败 retcode = 1034')).assertEqual('code:1034');
    });

    it('普通文案按文案去重', 0, () => {
      expect(DialogDedup.getDedupKey('网络错误')).assertEqual('msg:网络错误');
    });

    it('资源引用按资源 id 去重', 0, () => {
      const resource = $r('app.string.dialog_confirm');
      expect(DialogDedup.getDedupKey(resource)).assertEqual(`res:${resource.id}`);
    });

  });
}
