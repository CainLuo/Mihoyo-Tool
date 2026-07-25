/**
 * CharacterMaterialCardHeader.ets — 角色材料卡片头部组件
 *
 * 展示角色头像、名称、等级和展开/折叠图标。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { CharacterMaterialVM } from '../../models/MaterialListModels';

@ComponentV2
export struct CharacterMaterialCardHeader {
  @Param data: CharacterMaterialVM = new CharacterMaterialVM();

  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: 12 }) {
      // 角色头像（带稀有度背景色）
      Stack() {
        // 稀有度背景色
        Column()
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor(this.data.characterRarity >= 5
            ? $r('app.color.rarity_5star_bg')
            : $r('app.color.rarity_4star_bg'))

        // 角色头像
        if (this.data.characterIconUrl.length > 0) {
          Image(this.data.characterIconUrl)
            .width(48)
            .height(48)
            .borderRadius(24)
            .objectFit(ImageFit.Cover)
        }
      }
      .width(48)
      .height(48)

      // 角色名称和等级
      Column({ space: 4 }) {
        Text(this.data.characterName)
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.colorTextPrimary)

        Text(`Lv.${this.data.characterLevel}`)
          .fontSize(this.tm.current.font10)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 展开/折叠图标
      Text(this.data.isExpanded ? '▼' : '▶')
        .fontSize(12)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width('100%')
  }
}

@Preview
@ComponentV2
export struct CharacterMaterialCardHeaderPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      CharacterMaterialCardHeader({
        data: {
          characterId: '10000122',
          characterName: '甘雨',
          characterIconUrl: '',
          characterLevel: 90,
          characterRarity: 5,
          isExpanded: true
        } as CharacterMaterialVM
      })

      CharacterMaterialCardHeader({
        data: {
          characterId: '10000123',
          characterName: '胡桃',
          characterIconUrl: '',
          characterLevel: 80,
          characterRarity: 5,
          isExpanded: false
        } as CharacterMaterialVM
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
