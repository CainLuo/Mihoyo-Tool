/**
 * CharDetailHeroPanelLandscape — Phone 横屏立绘区
 *
 * 立绘铺满，底部渐变遮罩，左下角名字+等级+好感+技能横行，右侧命座纵列居中。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSkill, CharDetailRankItem } from './CharDetailModels';
import { elementColor } from '../characters/CharacterCard';
import { CharDetailConsColumn } from './CharDetailConsColumn';
import { GenshinElement } from '../../constants/GenshinElement';
import { ViewState } from '../../constants/ViewStates';

function makeMockLandscapeVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = '雷电将军';
  vm.charLevel = 90;
  vm.charFetter = 10;
  vm.charElement = GenshinElement.ELECTRO;
  vm.charImageUrl = '';
  const cons: CharDetailRankItem[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailRankItem();
    c.pos = i + 1;
    c.iconUrl = '';
    c.isActived = i < 6;
    cons[cons.length] = c;
  }
  vm.constellations = cons;
  const skills: CharDetailSkill[] = [];
  const levels = [10, 10, 13];
  for (let i = 0; i < 3; i++) {
    const s = new CharDetailSkill();
    s.iconUrl = '';
    s.level = levels[i];
    skills[skills.length] = s;
  }
  vm.skills = skills;
  return vm;
}

// ── Preview：Phone 横屏立绘区 ──
@Preview
@ComponentV2
export struct CharDetailHeroPanelLandscapePreview {
  build() {
    CharDetailHeroPanelLandscape({ vm: makeMockLandscapeVM() })
      .width(themeManager.current.value200)
      .height(themeManager.current.value360)
  }
}

@ComponentV2
export struct CharDetailHeroPanelLandscape {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  private elementBgColors(): LinearGradient {
    const elem = this.vm.charElement;
    const t = this.tm.current;
    if (elem === GenshinElement.HYDRO) {
      return { angle: t.a150, colors: [[t.bgElementHydro1, 0], [t.bgElementHydro2, 0.5], [t.bgElementHydro3, 1.0]] };
    }
    if (elem === GenshinElement.PYRO) {
      return { angle: t.a150, colors: [[t.bgElementPyro1, 0], [t.bgElementPyro2, 0.5], [t.bgElementPyro3, 1.0]] };
    }
    if (elem === GenshinElement.ELECTRO) {
      return { angle: t.a150, colors: [[t.bgElementElectro1, 0], [t.bgElementElectro2, 0.5], [t.bgElementElectro3, 1.0]] };
    }
    if (elem === GenshinElement.ANEMO) {
      return { angle: t.a150, colors: [[t.bgElementAnemo1, 0], [t.bgElementAnemo2, 0.5], [t.bgElementAnemo3, 1.0]] };
    }
    if (elem === GenshinElement.GEO) {
      return { angle: t.a150, colors: [[t.bgElementGeo1, 0], [t.bgElementGeo2, 0.5], [t.bgElementGeo3, 1.0]] };
    }
    if (elem === GenshinElement.CRYO) {
      return { angle: t.a150, colors: [[t.bgElementCryo1, 0], [t.bgElementCryo2, 0.5], [t.bgElementCryo3, 1.0]] };
    }
    if (elem === GenshinElement.DENDRO) {
      return { angle: t.a150, colors: [[t.bgElementDendro1, 0], [t.bgElementDendro2, 0.5], [t.bgElementDendro3, 1.0]] };
    }
    return { angle: t.a150, colors: [[t.bgPortrait1, 0], [t.bgPortrait2, 1.0]] };
  }

  build() {
    Stack() {
      // 背景（元素力渐变）
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient(this.elementBgColors())

      // 立绘铺满
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width(this.tm.current.full)
          .height(this.tm.current.full)
          .objectFit(ImageFit.Cover)
          .objectRepeat(ImageRepeat.NoRepeat)
      }

      // 底部渐变遮罩
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a0,
          colors: [[this.tm.current.overlayLandOpaque, 0], [this.tm.current.overlayLandStrong, 0.4],
            [this.tm.current.overlayLandFade, 0.65], [this.tm.current.colorTransparent, 1.0]]
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
          .fontSize(this.tm.current.value15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .textShadow({ radius: this.tm.current.value8, color: this.tm.current.overlayShadow, offsetY: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value4 }) {
          Text(`Lv.${this.vm.charLevel}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor(this.tm.current.textOnDarkMedium)
          Text($r('app.string.char_detail_fetter_label'))
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
        Row({ space: this.tm.current.value8 }) {
          ForEach(this.vm.skills, (skill: CharDetailSkill) => {
            Column({ space: this.tm.current.value2 }) {
              if (skill.iconUrl !== '') {
                Image(skill.iconUrl)
                  .width(this.tm.current.value34)
                  .height(this.tm.current.value34)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(this.tm.current.value17)
                  .backgroundColor(this.tm.current.surfaceDarkLg)
                  .border({ width: this.tm.current.value1p5, color: this.tm.current.surfaceSkillBorderPhone })
              }
              Text(`${skill.level}`)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(elementColor(this.vm.charElement))
            }
            .alignItems(HorizontalAlign.Center)
          }, (_skill: CharDetailSkill, idx: number) => `lskill_${idx}`)
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.End)
      .padding({
        left: this.tm.current.value10,
        right: this.tm.current.pct35,
        bottom: this.tm.current.value16
      })
      .zIndex(2)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .clip(true)
  }
}
