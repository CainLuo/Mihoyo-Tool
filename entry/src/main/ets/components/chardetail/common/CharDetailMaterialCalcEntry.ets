/**
 * CharDetailMaterialCalcEntry — 材料计算入口卡片
 *
 * 在角色详情页底部显示，点击跳转到材料计算页。
 */

import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GameId } from 'core';

@ComponentV2
export struct CharDetailMaterialCalcEntry {
  @Param gameId: GameId = GameId.GENSHIN;
  @Param onTap: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      Row() {
        // 图标
        Text('📊')
          .fontSize(this.tm.current.font20)
        
        // 标题和描述
        Column() {
          Text($r('app.string.char_detail_material_calc_title'))
            .fontSize(this.tm.current.font14)
            .fontColor(this.tm.current.colorTextPrimary)
            .fontWeight(FontWeight.Bold)
          
          Text($r('app.string.char_detail_material_calc_desc'))
            .fontSize(this.tm.current.font12)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ top: this.tm.current.value2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: this.tm.current.value12 })
        
        // 箭头
        Text('›')
          .fontSize(this.tm.current.font18)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value16)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .onClick(() => {
      this.onTap();
    })
  }
}

@Preview
@ComponentV2
export struct CharDetailMaterialCalcEntryPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      CharDetailMaterialCalcEntry({ 
        gameId: GameId.GENSHIN,
        onTap: () => {}
      })
    }
    .padding(this.tm.current.value16)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
