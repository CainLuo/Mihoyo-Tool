/**
 * CharacterMaterialSections.ets — 角色材料分组组件
 *
 * 展示单个角色的材料分组：角色突破材料、天赋材料、武器材料。
 * 每个分组使用网格形式展示材料列表。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialItemVM } from '../../models/MaterialListModels';
import { ThemeFonts } from '../../theme/ThemeFonts';
import { MaterialGridItem } from './MaterialGridItem';

@ComponentV2
export struct CharacterMaterialSections {
  @Param avatarMaterials: MaterialItemVM[] = [];
  @Param skillMaterials: MaterialItemVM[] = [];
  @Param weaponMaterials: MaterialItemVM[] = [];

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value12 }) {
      // 角色突破材料
      if (this.avatarMaterials.length > 0) {
        Column({ space: this.tm.current.value8 }) {
          Text($r('app.string.material_section_avatar'))
            .font(ThemeFonts.fontBold14)
            .fontColor(this.tm.current.colorTextPrimary)
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.avatarMaterials, (item: MaterialItemVM) => {
              MaterialGridItem({ item: item })
            }, (item: MaterialItemVM) => item.materialId)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        }
        .width(this.tm.current.full)
      }

      // 天赋材料
      if (this.skillMaterials.length > 0) {
        Column({ space: this.tm.current.value8 }) {
          Text($r('app.string.material_section_skill'))
            .font(ThemeFonts.fontBold14)
            .fontColor(this.tm.current.colorTextPrimary)
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.skillMaterials, (item: MaterialItemVM) => {
              MaterialGridItem({ item: item })
            }, (item: MaterialItemVM) => item.materialId)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        }
        .width(this.tm.current.full)
      }

      // 武器/光锥材料
      if (this.weaponMaterials.length > 0) {
        Column({ space: this.tm.current.value8 }) {
          Text($r('app.string.material_section_weapon'))
            .font(ThemeFonts.fontBold14)
            .fontColor(this.tm.current.colorTextPrimary)
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.weaponMaterials, (item: MaterialItemVM) => {
              MaterialGridItem({ item: item })
            }, (item: MaterialItemVM) => item.materialId)
          }
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        }
        .width(this.tm.current.full)
      }
    }
    .width(this.tm.current.full)
  }
}

@Preview
@ComponentV2
export struct CharacterMaterialSectionsPreview {
  @Local avatarMaterials: MaterialItemVM[] = [];
  @Local skillMaterials: MaterialItemVM[] = [];
  @Local weaponMaterials: MaterialItemVM[] = [];

  aboutToAppear(): void {
    const mat1 = new MaterialItemVM();
    mat1.materialId = '1';
    mat1.name = '哀叙冰玉';
    mat1.rarity = 5;
    mat1.have = 12;
    mat1.need = 46;

    const mat2 = new MaterialItemVM();
    mat2.materialId = '2';
    mat2.name = '极寒之核';
    mat2.rarity = 4;
    mat2.have = 8;
    mat2.need = 46;

    this.avatarMaterials = [mat1, mat2];

    const mat3 = new MaterialItemVM();
    mat3.materialId = '202';
    mat3.name = '摩拉';
    mat3.rarity = 3;
    mat3.have = 0;
    mat3.need = 2092530;

    this.skillMaterials = [mat3];
  }

  build() {
    Column() {
      CharacterMaterialSections({
        avatarMaterials: this.avatarMaterials,
        skillMaterials: this.skillMaterials,
        weaponMaterials: this.weaponMaterials
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
