/**
 * CharacterMaterialSection.ets — 角色材料区块组件
 *
 * 展示某一类材料（突破/技能/武器）的标题和列表。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialItemVM } from '../../models/MaterialListModels';
import { CharacterMaterialItem } from './CharacterMaterialItem';

@ComponentV2
export struct CharacterMaterialSection {
  @Param title: ResourceStr = '';
  @Param materials: MaterialItemVM[] = [];

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 8 }) {
      // Section 标题
      Text(this.title)
        .fontSize(this.tm.current.font12)
        .fontColor(this.tm.current.colorTextMuted)
        .width('100%')

      // 材料列表
      ForEach(this.materials, (item: MaterialItemVM) => {
        CharacterMaterialItem({ item: item })
      }, (item: MaterialItemVM) => item.materialId)
    }
    .width('100%')
  }
}

@Preview
@ComponentV2
export struct CharacterMaterialSectionPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: 16 }) {
      CharacterMaterialSection({
        title: $r('app.string.material_section_avatar'),
        materials: [
          { materialId: '1', name: '哀叙冰玉', iconUrl: '', rarity: 5, have: 12, need: 46, deficit: 34, isEnough: false } as MaterialItemVM,
          { materialId: '2', name: '极寒之核', iconUrl: '', rarity: 4, have: 8, need: 46, deficit: 38, isEnough: false } as MaterialItemVM
        ]
      })

      CharacterMaterialSection({
        title: $r('app.string.material_section_skill'),
        materials: [
          { materialId: '3', name: '「勤劳」的教导', iconUrl: '', rarity: 2, have: 24, need: 9, deficit: 0, isEnough: true } as MaterialItemVM
        ]
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
