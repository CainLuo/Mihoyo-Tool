/**
 * StarRailDailyDetailBuilder — 星穹铁道便笺详情页路由 Builder
 */
import { StarRailDailyDetail, StarRailDailyDetailParam } from '../StarRailDailyDetail'

@Builder
export function StarRailDailyDetailBuilder(name: string, param: Object) {
  StarRailDailyDetail({ routerParam: param as StarRailDailyDetailParam })
}
