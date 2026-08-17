/**
 * MaterialGridItem.ets — 单个材料网格项组件
 *
 * 展示单个材料：图标 + 缺口数量。
 * 货币材料（摩拉/经验书/魔矿）使用单位换算（万/亿）。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialItemVM } from '../../models/MaterialListModels';
import { ThemeFonts } from '../../theme/ThemeFonts';

/**
 * 货币材料 ID 列表
 * - 原神：摩拉(202)、大英雄的经验(104003)、精锻用魔矿(104013)
 * - 绝区零：丁尼(10)
 * - 星铁：信用点(2)
 */
const CURRENCY_MATERIAL_IDS: Set<string> = new Set<string>([
  '202', '104003', '104013',  // 原神
  '10',                        // 绝区零：丁尼
  '2',                         // 星铁：信用点
]);

@ComponentV2
export struct MaterialGridItem {
  @Param item: MaterialItemVM = new MaterialItemVM();

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      // 材料图标（带稀有度背景）
      Stack() {
        Column()
          .width(this.tm.current.value48)
          .height(this.tm.current.value48)
          .borderRadius(this.tm.current.radius12)
          .backgroundColor(this.getMaterialRarityBg(this.item.rarity))

        if (this.item.iconUrl.length > 0) {
          Image(this.item.iconUrl)
            .width(this.tm.current.value48)
            .height(this.tm.current.value48)
            .borderRadius(this.tm.current.radius12)
            .objectFit(ImageFit.Cover)
        }
      }
      .width(this.tm.current.value48)
      .height(this.tm.current.value48)

      // 缺少数量
      if (this.item.deficit > 0) {
        Text(this.formatDeficit(this.item))
          .font(ThemeFonts.fontBold13)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.value48)
          .textAlign(TextAlign.Center)
      } else {
        Text('✓')
          .font(ThemeFonts.fontBold13)
          .fontColor(this.tm.current.colorSuccess)
          .width(this.tm.current.value48)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.value56)
    .padding(this.tm.current.value4)
    .margin({ right: this.tm.current.value4, bottom: this.tm.current.value4 })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius8)
  }

  /**
   * 格式化缺口数量显示。
   * 货币材料（摩拉/经验书/魔矿）：使用单位换算（万/亿）
   * 其他材料：直接显示数字
   */
  private formatDeficit(item: MaterialItemVM): string {
    const isCurrency = CURRENCY_MATERIAL_IDS.has(item.materialId);
    if (isCurrency) {
      return '-' + this.formatCurrencyAmount(item.deficit);
    }
    return `-${item.deficit}`;
  }

  /**
   * 格式化摩拉/经验书/魔矿的数量显示。
   * 单位转换规则：
   * - < 1万：显示具体数字（如 5000）
   * - >= 1万 且 < 1亿：显示"万"单位，< 10万保留一位小数，>= 10万显示整数
   * - >= 1亿：显示"亿"单位，保留一位小数
   */
  private formatCurrencyAmount(amount: number): string {
    if (amount < 10000) {
      // < 1万：显示具体数字
      return `${amount}`;
    }
    
    const YI = 100000000; // 1亿
    const WAN = 10000;    // 1万
    
    if (amount >= YI) {
      // >= 1亿：显示 X.X亿
      const yiValue = amount / YI;
      const formatted = yiValue.toFixed(1);
      if (formatted.endsWith('.0')) {
        return formatted.substring(0, formatted.length - 2) + '亿';
      }
      return formatted + '亿';
    }
    
    // >= 1万 且 < 1亿：显示万单位
    const wanValue = amount / WAN;
    
    if (wanValue < 10) {
      // < 10万：保留一位小数（如 1.5万）
      const formatted = wanValue.toFixed(1);
      if (formatted.endsWith('.0')) {
        return formatted.substring(0, formatted.length - 2) + '万';
      }
      return formatted + '万';
    }
    
    // >= 10万：显示整数万（如 15万、5932万）
    return Math.floor(wanValue) + '万';
  }

  /**
   * 根据稀有度获取背景色
   */
  private getMaterialRarityBg(rarity: number): ResourceColor {
    if (rarity >= 5) {
      return $r('app.color.rarity_5star_bg');
    }
    if (rarity >= 4) {
      return $r('app.color.rarity_4star_bg');
    }
    if (rarity >= 3) {
      return $r('app.color.rarity_3star_bg');
    }
    if (rarity >= 2) {
      return $r('app.color.rarity_2star_bg');
    }
    return $r('app.color.rarity_1star_bg');
  }
}

@Preview
@ComponentV2
export struct MaterialGridItemPreview {
  @Local item1: MaterialItemVM = new MaterialItemVM();
  @Local item2: MaterialItemVM = new MaterialItemVM();

  aboutToAppear(): void {
    this.item1.materialId = '1';
    this.item1.name = '哀叙冰玉';
    this.item1.rarity = 5;
    this.item1.have = 12;
    this.item1.need = 46;

    this.item2.materialId = '202';
    this.item2.name = '摩拉';
    this.item2.rarity = 3;
    this.item2.have = 0;
    this.item2.need = 2092530;
  }

  build() {
    Column({ space: 16 }) {
      MaterialGridItem({ item: this.item1 })
      MaterialGridItem({ item: this.item2 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
