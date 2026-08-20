/**
 * CharacterMaterialCard.ets — 角色材料卡片组件（按角色视图）
 *
 * 展示单个角色的突破材料、天赋材料和武器材料。
 * 折叠状态：角色头像 + 名字 + 等级 + 武器 + 技能 + 展开箭头
 * 展开状态：在武器和技能下方显示材料列表
 */

import { SymbolGlyphModifier } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { CharacterMaterialVM, MaterialItemVM, WeaponMaterialVM, SkillItemVM } from '../../models/MaterialListModels';
import { ThemeFonts } from '../../theme/ThemeFonts';
import { CharacterMaterialSections } from './CharacterMaterialSections';

@ComponentV2
export struct CharacterMaterialCard {
  @Param data: CharacterMaterialVM = new CharacterMaterialVM();
  @Param onToggleExpand: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      // ─── 角色信息行（始终可见）─────────────────────────────────────────
      Column({ space: this.tm.current.value12 }) {
        // 第一行：角色信息 + 展开箭头
        Row({ space: this.tm.current.value12 }) {
          // 左侧：角色头像（带稀有度背景色）
          Stack() {
            Column()
              .width(this.tm.current.value48)
              .height(this.tm.current.value48)
              .borderRadius(this.tm.current.radius12)
              .backgroundColor(this.data.characterRarity >= 5
                ? $r('app.color.rarity_5star_bg')
                : $r('app.color.rarity_4star_bg'))

            if (this.data.characterIconUrl.length > 0) {
              Image(this.data.characterIconUrl)
                .width(this.tm.current.value48)
                .height(this.tm.current.value48)
                .borderRadius(this.tm.current.radius12)
                .objectFit(ImageFit.Cover)
            }
          }
          .width(this.tm.current.value48)
          .height(this.tm.current.value48)

          // 右侧：名字 + 等级 + 武器
          Column({ space: this.tm.current.value8 }) {
            // 第一行：角色名 + 等级
            Row({ space: this.tm.current.value8 }) {
              Text(this.data.characterName)
                .font(ThemeFonts.fontBold16)
                .fontColor(this.tm.current.colorTextPrimary)

              Text(`Lv.${this.data.characterLevel}`)
                .font(ThemeFonts.font13)
                .fontColor(this.tm.current.colorTextSecondary)
            }

            // 第二行：武器/光锥信息（图标 + 名称 + 等级）
            if (this.data.weapon !== null || this.data.lightCone !== null) {
              Row({ space: this.tm.current.value8 }) {
                Stack() {
                  Column()
                    .width(this.tm.current.value36)
                    .height(this.tm.current.value36)
                    .borderRadius(this.tm.current.radius8)
                    .backgroundColor(this.getWeaponRarity() >= 5
                      ? $r('app.color.rarity_5star_bg')
                      : $r('app.color.rarity_4star_bg'))

                  if (this.getWeaponIconUrl().length > 0) {
                    Image(this.getWeaponIconUrl())
                      .width(this.tm.current.value36)
                      .height(this.tm.current.value36)
                      .borderRadius(this.tm.current.radius8)
                      .objectFit(ImageFit.Cover)
                  }
                }
                .width(this.tm.current.value36)
                .height(this.tm.current.value36)

                Text(this.getWeaponName())
                  .font(ThemeFonts.font14)
                  .fontColor(this.tm.current.colorTextPrimary)

                Text(`Lv.${this.getWeaponLevel()}`)
                  .font(ThemeFonts.fontBold14)
                  .fontColor(this.tm.current.colorPrimary)
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 展开箭头
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(this.tm.current.font16)
            .fontColor([this.tm.current.colorTextSecondary])
            .rotate({ angle: this.data.isExpanded ? 90 : 0 })
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })
        }
        .width(this.tm.current.full)

        // 第二行：技能图标（横向排列）
        if (this.data.skills.length > 0) {
          Row({ space: this.tm.current.value8 }) {
            ForEach(this.data.skills, (skill: SkillItemVM, idx: number) => {
              Stack({ alignContent: Alignment.BottomEnd }) {
                Column()
                  .width(this.tm.current.value32)
                  .height(this.tm.current.value32)
                  .borderRadius(this.tm.current.radius8)
                  .backgroundColor($r('app.color.dark_500'))

                if (skill.iconUrl.length > 0) {
                  Image(skill.iconUrl)
                    .width(this.tm.current.value32)
                    .height(this.tm.current.value32)
                    .borderRadius(this.tm.current.radius8)
                    .objectFit(ImageFit.Cover)
                }

                Text(`${skill.level}`)
                  .font(ThemeFonts.font11)
                  .fontColor(Color.White)
                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .backgroundColor(this.tm.current.colorPrimary)
                  .borderRadius(4)
                  .margin({ right: 2, bottom: 2 })
              }
              .width(this.tm.current.value32)
              .height(this.tm.current.value32)
            }, (skill: SkillItemVM, idx: number) => `skill_${idx}`)
          }
          .width(this.tm.current.full)
        }
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value12
      })
      .onClick(() => {
        this.onToggleExpand();
      })

