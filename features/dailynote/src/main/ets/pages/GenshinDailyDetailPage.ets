/**
 * GenshinDailyDetailPage — 原神实时便笺详情页（View 层）
 *
 * 通过路由参数接收 accountId + roleUid，
 * 由 GenshinDailyDetailViewModel 从 DB 读取并解析数据。
 */

import { themeManager, ThemeManager } from 'basic'
import { DailyNoteGenshin } from '../views/genshin/DailyNoteGenshin'
import { GenshinDailyDetailViewModel } from '../viewmodel/GenshinDailyDetailViewModel'
import { DailyDetailScaffold } from '../views/common/DailyDetailScaffold'

/** 系统 Navigation 传入的路由参数 */
export class GenshinDailyDetailParam {
  accountId: string = '';
  roleUid: string = '';
}

@ComponentV2
export struct GenshinDailyDetailPage {
  @Param routerParam: GenshinDailyDetailParam = new GenshinDailyDetailParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: GenshinDailyDetailViewModel = new GenshinDailyDetailViewModel()

  aboutToAppear(): void {
    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid)
    this.vm.loadData()
  }

  @Builder
  gameContent() {
    DailyNoteGenshin({ data: this.vm.note })
      .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
  }

  build() {
    DailyDetailScaffold({
      title: $r('app.string.genshin_daily_title'),
      viewState: this.vm.viewState,
      content: () => { this.gameContent() }
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct GenshinDailyDetailPagePreview {
  build() {
    GenshinDailyDetailPage({ routerParam: new GenshinDailyDetailParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function GenshinDailyDetailPageBuilder(_name: string, param: Object) {
  GenshinDailyDetailPage({ routerParam: param as GenshinDailyDetailParam })
}
