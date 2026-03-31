/**
 * CharDetailConsColumn — 命座纵列组件
 *
 * 宽屏、竖屏、横屏三种布局共用。
 * 有图标时显示命座图标（未激活叠加锁图标），无图标时显示序号兜底。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { CharDetailConstellation } from '../../viewmodel/GenshinCharacterDetailViewModel';

/** 构造 mock 命座数据 */
function makeMockCons(activatedCount: number): CharDetailConstellation[] {
  const cons: CharDetailConstellation[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailConstellation();
    c.pos = i + 1;
    c.name = `命座${i + 1}`;
    c.iconUrl = '';
    c.isActived = i < activatedCount;
    cons[cons.length] = c;
  }
  return cons;
}

// ── Preview：6命全激活 ──
@Preview
@ComponentV2
struct CharDetailConsColumnPreviewFull {
  build() {
    CharDetailConsColumn({ constellations: makeMockCons(6) })
      .padding(themeManager.current.value16)
      .backgroundColor(themeManager.current.bgPageDeep)
  }
}

// ── Preview：2命（部分激活）──
@Preview
@ComponentV2
struct CharDetailConsColumnPreviewPartial {
  build() {
    CharDetailConsColumn({ constellations: makeMockCons(2) })
      .padding(themeManager.current.value16)
      .backgroundColor(themeManager.current.bgPageDeep)
  }
}

@ComponentV2
export struct CharDetailConsColumn {
  @Param constellations: CharDetailConstellation[] = [];
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      ForEach(this.constellations, (c: CharDetailConstellation) => {
        if (c.iconUrl !== '') {
          Stack() {
            Image(c.iconUrl)
              .width(this.tm.current.value28)
              .height(this.tm.current.value28)
              .objectFit(ImageFit.Contain)
              .borderRadius(this.tm.current.value28 / 2)
              .backgroundColor(c.isActived ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDark2xl)
              .border({
                width: this.tm.current.value1p5,
                color: c.isActived ? this.tm.current.surfaceActiveBorder : this.tm.current.surfaceInactiveBorder
              })
              .opacity(c.isActived ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
            if (!c.isActived) {
              SymbolGlyph($r('sys.symbol.lock'))
                .fontSize(this.tm.current.value28 * this.tm.current.charDetailLockIconRatio)
                .fontColor([this.tm.current.textLockIcon])
            }
          }
          .width(this.tm.current.value28)
          .height(this.tm.current.value28)
        } else {
          // 无图标兜底：显示序号
          Text(`${c.pos}`)
            .fontSize(this.tm.current.body13Bold.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(c.isActived ? $r('app.color.element_hydro') : this.tm.current.textInactive)
            .width(this.tm.current.value28)
            .height(this.tm.current.value28)
            .borderRadius(this.tm.current.value28 / 2)
            .backgroundColor(c.isActived ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDark2xl)
            .border({
              width: this.tm.current.value1p5,
              color: c.isActived ? this.tm.current.surfaceActiveBorder : this.tm.current.surfaceInactiveBorder
            })
            .textAlign(TextAlign.Center)
        }
      }, (c: CharDetailConstellation) => `cons_${c.pos}`)
    }
  }
}
