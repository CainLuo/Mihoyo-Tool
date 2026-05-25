/**
 * CharDetailRelicPlaceholder — 遗器/驱动盘未装备占位格
 *
 * 三个游戏通用：锁图标 + 位置名称，虚线边框。
 * posName 接受 ResourceStr（Resource 或 string），绝区零传数字字符串，原神/星铁传 $r()。
 * 使用方：CharDetailRelicsPanel、StarRailCharDetailContent、ZZZEquipSection
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';

@ComponentV2
export struct CharDetailRelicPlaceholder {
  /** 位置名称（ResourceStr，支持 $r() 或普通字符串） */
  @Param posName: ResourceStr = '';
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      SymbolGlyph($r('sys.symbol.lock'))
        .fontSize(this.tm.current.font20)
        .fontColor([this.tm.current.textOnDarkMuted])
      Text(this.posName)
        .fontSize(this.tm.current.font13)
        .fontColor(this.tm.current.textOnDarkMuted)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.tm.current.surfaceDarkMd)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceInactiveBorder, style: BorderStyle.Dashed })
    .borderRadius(this.tm.current.radius8)
  }
}
