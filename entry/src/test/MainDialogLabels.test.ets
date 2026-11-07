import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { getGameAccountLabel } from '../main/ets/utils/MainDialogLabels';

export default function mainDialogLabelsTest() {
  describe('MainDialogLabels', () => {

    it('roleId 为空时返回 fallback', 0, () => {
      expect(getGameAccountLabel(null, GameId.GENSHIN, '', '账号 1')).assertEqual('账号 1');
    });

    it('没有 UIContext 时只显示 UID', 0, () => {
      expect(getGameAccountLabel(null, GameId.STARRAIL, '100000001', 'fallback'))
        .assertEqual('UID 100000001');
    });

  });
}
