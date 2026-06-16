/**
 * CharDetailHeroPanelWide — 宽屏三栏立绘区
 *
 * 立绘铺满，左上角名字+等级+好感，左下角命座列，右下角技能列。
 * 适用于 Tablet / PC / Foldable 展开（sm/md/lg 断点）。
 */

import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailRankItem, CharDetailSkill } from '../../../models/CharDetailModels';
import { elementColor, GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailConsColumn } from '../common/CharDetailConsColumn';
import { CharDetailSkillsColumn } from './CharDetailSkillsColumn';
import { genshinElementBgGradient } from '../../../utils/GenshinElementBgUtil';
import { ViewState } from '../../../constants/ViewStates';

function makeMockWideVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = '神里绫华';
  vm.charLevel = 90;
  vm.charFetter = 10;
  vm.charElement = GenshinElement.CRYO;
  vm.charImageUrl = '';
  const cons: CharDetailRankItem[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailRankItem();
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

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient(genshinElementBgGradient(this.vm.charElement, this.tm.current, this.tm.current.a135))

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
          colors: [
            ['#80000000', 0],
            [Color.Transparent, 0.3],
            [Color.Transparent, 0.55],
            ['#80000000', 1.0]
          ]
        })

      // 左上角：名字 + 等级 + 好感
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.fontBold18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .textShadow({ radius: this.tm.current.value8, color: '#80000000', offsetY: 2 })
        Text(`Lv.${this.vm.charLevel}`)
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.textOnDarkMedium)
        Text($r('app.string.char_detail_fetter_label'))
          .fontSize(this.tm.current.font13)
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
