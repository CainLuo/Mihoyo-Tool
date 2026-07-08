/**
 * CharDetailHeroPanelPortrait — Phone 竖屏立绘区
 *
 * 立绘贴右，左侧渐变遮罩，左下角名字+等级+好感+技能横行，右侧命座纵列居中。
 */

import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSkill, CharDetailRankItem } from '../../../models/CharDetailModels';
import { elementColor, GenshinElement } from '../../../constants/GenshinElement';
import { CharDetailConsColumn } from '../common/CharDetailConsColumn';
import { CharDetailHeroInfoOverlay } from './CharDetailHeroInfoOverlay';
import { CharDetailLevelAndFetterRow } from './CharDetailLevelAndFetterRow';
import { genshinElementBgGradient } from '../../../utils/GenshinElementBgUtil';
import { HeroPanelMode } from '../../../constants/HeroPanelMode';
import { ViewState } from '../../../constants/ViewStates';
import { TransparentColorCache } from '../../../utils/ColorUtil';

function makeMockPortraitVM(): GenshinCharacterDetailViewModel {
  const vm = new GenshinCharacterDetailViewModel();
  vm.viewState = ViewState.DATA;
  vm.charName = '胡桃';
  vm.charLevel = 90;
  vm.charFetter = 10;
  vm.charElement = GenshinElement.PYRO;
  vm.charImageUrl = '';
  const cons: CharDetailRankItem[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailRankItem();
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
export struct CharDetailHeroPanelPortraitPreview {
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

  @Builder
  extraContentBuilder() {
    CharDetailLevelAndFetterRow({ vm: this.vm, mode: HeroPanelMode.PORTRAIT })
  }

  build() {
    Stack() {
      // 背景（元素力渐变）
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient(genshinElementBgGradient(this.vm.charElement, this.tm.current, this.tm.current.a150))

      // 立绘贴右
      if (this.vm.charImageUrl !== '') {
        Image(this.vm.charImageUrl)
          .width('60%')
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
          colors: [
            [this.tm.current.overlayPortraitBase, 0],
            [TransparentColorCache.blackWith60, 0.32],
            [TransparentColorCache.blackWith40, 0.55],
            [Color.Transparent, 1.0]
          ]
        })

      // 底部渐变
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a0,
          colors: [[this.tm.current.overlayPortraitBot, 0], [Color.Transparent, 0.45]]
        })

      // 左侧命座纵列（垂直居中，和星铁/绝区零保持一致）
      Column() {
        CharDetailConsColumn({ constellations: this.vm.constellations })
      }
      .height(this.tm.current.full)
      .justifyContent(FlexAlign.Center)
      .padding({ left: this.tm.current.value12 })
      .position({ x: 0, y: 0 })
      .zIndex(3)

      // 左下角：名字 + 等级 + 好感（技能移到独立 section）
      CharDetailHeroInfoOverlay({
        charName: this.vm.charName,
        charElement: this.vm.charElement,
        mode: HeroPanelMode.PORTRAIT,
        extraContent: () => { this.extraContentBuilder() }
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .clip(true)
  }
}
