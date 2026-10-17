/**
 * MaterialSectionView.ets — 材料分组视图组件
 *
 * 展示单个材料分组：标题 + 材料网格。
 * 用于"按材料"视图。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialSummaryVM, MaterialSectionVM, MaterialSectionType } from '../../models/MaterialListModels';
import { MaterialGridCard } from './MaterialGridCard';
import { ThemeFonts } from '../../theme/ThemeFonts';

@ComponentV2
export struct MaterialSectionView {
  @Param section: MaterialSectionVM = new MaterialSectionVM();
  @Param onMaterialTap: (material: MaterialSummaryVM) => void = (_: MaterialSummaryVM) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value12 }) {
      // section 标题
      Text(this.section.title)
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)

      // 材料网格
      GridRow({
        columns: 5,
        gutter: { x: this.tm.current.value8, y: this.tm.current.value8 }
      }) {
        ForEach(this.section.materials, (mat: MaterialSummaryVM) => {
          GridCol() {
            MaterialGridCard({
              data: mat,
              isCurrency: this.section.type === MaterialSectionType.CURRENCY,
              onTap: () => {
                this.onMaterialTap(mat);
              }
            })
          }
        }, (mat: MaterialSummaryVM) => mat.materialId)
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@ComponentV2
export struct MaterialSectionViewPreview {
  @Local section: MaterialSectionVM = new MaterialSectionVM();

  aboutToAppear(): void {
    this.section.type = MaterialSectionType.CURRENCY;
    this.section.title = '经验书与摩拉';

    const mat1 = new MaterialSummaryVM();
    mat1.materialId = '202';
    mat1.name = '摩拉';
    mat1.rarity = 3;
    mat1.totalNeed = 2092530;

    const mat2 = new MaterialSummaryVM();
    mat2.materialId = '104003';
    mat2.name = '大英雄的经验';
    mat2.rarity = 4;
    mat2.totalNeed = 8000;

    this.section.materials = [mat1, mat2];
  }

  build() {
    Column() {
      MaterialSectionView({ section: this.section })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
