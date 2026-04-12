/**
 * StarRailCharacterDetailBuilder — 星穹铁道角色详情页路由 Builder
 */
import { StarRailCharacterDetail } from '../StarRailCharacterDetail'
import { CharDetailRouterParam } from '../../components/chardetail/CharDetailModels'

@Builder
export function StarRailCharacterDetailBuilder(name: string, param: Object) {
  StarRailCharacterDetail({ routerParam: param as CharDetailRouterParam })
}
