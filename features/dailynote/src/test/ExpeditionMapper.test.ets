import { describe, it, expect } from '@ohos/hypium';
import { toExpeditionVMs } from '../main/ets/utils/ExpeditionMapper';
import { GenshinExpeditionData, StarRailExpeditionData } from 'core';

function genshinExpedition(sideIcon: string, status: string, remainedTime: string): GenshinExpeditionData {
  const raw = new GenshinExpeditionData();
  raw.avatarSideIcon = sideIcon;
  raw.status = status;
  raw.remainedTime = remainedTime;
  return raw;
}

function starRailExpedition(sideIcon: string, status: string, remainedTime: string): StarRailExpeditionData {
  const raw = new StarRailExpeditionData();
  raw.avatarSideIcon = sideIcon;
  raw.status = status;
  raw.remainedTime = remainedTime;
  return raw;
}

export default function expeditionMapperTest() {
  describe('ExpeditionMapper', () => {

    it('空数组返回空数组', 0, () => {
      expect(toExpeditionVMs([]).length).assertEqual(0);
    });

    it('Ongoing 且剩余时间非 0 时未完成', 0, () => {
      const result = toExpeditionVMs([genshinExpedition('a.png', 'Ongoing', '3600')]);
      expect(result.length).assertEqual(1);
      expect(result[0].avatarUrl).assertEqual('a.png');
      expect(result[0].remainSeconds).assertEqual(3600);
      expect(result[0].isFinished).assertFalse();
    });

    it('status=Finished 视为已完成', 0, () => {
      const result = toExpeditionVMs([genshinExpedition('a.png', 'Finished', '3600')]);
      expect(result[0].isFinished).assertTrue();
    });

    it('remainedTime=0 视为已完成', 0, () => {
      const result = toExpeditionVMs([starRailExpedition('b.png', 'Ongoing', '0')]);
      expect(result[0].isFinished).assertTrue();
      expect(result[0].remainSeconds).assertEqual(0);
    });

    it('remainedTime 非法时按 0 秒处理', 0, () => {
      const result = toExpeditionVMs([starRailExpedition('b.png', 'Ongoing', 'unknown')]);
      expect(result[0].remainSeconds).assertEqual(0);
      expect(result[0].isFinished).assertFalse();
    });

    it('多条派遣按原顺序转换', 0, () => {
      const result = toExpeditionVMs([
        genshinExpedition('a.png', 'Ongoing', '60'),
        genshinExpedition('b.png', 'Finished', '0'),
      ]);
      expect(result.length).assertEqual(2);
      expect(result[0].avatarUrl).assertEqual('a.png');
      expect(result[1].avatarUrl).assertEqual('b.png');
    });

  });
}
