import { GenshinDailyDetail, GenshinDailyDetailParam } from '../GenshinDailyDetail'

@Builder
export function GenshinDailyDetailBuilder(_name: string, param: object) {
  GenshinDailyDetailDestination({ routerParam: param as GenshinDailyDetailParam })
}

@Component
struct GenshinDailyDetailDestination {
  @Prop routerParam: GenshinDailyDetailParam = new GenshinDailyDetailParam()

  build() {
    NavDestination() {
      GenshinDailyDetail({ routerParam: this.routerParam })
    }
    .title($r('app.string.genshin_daily_title'))
  }
}
