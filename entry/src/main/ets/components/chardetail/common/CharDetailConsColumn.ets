/**
 * CharDetailConsColumn — 命座/星魂/影画纵列组件（三个游戏通用）
 *
 * 有图标时：激活显示图标，未激活显示置灰图标 + 锁
 * 无图标时：激活显示序号，未激活显示锁（绝区零影画无图标 URL）
 */

import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailRankItem } from '../../../models/CharDetailModels';

/** 构造 mock 命座数据 */
function makeMockCons(activatedCount: number): CharDetailRankItem[] {
  const cons: CharDetailRankItem[] = [];
  for (let i = 0; i < 6; i++) {
    const c = new CharDetailRankItem();
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
export struct CharDetailConsColumnPreviewFull {
  build() {
    CharDetailConsColumn({ constellations: makeMockCons(6) })
      .padding(themeManager.current.value16)
      .backgroundColor(themeManager.current.bgPageDeep)
  }
}

// ── Preview：2命（部分激活）──
@Preview
@ComponentV2
export struct CharDetailConsColumnPreviewPartial {
  build() {
    CharDetailConsColumn({ constellations: makeMockCons(2) })
      .padding(themeManager.current.value16)
      .backgroundColor(themeManager.current.bgPageDeep)
  }
}

@ComponentV2
export struct CharDetailConsColumn {
  @Param constellations: CharDetailRankItem[] = [];
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      ForEach(this.constellations, (c: CharDetailRankItem) => {
        if (c.iconUrl !== '') {
          Stack() {
            Image(c.iconUrl)
              .width(this.tm.current.value28)
              .height(this.tm.current.value28)
              .objectFit(ImageFit.Contain)
              .opacity(c.isActived ? 1.0 : this.tm.current.opacity03)
            if (!c.isActived) {
              SymbolGlyph($r('sys.symbol.lock'))
                .fontSize(this.tm.current.value28 * this.tm.current.opacity06)
                .fontColor(['#59FFFFFF'])
            }
          }
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(c.isActived ? '#263A6FD8' : '#99000000')
          .border({
            width: this.tm.current.value1,
            color: c.isActived ? '#993A6FD8' : '#1AFFFFFF'
          })
        } else {
          // 无图标兜底：激活时显示序号，未激活时显示锁图标
          Stack() {
            Text(c.isActived ? `${c.pos}` : '')
              .fontSize(this.tm.current.fontBold14)
              .fontWeight(FontWeight.Bold)
              .fontColor(c.isActived ? this.tm.current.accentRefine : this.tm.current.textInactive)
              .textAlign(TextAlign.Center)
            if (!c.isActived) {
              SymbolGlyph($r('sys.symbol.lock'))
                .fontSize(this.tm.current.value28 * this.tm.current.opacity06)
                .fontColor(['#59FFFFFF'])
            }
          }
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(c.isActived ? '#263A6FD8' : '#99000000')
          .border({
            width: this.tm.current.value1p5,
            color: c.isActived ? '#993A6FD8' : '#1AFFFFFF'
          })
        }
      }, (c: CharDetailRankItem) => `cons_${c.pos}`)
    }
  }
}
