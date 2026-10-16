/**
 * MaterialCharacterSelectBuilder.ets — 角色选择页 Builder
 *
 * 用于 NavPathStack 路由注册，透传参数到 MaterialCharacterSelect 组件。
 */

import { MaterialCharacterSelect } from '../pages/MaterialCharacterSelect'
import { GameId } from 'core'

/** 路由参数类型 */
interface MaterialCharacterSelectRouteParam {
  accountId: string
  roleUid: string
  gameId: GameId
}

@Builder
export function MaterialCharacterSelectBuilder(_name: string, param: Object) {
  MaterialCharacterSelect({
    param: param as MaterialCharacterSelectRouteParam
  })
}
