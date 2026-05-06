/**
 * WidgetConfigPreview — Widget 配置页卡片预览组件
 *
 * 根据选中的尺寸和 slots 渲染卡片预览。
 * 使用占位数据，仅用于配置页预览，不依赖真实 Widget 数据。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { GameId } from 'core';

/** 占位数据：体力值 */
class StaminaData {
  cur: number = 0;
  max: number = 0;
  rec: string = '';

  constructor(cur: number, max: number, rec: string) {
    this.cur = cur;
    this.max = max;
    this.rec = rec;
  }
}

/** 尺寸宽高配置 */
class SizeDimension {
  width: number = 168;
  height: number = 168;

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }
}

/** 游戏颜色 */
function gameColor(gameId: string): string {
  if (gameId === GameId.GENSHIN || gameId === 'genshin') return '#5ba3e8';
  if (gameId === GameId.STARRAIL || gameId === 'starrail') return '#9b8eff';
  if (gameId === GameId.ZZZ || gameId === 'zzz') return '#f7b84b';
  return '#888888';
}

/** 游戏名称 */
function gameName(gameId: string): string {
  if (gameId === GameId.GENSHIN || gameId === 'genshin') return '原神';
  if (gameId === GameId.STARRAIL || gameId === 'starrail') return '崩坏：星穹铁道';
  if (gameId === GameId.ZZZ || gameId === 'zzz') return '绝区零';
  return '未知游戏';
}

/** 获取占位体力数据 */
function getStaminaData(gameId: string): StaminaData {
  if (gameId === GameId.GENSHIN || gameId === 'genshin') {
    return new StaminaData(140, 200, '4小时后回满');
  }
  if (gameId === GameId.STARRAIL || gameId === 'starrail') {
    return new StaminaData(200, 300, '6小时后回满');
  }
  if (gameId === GameId.ZZZ || gameId === 'zzz') {
    return new StaminaData(180, 240, '3小时后回满');
  }
  return new StaminaData(0, 0, '');
}

/** 体力颜色：0-30% 红色，30-70% 橙色，70-100% 游戏主题色 */
function staminaColor(ratio: number, gameId: string): string {
  if (ratio <= 0.3) return '#ef5350';
  if (ratio <= 0.7) return '#ffca28';
  return gameColor(gameId);
}

/** 尺寸配置 */
const SIZE_DIMENSIONS: Record<string, SizeDimension> = {
  [WidgetSize.SIZE_1x2]: new SizeDimension(168, 80),
  [WidgetSize.SIZE_2x2]: new SizeDimension(168, 168),
  [WidgetSize.SIZE_2x4]: new SizeDimension(336, 168),
  [WidgetSize.SIZE_4x4]: new SizeDimension(336, 336),
};

/** 游戏背景色 */
function cardBgColors(gameId: string): string[] {
  if (gameId === GameId.GENSHIN || gameId === 'genshin') {
    return ['#152030', '#1a2d42', '#1c3350'];
  }
  if (gameId === GameId.STARRAIL || gameId === 'starrail') {
    return ['#181828', '#201830', '#261c40'];
  }
  if (gameId === GameId.ZZZ || gameId === 'zzz') {
    return ['#1e1a0e', '#2a2010', '#342810'];
  }
  return ['#181820', '#1c1c2c', '#1c1c2c'];
}

@ComponentV2
export struct WidgetConfigPreview {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Param selectedSlots: WidgetSlotRef[] = [];
  @Local private tm: ThemeManager = themeManager;

  private get dimensions(): SizeDimension {
    const dim = SIZE_DIMENSIONS[this.selectedSize];
    return dim !== undefined ? dim : SIZE_DIMENSIONS[WidgetSize.SIZE_2x2];
  }

  private get firstGameId(): string {
    if (this.selectedSlots.length === 0) {
      return 'genshin';
    }
    return this.selectedSlots[0].gameId;
  }

  private get cardGradient(): LinearGradient {
    const colors = cardBgColors(this.firstGameId);
    return {
      angle: this.tm.current.a135,
      colors: [[colors[0], 0], [colors[1], 0.5], [colors[2], 1]]
    };
  }

  build() {
    Column() {
      if (this.selectedSlots.length === 0) {
        this.EmptyPreview()
      } else if (this.selectedSize === WidgetSize.SIZE_1x2) {
        this.Preview1x2()
      } else if (this.selectedSize === WidgetSize.SIZE_2x2) {
        this.Preview2x2()
      } else if (this.selectedSize === WidgetSize.SIZE_2x4) {
        this.Preview2x4()
      } else {
        this.Preview4x4()
      }
    }
    .width(this.dimensions.width)
    .height(this.dimensions.height)
    .padding(this.tm.current.value12)
    .linearGradient(this.cardGradient)
    .borderRadius(this.tm.current.radius12)
    .shadow({
      radius: 8,
      offsetY: 2,
      color: 'rgba(0,0,0,0.5)'
    })
  }

  // ─── 空态预览 ─────────────────────────────────────────────────────

