/**
 * CharDetailHeroPanelWide — 宽屏三栏立绘区
 *
 * 立绘铺满，左上角名字+等级+好感，左下角命座列，右下角技能列。
 * 适用于 Tablet / PC / Foldable 展开（sm/md/lg 断点）。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailConstellation, CharDetailSkill } from './CharDetailModels';
import { elementColor } from '../characters/CharacterCard';
import { GenshinElement } from '../../constants/GenshinElement';
import { CharDetailConsColumn } from './CharDetailConsColumn';
import { CharDetailSkillsColumn } from './CharDetailSkillsColumn';
import { ViewState } from '../../constants/ViewStates';

function makeMockWideVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = '神里绫华';
  vm.charLevel = 90;
  vm.charFetter = 10;
  vm.charElement = GenshinElement.CRYO;
  vm.charImageUrl = '';
  const cons: CharDetailConstellation[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailConstellation();
    c.pos = i + 1;
    c.iconUrl = '';
    c.isActived = i < 3;
    cons[cons.length] = c;
  }
  vm.constellations = cons;
  const skills: CharDetailSkill[] = [];
  const levels = [10, 10, 10];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = levels[i];
    skills[skills.length] = s;
  }
  vm.skills = skills;
  return vm;
}

// ── Preview：宽屏立绘区 ──
@Preview
@ComponentV2
export struct CharDetailHeroPanelWidePreview {
  build() {
    CharDetailHeroPanelWide({ vm: makeMockWideVM() })
      .width(themeManager.current.value400)
      .height(themeManager.current.value480)
  }
}

@ComponentV2
export struct CharDetailHeroPanelWide {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  private elementBgColors(): LinearGradient {
    const elem = this.vm.charElement;
    const t = this.tm.current;
    if (elem === GenshinElement.HYDRO) {
      return { angle: t.a135, colors: [[t.bgElementHydro1, 0], [t.bgElementHydro2, 0.4], [t.bgElementHydro3, 1.0]] };
    }
    if (elem === GenshinElement.PYRO) {
      return { angle: t.a135, colors: [[t.bgElementPyro1, 0], [t.bgElementPyro2, 0.4], [t.bgElementPyro3, 1.0]] };
    }
    if (elem === GenshinElement.ELECTRO) {
      return { angle: t.a135, colors: [[t.bgElementElectro1, 0], [t.bgElementElectro2, 0.4], [t.bgElementElectro3, 1.0]] };
    }
    if (elem === GenshinElement.ANEMO) {
      return { angle: t.a135, colors: [[t.bgElementAnemo1, 0], [t.bgElementAnemo2, 0.4], [t.bgElementAnemo3, 1.0]] };
    }
    if (elem === GenshinElement.GEO) {
      return { angle: t.a135, colors: [[t.bgElementGeo1, 0], [t.bgElementGeo2, 0.4], [t.bgElementGeo3, 1.0]] };
    }
    if (elem === GenshinElement.CRYO) {
      return { angle: t.a135, colors: [[t.bgElementCryo1, 0], [t.bgElementCryo2, 0.4], [t.bgElementCryo3, 1.0]] };
    }
    if (elem === GenshinElement.DENDRO) {
      return { angle: t.a135, colors: [[t.bgElementDendro1, 0], [t.bgElementDendro2, 0.4], [t.bgElementDendro3, 1.0]] };
    }
    return { angle: t.a135, colors: [[t.bgElementHydro1, 0], [t.bgElementHydro2, 0.4], [t.bgElementHydro3, 1.0]] };
  }

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient(this.elementBgColors())

      // 立绘
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width(this.tm.current.full)
          .height(this.tm.current.full)
          .objectFit(ImageFit.Cover)
          .objectRepeat(ImageRepeat.NoRepeat)
      }

      // 上下渐变遮罩
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a180,
          colors: [[this.tm.current.overlayShadow, 0], [this.tm.current.colorTransparent, 0.3],
            [this.tm.current.colorTransparent, 0.55], [this.tm.current.overlayScrImTop, 1.0]]
        })

      // 左上角：名字 + 等级 + 好感
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.title18Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .textShadow({ radius: this.tm.current.value8, color: this.tm.current.overlayShadow, offsetY: 2 })
        Text(`Lv.${this.vm.charLevel}`)
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.textOnDarkMedium)
        Text($r('app.string.char_detail_fetter_label'))
          .fontSize(this.tm.current.body12.size)
          .fontColor(elementColor(this.vm.charElement))
      }
      .alignItems(HorizontalAlign.Start)
      .position({ x: this.tm.current.value12, y: this.tm.current.value12 })
      .zIndex(2)

      // 左下角：命座列
      Column() {
        CharDetailConsColumn({ constellations: this.vm.constellations })
      }
      .position({ x: this.tm.current.value12, y: '100%' })
      .markAnchor({ x: 0, y: '100%' })
      .margin({ bottom: this.tm.current.value12 })
      .zIndex(2)

      // 右下角：技能列
      Column() {
        CharDetailSkillsColumn({ skills: this.vm.skills, charElement: this.vm.charElement })
      }
      .position({ x: '100%', y: '100%' })
      .markAnchor({ x: '100%', y: '100%' })
      .margin({ right: this.tm.current.value12, bottom: this.tm.current.value12 })
      .zIndex(2)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .clip(true)
  }
}
