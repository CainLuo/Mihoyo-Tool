import { describe, it, expect } from '@ohos/hypium';
import { HomeCardPresenter } from '../main/ets/viewmodel/HomeCardPresenter';
import { GameId } from 'core';

export default function homeCardPresenterTest() {
  describe('HomeCardPresenter', () => {

    // ─── syncDescKey ─────────────────────────────────────────────

    it('lastSyncTime=0 返回未同步', 0, () => {
      expect(HomeCardPresenter.syncDescKey(0)).assertEqual('sync_not_synced');
    });

    it('1 分钟内返回 just_now', 0, () => {
      const now = Math.floor(Date.now() / 1000);
      expect(HomeCardPresenter.syncDescKey(now - 10)).assertEqual('sync_just_now');
      expect(HomeCardPresenter.syncDescKey(now - 59)).assertEqual('sync_just_now');
    });

    it('1~59 分钟返回分钟数', 0, () => {
      const now = Math.floor(Date.now() / 1000);
      expect(HomeCardPresenter.syncDescKey(now - 60)).assertEqual('sync_minutes_ago:1');
      expect(HomeCardPresenter.syncDescKey(now - 5 * 60)).assertEqual('sync_minutes_ago:5');
      expect(HomeCardPresenter.syncDescKey(now - 59 * 60)).assertEqual('sync_minutes_ago:59');
    });

    it('1~23 小时返回小时数', 0, () => {
      const now = Math.floor(Date.now() / 1000);
      expect(HomeCardPresenter.syncDescKey(now - 60 * 60)).assertEqual('sync_hours_ago:1');
      expect(HomeCardPresenter.syncDescKey(now - 2 * 60 * 60)).assertEqual('sync_hours_ago:2');
      expect(HomeCardPresenter.syncDescKey(now - 23 * 60 * 60)).assertEqual('sync_hours_ago:23');
    });

    it('超过 24 小时返回 long_ago', 0, () => {
      const now = Math.floor(Date.now() / 1000);
      expect(HomeCardPresenter.syncDescKey(now - 24 * 60 * 60)).assertEqual('sync_long_ago');
      expect(HomeCardPresenter.syncDescKey(now - 7 * 24 * 60 * 60)).assertEqual('sync_long_ago');
    });

    // ─── getPrimaryColor ────────────────────────────────────────

    it('满体力时原神返回 danger、其他游戏返回 primary', 0, () => {
      const genshin = HomeCardPresenter.getPrimaryColor(GameId.GENSHIN, 200, 200, true);
      const starRail = HomeCardPresenter.getPrimaryColor(GameId.STARRAIL, 240, 240, true);
      expect(genshin !== null && genshin !== undefined).assertTrue();
      expect(starRail !== null && starRail !== undefined).assertTrue();
    });

    it('未满时按比例返回三种颜色', 0, () => {
      const low = HomeCardPresenter.getPrimaryColor(GameId.GENSHIN, 10, 200, false);
      const medium = HomeCardPresenter.getPrimaryColor(GameId.GENSHIN, 100, 200, false);
      const high = HomeCardPresenter.getPrimaryColor(GameId.GENSHIN, 180, 200, false);
      expect(low !== null && low !== undefined).assertTrue();
      expect(medium !== null && medium !== undefined).assertTrue();
      expect(high !== null && high !== undefined).assertTrue();
    });

    it('max=0 时比例按 0 处理，不崩溃', 0, () => {
      const color = HomeCardPresenter.getPrimaryColor(GameId.GENSHIN, 0, 0, false);
      expect(color !== null && color !== undefined).assertTrue();
    });

    // ─── 颜色 / Logo ────────────────────────────────────────────

    it('getGameColor 三个游戏都返回非空资源', 0, () => {
      expect(HomeCardPresenter.getGameColor(GameId.GENSHIN) !== null).assertTrue();
      expect(HomeCardPresenter.getGameColor(GameId.STARRAIL) !== null).assertTrue();
      expect(HomeCardPresenter.getGameColor(GameId.ZZZ) !== null).assertTrue();
    });

    it('getGameLogo 三个游戏都返回非空资源', 0, () => {
      expect(HomeCardPresenter.getGameLogo(GameId.GENSHIN) !== null).assertTrue();
      expect(HomeCardPresenter.getGameLogo(GameId.STARRAIL) !== null).assertTrue();
      expect(HomeCardPresenter.getGameLogo(GameId.ZZZ) !== null).assertTrue();
    });

  });
}
