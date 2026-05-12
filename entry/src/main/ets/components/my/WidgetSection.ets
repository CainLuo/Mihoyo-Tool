/**
 * WidgetSection — My 页面的 Widget 卡片入口区域
 */
import { formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger } from 'core';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MyAccountVM } from '../../models/MyModels';

const TAG = 'WIDGET';
const BUNDLE_NAME = 'com.cainluo.miyoyo.tools';
const ABILITY_NAME = 'EntryFormAbility';
const MODULE_NAME = 'entry';

function gameIdToFormName(gameId: string): string {
  if (gameId === 'genshin') { return 'widget_1x2_genshin'; }
  if (gameId === 'starrail') { return 'widget_1x2_starrail'; }
  if (gameId === 'zzz') { return 'widget_1x2_zzz'; }
  return 'widget_2x2';
}

/**
 * 根据 formName 返回对应的 FormDimension 数值
 * 参考 FormDimension 枚举：Dimension_1_2=1, Dimension_2_2=2, Dimension_2_4=3, Dimension_4_4=4
 */
function formNameToDimension(formName: string): number {
  if (formName === 'widget_1x2_genshin' || formName === 'widget_1x2_starrail' || formName === 'widget_1x2_zzz') {
    return 1; // 1×2
  }
  if (formName === 'widget_2x4') { return 3; } // 2×4
  if (formName === 'widget_4x4') { return 4; } // 4×4
  return 2; // 2×2（默认）
}

function gameIdToLabel(gameId: string): ResourceStr {
  if (gameId === 'genshin') { return $r('app.string.game_name_genshin'); }
  if (gameId === 'starrail') { return $r('app.string.game_name_starrail'); }
  if (gameId === 'zzz') { return $r('app.string.game_name_zzz'); }
  return gameId;
}

@ComponentV2
export struct WidgetSection {
  @Param accounts: MyAccountVM[] = [];
  @Local private tm: ThemeManager = themeManager;

  private openFormManager(accountId: string, formName: string, selectedGames: string[]): void {
    const want: Want = {
      bundleName: BUNDLE_NAME,
      abilityName: ABILITY_NAME,
      parameters: {
        'ohos.extra.param.key.form_dimension': formNameToDimension(formName),
        'ohos.extra.param.key.form_name': formName,
        'ohos.extra.param.key.module_name': MODULE_NAME,
        'accountId': accountId,
        'selectedGames': selectedGames.join(','),
      },
    };
    try {
      formProvider.openFormManager(want);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `openFormManager failed: code=${err.code} msg=${err.message}`);
    }
  }

  private getGameIds(account: MyAccountVM): string[] {
    const gameIds: string[] = [];
    for (let i = 0; i < account.roles.length; i++) {
      const gid = account.roles[i].gameId;
      if (gameIds.indexOf(gid) < 0) {
        gameIds.push(gid);
      }
    }
    return gameIds;
  }

  build() {
    Column() {
      ForEach(this.accounts, (account: MyAccountVM) => {
        this.AccountWidgetBlock(account)
      }, (account: MyAccountVM) => account.uid)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }

  @Builder
  AccountWidgetBlock(account: MyAccountVM) {
    Column({ space: 0 }) {
      Row() {
        Text(account.nickname.length > 0 ? account.nickname : account.username)
          .fontSize(this.tm.current.body13.size)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Text(account.uid)
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding({
        top: this.tm.current.value12,
        bottom: this.tm.current.value8,
        left: this.tm.current.value16,
        right: this.tm.current.value16,
      })

      Row({ space: this.tm.current.value8 }) {
        ForEach(this.getGameIds(account), (gameId: string) => {
          Button({ type: ButtonType.Normal }) {
            Text(gameIdToLabel(gameId))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.colorTextPrimary)
          }
          .height(this.tm.current.value36)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
          .backgroundColor(this.tm.current.colorSurfaceSubtle)
          .borderRadius(this.tm.current.radius8)
          .onClick(() => {
            this.openFormManager(account.uid, gameIdToFormName(gameId), [gameId]);
          })
        }, (gameId: string) => gameId)

        if (this.getGameIds(account).length >= 2) {
          Button({ type: ButtonType.Normal }) {
            Text($r('app.string.widget_add_all_games'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.colorPrimary)
          }
          .height(this.tm.current.value36)
          .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
          .backgroundColor('rgba(58,111,216,0.15)')
          .borderRadius(this.tm.current.radius8)
          .onClick(() => {
            this.openFormManager(account.uid, 'widget_2x2', this.getGameIds(account));
          })
        }
      }
      .width(this.tm.current.full)
      .padding({
        bottom: this.tm.current.value12,
        left: this.tm.current.value16,
        right: this.tm.current.value16,
      })
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@ComponentV2
export struct WidgetSectionPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 16 }) {
      WidgetSection({ accounts: [] })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