  @Builder
  EmptyPreview() {
    Column() {
      Text('请选择要显示的角色')
        .fontSize(this.tm.current.body12.size)
        .fontColor('rgba(255,255,255,0.5)')
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
  }

  // ─── 1x2 预览 ─────────────────────────────────────────────────────

  @Builder
  Preview1x2() {
    Row() {
      // 左侧：游戏色竖线装饰条
      Column()
        .width(3)
        .height(this.dimensions.height - this.tm.current.value24)
        .borderRadius(2)
        .backgroundColor(gameColor(this.firstGameId))

      // 内容区
      if (this.selectedSlots.length > 0) {
        this.Preview1x2Content(this.selectedSlots[0])
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  Preview1x2Content(slot: WidgetSlotRef) {
    Column() {
      // 第一行：游戏名 + UID
      Row({ space: this.tm.current.value4 }) {
        Text(gameName(slot.gameId))
          .fontSize(10)
          .fontWeight(500)
          .fontColor('rgba(255,255,255,0.6)')

        Text(`UID ${slot.roleId}`)
          .fontSize(9)
          .fontColor('rgba(255,255,255,0.35)')
      }

      // 第二行：当前体力/最大体力
      Row({ space: 2 }) {
        Text(String(getStaminaData(slot.gameId).cur))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(staminaColor(getStaminaData(slot.gameId).cur / getStaminaData(slot.gameId).max, slot.gameId))

        Text('/' + String(getStaminaData(slot.gameId).max))
          .fontSize(18)
          .fontColor('rgba(255,255,255,0.4)')
      }

      // 第三行：恢复时间
      Text(getStaminaData(slot.gameId).rec)
        .fontSize(10)
        .fontColor('rgba(255,255,255,0.4)')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .margin({ left: this.tm.current.value8 })
    .justifyContent(FlexAlign.Center)
  }

  // ─── 2x2 预览 ─────────────────────────────────────────────────────

  @Builder
  Preview2x2() {
    if (this.selectedSlots.length === 1) {
      this.Preview2x2SingleSlot()
    } else {
      this.Preview2x2MultiSlot()
    }
  }

  @Builder
  Preview2x2SingleSlot() {
    Column() {
      // 头部：游戏名 + UID
      Column({ space: 1 }) {
        Text(gameName(this.firstGameId))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('rgba(255,255,255,0.8)')
          .maxLines(1)

        Text(`UID ${this.selectedSlots[0].roleId}`)
          .fontSize(10)
          .fontColor('rgba(255,255,255,0.35)')
      }
      .width(this.tm.current.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: this.tm.current.value8 })

      // 体力区块
      this.StaminaBlock(this.firstGameId)

      // 额外信息
      Text(this.selectedSlots[0].nickname)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.45)')
        .margin({ top: this.tm.current.value8 })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  Preview2x2MultiSlot() {
    Column() {
      // 头部：账号名
      if (this.selectedSlots.length > 0) {
        Text(this.selectedSlots[0].accountName)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('rgba(255,255,255,0.7)')
          .margin({ bottom: this.tm.current.value4 })
      }

      // 游戏行
      ForEach(this.selectedSlots, (slot: WidgetSlotRef, idx: number) => {
        this.GameRow(slot, idx)
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  GameRow(slot: WidgetSlotRef, idx: number) {
    Column() {
      Row() {
        // 左侧：游戏色竖线
        Column()
          .width(3)
          .height(30)
          .borderRadius(2)
          .backgroundColor(gameColor(slot.gameId))

        // 中间：游戏名 + 体力 + 恢复时间
        Column({ space: 1 }) {
          Text(gameName(slot.gameId))
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.5)')
            .maxLines(1)

          Row({ space: 2 }) {
            Text(String(getStaminaData(slot.gameId).cur))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(staminaColor(getStaminaData(slot.gameId).cur / getStaminaData(slot.gameId).max, slot.gameId))

            Text('/' + String(getStaminaData(slot.gameId).max))
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.35)')
          }

          Text(getStaminaData(slot.gameId).rec)
            .fontSize(9)
            .fontColor('rgba(255,255,255,0.4)')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: this.tm.current.value8 })
      }
      .width(this.tm.current.full)

      if (idx < this.selectedSlots.length - 1) {
        Divider()
          .width(this.tm.current.full)
          .height(1)
          .color('rgba(255,255,255,0.08)')
          .margin({ top: this.tm.current.value4, bottom: this.tm.current.value4 })
      }
    }
  }

  @Builder
  StaminaBlock(gameId: string) {
    Column({ space: 2 }) {
      Row({ space: 3 }) {
        Text(String(getStaminaData(gameId).cur))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(staminaColor(getStaminaData(gameId).cur / getStaminaData(gameId).max, gameId))

        Text('/' + String(getStaminaData(gameId).max))
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.4)')
      }

      Text(getStaminaData(gameId).rec)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.5)')
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: this.tm.current.value8 })
  }

  // ─── 2x4 预览（暂用 2x2 布局缩放）─────────────────────────────────

  @Builder
  Preview2x4() {
    this.Preview2x2()
  }

  // ─── 4x4 预览（暂用 2x2 布局缩放）─────────────────────────────────

  @Builder
  Preview4x4() {
    this.Preview2x2()
  }
}

@Preview
@ComponentV2
struct WidgetConfigPreviewSample {
  @Local private tm: ThemeManager = themeManager;
  @Local private sampleSlots: WidgetSlotRef[] = [];

  aboutToAppear(): void {
    const slot = new WidgetSlotRef();
    slot.accountId = '1';
    slot.accountName = '旅行者A';
    slot.gameId = 'genshin';
    slot.roleId = '123';
    slot.nickname = '荧';
    slot.server = 'cn_gf01';
    this.sampleSlots = [slot];
  }

  build() {
    Column({ space: 16 }) {
      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_2x2,
        selectedSlots: []
      })

      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_2x2,
        selectedSlots: this.sampleSlots
      })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
