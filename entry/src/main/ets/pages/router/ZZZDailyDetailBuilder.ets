/**
 * ZZZDailyDetailBuilder — 绝区零便笺详情页路由 Builder
 */
import { ZZZDailyDetail, ZZZDailyDetailParam } from '../ZZZDailyDetail'

@Builder
export function ZZZDailyDetailBuilder(name: string, param: Object) {
  ZZZDailyDetail({ routerParam: param as ZZZDailyDetailParam })
}
