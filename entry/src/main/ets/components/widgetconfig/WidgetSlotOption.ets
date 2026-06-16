/**
 * WidgetSlotOption — 角色选项组件
 *
 * 用于 Widget 配置页的步骤 3，展示可选的角色 slots。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { gameIdStrToLogo } from '../../utils/GameIdUtil';
import { TransparentColorCache } from '../../utils/ColorUtil';

@ComponentV2
export struct WidgetSlotOption {
  @Local private tm: ThemeManager = themeManager;
  /** 角色信息 */
  @Param slot: WidgetSlotRef = new WidgetSlotRef();
  /** 游戏颜色（使用 ResourceColor 支持资源引用） */
  @Param gameColor: ResourceColor = $r('app.color.color_primary');
  /** 游戏名称 */
  @Param gameName: ResourceStr = '';
  /** 是否选中 */
  @Param isSelected: boolean = false;
  /** 点击回调 */
  @Param onTap: () => void = () => {};

  build() {
    Row() {
      // 左侧：游戏 logo
      Image(gameIdStrToLogo(this.slot.gameId))
        .width(this.tm.current.value40)
        .height(this.tm.current.value40)
        .borderRadius(this.tm.current.radius12)
        .objectFit(ImageFit.Cover)

      // 中间：账号 + 游戏 + 角色信息
      Column() {
        Row({ space: this.tm.current.value4 }) {
          Text(this.slot.accountName)
            .fontSize(this.tm.current.fontBold14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isSelected ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary)

          Text('·')
            .fontSize(this.tm.current.font14)
            .fontColor(this.tm.current.colorTextSecondary)

          Text(this.gameName)
            .fontSize(this.tm.current.font13)
            .fontColor(this.gameColor)
        }

        Row({ space: this.tm.current.value4 }) {
          Text(this.slot.nickname)
            .fontSize(this.tm.current.font13)
            .fontColor(this.tm.current.colorTextSecondary)

          Text(`UID ${this.slot.roleId}`)
            .fontSize(this.tm.current.font11)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .margin({ top: this.tm.current.value2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: this.tm.current.value12 })

      // 右侧：选中状态
      Row() {
        if (this.isSelected) {
          Text('✓')
            .fontSize(this.tm.current.font13)
            .fontColor(Color.White)
        }
      }
      .width(this.tm.current.font18)
      .height(this.tm.current.font18)
      .borderRadius(this.tm.current.value9)
      .backgroundColor(this.isSelected ? this.gameColor : Color.Transparent)
      .border({
        width: this.tm.current.value2,
        color: this.isSelected ? this.gameColor : this.tm.current.colorDivider
      })
      .justifyContent(FlexAlign.Center)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.font14)
    .backgroundColor(this.isSelected ? TransparentColorCache.blue500With15 : this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: this.tm.current.value1,
      color: this.isSelected ? TransparentColorCache.blue500With60 : this.tm.current.colorDivider
    })
    .onClick(() => { this.onTap(); })
  }
}

@Preview
@ComponentV2
struct WidgetSlotOptionPreview {
  @Local private tm: ThemeManager = themeManager;
  @Local private genshinSlot: WidgetSlotRef = this.createGenshinSlot();
  @Local private starrailSlot: WidgetSlotRef = this.createStarRailSlot();

  build() {
    Column({ space: this.tm.current.value10 }) {
      WidgetSlotOption({
        slot: this.genshinSlot,
        gameColor: '#5ba3e8',
        gameName: $r('app.string.game_name_genshin'),
        isSelected: true
      })
      WidgetSlotOption({
        slot: this.starrailSlot,
        gameColor: '#9b8eff',
        gameName: $r('app.string.game_name_starrail'),
        isSelected: false
      })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }

  private createGenshinSlot(): WidgetSlotRef {
    const slot = new WidgetSlotRef();
    slot.accountId = '182692936';
    slot.accountName = 'CainLuo';
    slot.gameId = 'genshin';
    slot.roleId = '109050292';
    slot.nickname = '凹凸曼的小怪兽';
    slot.server = 'cn_gf01';
    return slot;
  }

  private createStarRailSlot(): WidgetSlotRef {
    const slot = new WidgetSlotRef();
    slot.accountId = '182692936';
    slot.accountName = 'CainLuo';
    slot.gameId = 'starrail';
    slot.roleId = '102731382';
    slot.nickname = '凹凸曼的小怪兽';
    slot.server = 'prod_gf_cn';
    return slot;
  }
}
