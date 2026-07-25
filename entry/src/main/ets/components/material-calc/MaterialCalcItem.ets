/**
 * MaterialCalcItem.ets — 材料列表项组件
 *
 * 显示单个材料的信息：图标、名称、进度条、数量。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialCalcItemVM } from '../../models/MaterialCalcModels';

@ComponentV2
export struct MaterialCalcItem {
  @Param item: MaterialCalcItemVM = new MaterialCalcItemVM();

  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: 10 }) {
      // 材料图标
      Row() {
        if (this.item.iconUrl.length > 0) {
          Image(this.item.iconUrl)
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        } else {
          Text('📦')
            .fontSize(18)
        }
      }
      .width(36)
      .height(36)
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.rarityBackgroundColor(this.item.rarity))
      .justifyContent(FlexAlign.Center)

      // 名称和进度条
      Column({ space: 4 }) {
        // 材料名称
        Text(this.item.name)
          .fontSize(this.tm.current.font14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 进度条
        Row() {
          Row()
            .width(`${this.item.progress}%`)
            .height('100%')
            .backgroundColor(this.item.isEnough ? this.tm.current.colorPrimary : this.tm.current.colorPrimary)
            .borderRadius(2)
        }
        .width(80)
        .height(3)
        .backgroundColor(this.tm.current.colorDivider)
        .borderRadius(2)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 数量
      Column({ space: 1 }) {
        Text(`${this.item.have}/${this.item.need}`)
          .fontSize(this.tm.current.font14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.item.isEnough ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)

        if (this.item.isEnough) {
          Text('✓')
            .fontSize(this.tm.current.font10)
            .fontColor(this.tm.current.colorPrimary)
        } else {
          Text(`-${this.item.deficit}`)
            .fontSize(this.tm.current.font10)
            .fontColor(this.tm.current.colorDanger)
        }
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 12, right: 12 })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
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
export struct MaterialCalcItemPreview {
  @Local items: MaterialCalcItemVM[] = [];

  aboutToAppear(): void {
    this.items = [
      { materialId: '1', name: '哀叙冰玉', rarity: 5, have: 12, need: 46 } as MaterialCalcItemVM,
      { materialId: '2', name: '极寒之核', rarity: 4, have: 46, need: 46 } as MaterialCalcItemVM,
      { materialId: '3', name: '清心', rarity: 3, have: 68, need: 168 } as MaterialCalcItemVM,
    ];
  }

  build() {
    Column({ space: 6 }) {
      ForEach(this.items, (item: MaterialCalcItemVM) => {
        MaterialCalcItem({ item: item })
      }, (item: MaterialCalcItemVM) => item.materialId)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
