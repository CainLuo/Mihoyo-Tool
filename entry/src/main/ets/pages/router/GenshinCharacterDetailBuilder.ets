import { GenshinCharacterDetail, GenshinCharacterDetailParam } from '../GenshinCharacterDetail';

@Builder
export function GenshinCharacterDetailBuilder(_name: string, param: object) {
  GenshinCharacterDetailDestination({ routerParam: param as GenshinCharacterDetailParam })
}

@ComponentV2
struct GenshinCharacterDetailDestination {
  @Param routerParam: GenshinCharacterDetailParam = new GenshinCharacterDetailParam();

  build() {
    NavDestination() {
      GenshinCharacterDetail({ routerParam: this.routerParam })
    }
    .title($r('app.string.char_detail_title'))
  }
}
