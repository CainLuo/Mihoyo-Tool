/**
 * Widget4x4Header.ets — 4×4 Widget 顶部标题行
 *
 * 游戏色圆点 + 游戏名 + UID（固定高度，不参与 flex 分配）。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetColors } from 'widgetbase';

@Component
export struct Widget4x4Header {
  /** 游戏主题色（左侧圆点） */
  gameColor: ResourceColor = '';

  /** 游戏名称 */
  gameName: string = '';

  /** 角色 UID（含前缀） */
  roleIdWithPrefix: string = '';

  build() {
    Row() {
      // 游戏色圆点
      Row()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(this.gameColor)

      // 游戏名
      Text(this.gameName)
        .fontSize(14)
        .fontWeight(700)
        .fontColor(WidgetColors.WHITE)
        .opacity(0.95)
        .layoutWeight(1)
        .margin({ left: 6 })

      // UID
      Text(this.roleIdWithPrefix)
        .fontSize(10)
        .fontColor(WidgetColors.WHITE)
        .opacity(0.35)
    }
    .width('100%')
    .padding({ bottom: 8 })
  }
}

@Preview
@Component
struct Widget4x4HeaderPreview {
  build() {
    Column() {
      Widget4x4Header({
        gameColor: $r('app.color.game_color_genshin'),
        gameName: '原神',
        roleIdWithPrefix: 'UID 123456789'
      })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