      // ─── 展开区域：材料列表 ─────────────────────────────────────────
      if (this.data.isExpanded) {
        Column({ space: this.tm.current.value16 }) {
          // 分隔线
          Divider()
            .color(this.tm.current.colorDivider)
            .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })

          // 材料列表
          CharacterMaterialSections({
            avatarMaterials: this.data.avatarMaterials,
            skillMaterials: this.data.skillMaterials,
            weaponMaterials: this.data.weaponMaterials,
            avatarSectionTitle: this.data.avatarSectionTitle
          })
        }
        .width(this.tm.current.full)
        .padding({ bottom: this.tm.current.value16 })
      }
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
  }

  // ─── 辅助方法 ─────────────────────────────────────────────────────

  private getWeaponName(): ResourceStr {
    if (this.data.weapon !== null) {
      return this.data.weapon.weaponName
    }
    if (this.data.lightCone !== null) {
      return this.data.lightCone.weaponName
    }
    return ''
  }

  private getWeaponLevel(): number {
    if (this.data.weapon !== null) {
      return this.data.weapon.weaponLevel
    }
    if (this.data.lightCone !== null) {
      return this.data.lightCone.weaponLevel
    }
    return 0
  }

  private getWeaponIconUrl(): string {
    if (this.data.weapon !== null) {
      return this.data.weapon.weaponIconUrl
    }
    if (this.data.lightCone !== null) {
      return this.data.lightCone.weaponIconUrl
    }
    return ''
  }

  private getWeaponRarity(): number {
    if (this.data.weapon !== null) {
      return this.data.weapon.weaponRarity
    }
    if (this.data.lightCone !== null) {
      return this.data.lightCone.weaponRarity
    }
    return 1
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct CharacterMaterialCardPreview {
  @Local data: CharacterMaterialVM = new CharacterMaterialVM();

  aboutToAppear(): void {
    this.data.characterId = '10000122';
    this.data.characterName = '甘雨';
    this.data.characterIconUrl = '';
    this.data.characterLevel = 90;
    this.data.characterRarity = 5;
    this.data.isExpanded = false;
    
    const weapon = new WeaponMaterialVM();
    weapon.weaponName = '阿莫斯之弓';
    weapon.weaponLevel = 90;
    weapon.weaponIconUrl = '';
    weapon.weaponRarity = 5;
    this.data.weapon = weapon;
    
    this.data.skills = [
      { iconUrl: '', level: 10 } as SkillItemVM,
      { iconUrl: '', level: 10 } as SkillItemVM,
      { iconUrl: '', level: 10 } as SkillItemVM,
    ];
    
    // 角色突破材料（缺口数据）
    const mat1 = new MaterialItemVM();
    mat1.materialId = '1';
    mat1.name = '哀叙冰玉';
    mat1.iconUrl = '';
    mat1.rarity = 5;
    mat1.have = 12;
    mat1.need = 46;
    
    const mat2 = new MaterialItemVM();
    mat2.materialId = '2';
    mat2.name = '极寒之核';
    mat2.iconUrl = '';
    mat2.rarity = 4;
    mat2.have = 8;
    mat2.need = 46;
    
    this.data.avatarMaterials = [mat1, mat2];
    
    // 天赋材料（充足数据）
    const mat3 = new MaterialItemVM();
    mat3.materialId = '3';
    mat3.name = '「勤劳」的教导';
    mat3.iconUrl = '';
    mat3.rarity = 2;
    mat3.have = 24;
    mat3.need = 9;
    
    const mat4 = new MaterialItemVM();
    mat4.materialId = '4';
    mat4.name = '「勤劳」的指引';
    mat4.iconUrl = '';
    mat4.rarity = 3;
    mat4.have = 63;
    mat4.need = 63;
    
    this.data.skillMaterials = [mat3, mat4];
    
    // 武器材料（充足数据）
    const mat5 = new MaterialItemVM();
    mat5.materialId = '5';
    mat5.name = '孤云寒林的神体';
    mat5.iconUrl = '';
    mat5.rarity = 5;
    mat5.have = 3;
    mat5.need = 3;
    
    this.data.weaponMaterials = [mat5];
  }

  build() {
    Column() {
      CharacterMaterialCard({
        data: this.data,
        onToggleExpand: () => {
          this.data.isExpanded = !this.data.isExpanded;
        }
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
