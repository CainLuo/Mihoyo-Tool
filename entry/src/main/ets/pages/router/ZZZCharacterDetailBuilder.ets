/**
 * ZZZCharacterDetailBuilder — 绝区零角色详情页路由 Builder
 */
import { ZZZCharacterDetail } from '../ZZZCharacterDetail'
import { CharDetailRouterParam } from '../../components/chardetail/CharDetailModels'

@Builder
export function ZZZCharacterDetailBuilder(name: string, param: Object) {
  ZZZCharacterDetail({ routerParam: param as CharDetailRouterParam })
}
