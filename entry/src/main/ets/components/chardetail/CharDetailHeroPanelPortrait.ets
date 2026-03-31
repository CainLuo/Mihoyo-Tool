/**
 * CharDetailHeroPanelPortrait — Phone 竖屏立绘区
 *
 * 立绘贴右，左侧渐变遮罩，左下角名字+等级+好感+技能横行，右侧命座纵列居中。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel, CharDetailSkill, CharDetailConstellation } from '../../viewmodel/GenshinCharacterDetailViewModel';
import { elementColor } from '../characters/CharacterCard';
import { CharDetailConsColumn } from './CharDetailConsColumn';
import { GenshinElement } from '../../constants/GenshinElement';
import { ViewState } from '../../constants/ViewStates';

function makeMockPortraitVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = '胡桃';
  vm.charLevel = 90;
  vm.charMaxLevel = 90;
  vm.charFetter = 10;
  vm.charElement = GenshinElement.PYRO;
  vm.charImageUrl = '';
  const cons: CharDetailConstellation[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailConstellation();
    c.pos = i + 1;
    c.iconUrl = '';
    c.isActived = i < 1;
    cons[cons.length] = c;
  }
  vm.constellations = cons;
  const skills: CharDetailSkill[] = [];
  const levels = [10, 12, 12];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = levels[i];
    skills[skills.length] = s;
  }
  vm.skills = skills;
  return vm;
}

// ── Preview：Phone 竖屏立绘区 ──
@Preview
@ComponentV2
struct CharDetailHeroPanelPortraitPreview {
  build() {
    CharDetailHeroPanelPortrait({ vm: makeMockPortraitVM() })
      .width(themeManager.current.value360)
      .height(themeManager.current.value260)
  }
}

@ComponentV2
export struct CharDetailHeroPanelPortrait {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Stack() {
      // 背景
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a150,
          colors: [[this.tm.current.bgPortrait1, 0], [this.tm.current.bgPortrait2, 1.0]]
        })

      // 立绘贴右
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .height(this.tm.current.full)
          .objectFit(ImageFit.Cover)
          .position({ x: '100%', y: 0 })
          .markAnchor({ x: '100%', y: 0 })
      }

      // 左侧渐变遮罩
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a90,
          colors: [[this.tm.current.overlayPortraitBase, 0], [this.tm.current.overlayPortraitStrong, 0.32],
            [this.tm.current.overlayPortraitMid, 0.55], [this.tm.current.colorTransparent, 1.0]]
        })

      // 底部渐变
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a0,
          colors: [[this.tm.current.overlayPortraitBot, 0], [this.tm.current.colorTransparent, 0.45]]
        })

      // 右侧命座纵列（垂直居中）
      Column() {
        CharDetailConsColumn({ constellations: this.vm.constellations })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .padding({ right: this.tm.current.value12 })
      .zIndex(3)

      // 左下角：名字 + 等级 + 好感 + 技能横行
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.value22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .textShadow({ radius: this.tm.current.value8, color: this.tm.current.overlayShadow, offsetY: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value8 }) {
          Text(`Lv.${this.vm.charLevel}`)
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.textOnDarkMedium)
          Text($r('app.string.character_fetter_value', this.vm.charFetter))
            .fontSize(this.tm.current.body10.size)
            .fontColor(elementColor(this.vm.charElement))
            .backgroundColor(this.tm.current.surfaceFetterBg)
            .border({ width: this.tm.current.value1, color: this.tm.current.surfaceFetterBorder })
            .borderRadius(this.tm.current.value4)
            .padding({
              left: this.tm.current.value4, right: this.tm.current.value4,
              top: this.tm.current.value1, bottom: this.tm.current.value1
            })
        }
        // 技能横行
        Row({ space: this.tm.current.value10 }) {
          ForEach(this.vm.skills, (skill: CharDetailSkill) => {
            Column({ space: this.tm.current.value2 }) {
              if (skill.iconUrl !== '') {
                Image(skill.iconUrl)
                  .width(this.tm.current.value34)
                  .height(this.tm.current.value34)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(this.tm.current.value17)
                  .backgroundColor(this.tm.current.surfaceDark2xl)
                  .border({ width: this.tm.current.value1p5, color: this.tm.current.surfaceSkillBorderPhone })
              }
              Text(`${skill.level}`)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(elementColor(this.vm.charElement))
            }
            .alignItems(HorizontalAlign.Center)
          }, (_skill: CharDetailSkill, idx: number) => `pskill_${idx}`)
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.End)
      .padding({
        left: this.tm.current.value12,
        right: this.tm.current.pct40,
        bottom: this.tm.current.value24
      })
      .zIndex(2)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .clip(true)
  }
}
