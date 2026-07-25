/**
 * CharacterMaterialItem.ets — 单个材料项组件
 *
 * 展示材料图标、名称、拥有/需求数量和缺少数量。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialItemVM } from '../../models/MaterialListModels';

@ComponentV2
export struct CharacterMaterialItem {
  @Param item: MaterialItemVM = new MaterialItemVM();

  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: 8 }) {
      // 材料图标
      Row() {
        if (this.item.iconUrl.length > 0) {
          Image(this.item.iconUrl)
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        } else {
          Text('📦')
            .fontSize(16)
        }
      }
      .width(32)
      .height(32)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.rarityBackgroundColor(this.item.rarity))
      .justifyContent(FlexAlign.Center)

      // 材料名称
      Text(this.item.name)
        .fontSize(this.tm.current.font14)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)

      // 数量
      Text(`${this.item.have}/${this.item.need}`)
        .fontSize(this.tm.current.font14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.item.isEnough ? this.tm.current.colorSuccess : this.tm.current.colorTextPrimary)

      // 缺少数量
      if (!this.item.isEnough) {
        Text(`-${this.item.deficit}`)
          .fontSize(this.tm.current.font10)
          .fontColor(this.tm.current.colorDanger)
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  /**
   * 根据稀有度获取背景色
   */
  private rarityBackgroundColor(rarity: number): ResourceColor {
    switch (rarity) {
      case 5:
        return $r('app.color.rarity_5star_bg');
      case 4:
        return $r('app.color.rarity_4star_bg');
      case 3:
        return $r('app.color.blue_300');
      case 2:
        return $r('app.color.green');
      default:
        return this.tm.current.colorDivider;
    }
  }
}

@Preview
@ComponentV2
export struct CharacterMaterialItemPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: 8 }) {
      CharacterMaterialItem({
        item: {
          materialId: '1',
          name: '哀叙冰玉',
          iconUrl: '',
          rarity: 5,
          have: 12,
          need: 46,
          deficit: 34,
          isEnough: false
        } as MaterialItemVM
      })

      CharacterMaterialItem({
        item: {
          materialId: '2',
          name: '极寒之核',
          iconUrl: '',
          rarity: 4,
          have: 46,
          need: 46,
          deficit: 0,
          isEnough: true
        } as MaterialItemVM
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
