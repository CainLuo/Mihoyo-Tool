import { GenshinCharacterDetail, GenshinCharacterDetailParam } from '../GenshinCharacterDetail';

@Builder
export function GenshinCharacterDetailBuilder(_name: string, param: Object) {
  GenshinCharacterDetailDestination({ routerParam: param as GenshinCharacterDetailParam })
}

@Component
struct GenshinCharacterDetailDestination {
  routerParam: GenshinCharacterDetailParam = new GenshinCharacterDetailParam();

  build() {
    NavDestination() {
      GenshinCharacterDetail({ routerParam: this.routerParam })
    }
    .title($r('app.string.char_detail_title'))
    .hideTitleBar(false)
  }
}
