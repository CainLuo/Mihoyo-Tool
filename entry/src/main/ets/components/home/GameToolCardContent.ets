/**
 * GameToolCardContent — 游戏战绩卡片内容区（四个游戏通用）
 *
 * 主体力区块（大数字+进度圈+恢复描述）+ 分割线 + 数据行列表。
 * 数据行由 ViewModel 填充，View 层只做 ForEach 渲染，不做任何业务判断。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameNoteSnapshotVM, GameDataRowVM } from '../../models/HomeModels';
import { GameStaminaBlock } from './GameStaminaBlock';
import { GameDataRow } from './GameDataRow';

@ComponentV2
export struct GameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, 0, '', '', false);
  @Param primaryColor: ResourceColor = $r('app.color.color_primary');
  @Param progressRatio: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      GameStaminaBlock({
        label: this.snap.primaryLabel,
        current: this.snap.primaryCurrent,
        max: this.snap.primaryMax,
        recoverySeconds: this.snap.primaryRecoverySeconds,
        recoveryColor: this.snap.isFull ? this.tm.current.colorDanger : this.tm.current.colorTextSecondary,
        primaryColor: this.primaryColor,
        progressRatio: this.progressRatio
      })

      if (this.snap.dataRows.length > 0) {
        Divider().color(this.tm.current.colorDivider)

        ForEach(this.snap.dataRows, (row: GameDataRowVM) => {
          GameDataRow({
            label: row.label,
            value: row.value,
            valueColor: row.valueColor
          })
        }, (row: GameDataRowVM, idx: number) => `row_${idx}`)
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12,
      top: this.tm.current.value8,
      bottom: this.tm.current.value12
    })
    .alignItems(HorizontalAlign.Start)
  }
}
