import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { AppRoutes } from 'basic';
import { getMaterialListRoute, getMaterialTargetConfigRoute } from '../main/ets/utils/MaterialRouteUtil';

export default function materialRouteUtilTest() {
  describe('MaterialRouteUtil', () => {

    it('原神汇总页路由', 0, () => {
      expect(getMaterialListRoute(GameId.GENSHIN)).assertEqual(AppRoutes.GENSHIN_MATERIAL_LIST);
    });

    it('星铁汇总页路由', 0, () => {
      expect(getMaterialListRoute(GameId.STARRAIL)).assertEqual(AppRoutes.STARRAIL_MATERIAL_LIST);
    });

    it('绝区零汇总页路由', 0, () => {
      expect(getMaterialListRoute(GameId.ZZZ)).assertEqual(AppRoutes.ZZZ_MATERIAL_LIST);
    });

    it('未知游戏回落原神汇总页路由', 0, () => {
      expect(getMaterialListRoute(GameId.HONKAI3)).assertEqual(AppRoutes.GENSHIN_MATERIAL_LIST);
    });

    it('三个游戏的目标配置页路由', 0, () => {
      expect(getMaterialTargetConfigRoute(GameId.GENSHIN)).assertEqual(AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG);
      expect(getMaterialTargetConfigRoute(GameId.STARRAIL)).assertEqual(AppRoutes.STARRAIL_MATERIAL_TARGET_CONFIG);
      expect(getMaterialTargetConfigRoute(GameId.ZZZ)).assertEqual(AppRoutes.ZZZ_MATERIAL_TARGET_CONFIG);
    });

    it('未知游戏回落原神目标配置页路由', 0, () => {
      expect(getMaterialTargetConfigRoute(GameId.HONKAI3)).assertEqual(AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG);
    });

  });
}
