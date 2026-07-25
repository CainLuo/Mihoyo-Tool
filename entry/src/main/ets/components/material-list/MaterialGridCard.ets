/**
 * MaterialGridCard.ets — 材料网格卡片组件（按材料视图）
 *
 * 展示单个材料的汇总信息：图标 + 数量。
 * 数量与图标左、右、下对齐。
 * 摩拉/经验书/魔矿数量格式化：< 10000 显示具体数字，>= 10000 显示"万"单位。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialSummaryVM } from '../../models/MaterialListModels';
import { ThemeFonts } from '../../theme/ThemeFonts';
import { MaterialListViewModel } from '../../viewmodel/MaterialListViewModel';

@ComponentV2
export struct MaterialGridCard {
  @Param data: MaterialSummaryVM = new MaterialSummaryVM();
  @Param isCurrency: boolean = false;
  @Param onTap: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      // 材料图标（带稀有度背景）
      Stack() {
        Column()
          .width(this.tm.current.value48)
          .height(this.tm.current.value48)
          .borderRadius(this.tm.current.radius12)
          .backgroundColor(this.rarityBackgroundColor(this.data.rarity))

        if (this.data.iconUrl.length > 0) {
          Image(this.data.iconUrl)
            .width(this.tm.current.value48)
            .height(this.tm.current.value48)
            .borderRadius(this.tm.current.radius12)
            .objectFit(ImageFit.Contain)
        }
      }
      .width(this.tm.current.value48)
      .height(this.tm.current.value48)

      // 数量显示
      if (this.data.deficit > 0) {
        // 缺少材料：显示 -数量
        Text(this.formatAmount(this.data.deficit))
          .font(ThemeFonts.fontBold13)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.value48)
          .textAlign(TextAlign.Center)
      } else {
        // 材料充足：显示 ✓
        Text('✓')
          .font(ThemeFonts.fontBold13)
          .fontColor(this.tm.current.colorSuccess)
          .width(this.tm.current.value48)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.value56)
    .padding(this.tm.current.value4)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius8)
    .onClick(() => {
      this.onTap();
    })
  }

  /**
   * 格式化数量显示。
   * 摩拉/经验书/魔矿：< 10000 显示具体数字，>= 10000 显示"万"单位。
   * 其他材料：直接显示数字。
   */
  private formatAmount(amount: number): string {
    if (this.isCurrency) {
      return '-' + MaterialListViewModel.formatCurrencyAmount(amount);
    }
    return `-${amount}`;
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
        return $r('app.color.rarity_3star_bg');
      case 2:
        return $r('app.color.rarity_2star_bg');
      default:
        return $r('app.color.rarity_1star_bg');
    }
  }
}

@Preview
@ComponentV2
export struct MaterialGridCardPreview {
  @Local data1: MaterialSummaryVM = new MaterialSummaryVM();
  @Local data2: MaterialSummaryVM = new MaterialSummaryVM();
  @Local data3: MaterialSummaryVM = new MaterialSummaryVM();
  @Local data4: MaterialSummaryVM = new MaterialSummaryVM();

  aboutToAppear(): void {
    this.data1.materialId = '1';
    this.data1.name = '哀叙冰玉';
    this.data1.rarity = 5;
    this.data1.totalHave = 12;
    this.data1.totalNeed = 46;

    this.data2.materialId = '2';
    this.data2.name = '极寒之核';
    this.data2.rarity = 4;
    this.data2.totalHave = 46;
    this.data2.totalNeed = 46;

    this.data3.materialId = '202';
    this.data3.name = '摩拉';
    this.data3.rarity = 3;
    this.data3.totalHave = 0;
    this.data3.totalNeed = 2092530;

    this.data4.materialId = '104003';
    this.data4.name = '大英雄的经验';
    this.data4.rarity = 4;
    this.data4.totalHave = 100;
    this.data4.totalNeed = 8000;
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        MaterialGridCard({ data: this.data1, onTap: () => {} })
        MaterialGridCard({ data: this.data2, onTap: () => {} })
      }

      Row({ space: 12 }) {
        MaterialGridCard({ data: this.data3, isCurrency: true, onTap: () => {} })
        MaterialGridCard({ data: this.data4, isCurrency: true, onTap: () => {} })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
