/**
 * MaterialCalcSection.ets — 材料 Section 组件
 *
 * 显示角色材料或武器材料的 Section。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialSectionVM, MaterialCalcItemVM } from '../../models/MaterialCalcModels';
import { MaterialCalcItem } from './MaterialCalcItem';

@ComponentV2
export struct MaterialCalcSection {
  @Param section: MaterialSectionVM = new MaterialSectionVM();
  @Param iconName: string = '👤';
  @Param onWeaponLevelTap: (() => void) | null = null;

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 10 }) {
      // Section 标题行
      Row({ space: 8 }) {
        // 图标
        Text(this.iconName)
          .fontSize(16)

        // 标题
        Text(this.section.title)
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.colorTextPrimary)

        // 进度
        Text(`${this.section.progressPercent}%`)
          .fontSize(this.tm.current.font12)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 武器等级按钮（仅武器 Section 显示）
      if (this.onWeaponLevelTap !== null) {
        Button() {
          Text('Lv.80→90 ▼')
            .fontSize(this.tm.current.font12)
            .fontColor(this.tm.current.colorPrimary)
        }
        .type(ButtonType.Normal)
        .backgroundColor(this.tm.current.surfaceActivePrimary)
        .borderRadius(this.tm.current.radius8)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .onClick(() => {
          if (this.onWeaponLevelTap !== null) {
            this.onWeaponLevelTap();
          }
        })
      }

      // 缺少数量提示
      if (this.section.hasData) {
        Text(this.section.deficitCount > 0
          ? `缺少 ${this.section.deficitCount} 个材料`
          : '材料已足够')
          .fontSize(this.tm.current.font12)
          .fontColor(this.section.deficitCount > 0 ? this.tm.current.colorDanger : this.tm.current.colorPrimary)
          .width('100%')
      }

      // 材料列表
      if (this.section.hasData) {
        Column({ space: 6 }) {
          ForEach(this.section.items, (item: MaterialCalcItemVM) => {
            MaterialCalcItem({ item: item })
          }, (item: MaterialCalcItemVM) => item.materialId)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
  }
}

@Preview
@ComponentV2
export struct MaterialCalcSectionPreview {
  @Local section: MaterialSectionVM = new MaterialSectionVM();

  aboutToAppear(): void {
    this.section.title = $r('app.string.material_section_avatar');
    this.section.progressPercent = 35;
    this.section.deficitCount = 82;
    this.section.hasData = true;
    this.section.items = [
      { materialId: '1', name: '哀叙冰玉', rarity: 5, have: 12, need: 46 } as MaterialCalcItemVM,
      { materialId: '2', name: '极寒之核', rarity: 4, have: 8, need: 46 } as MaterialCalcItemVM,
    ];
  }

  build() {
    Column() {
      MaterialCalcSection({
        section: this.section,
        iconName: '👤',
        onWeaponLevelTap: null
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
