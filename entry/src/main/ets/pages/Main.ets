import { Home } from './Home';
import { My } from './My';
import { Setting } from './Setting';
import { AppRoute } from '../constants/AppRoute';

@Entry
@Component
struct Main {
  @Provide('pathStack') pathStack: NavPathStack = new NavPathStack();

  @Builder
  PageMap(name: string) {
    if (name == AppRoute.Setting) {
      NavDestination() {
        Setting()
      }
      .title('设置')
    }
  }

  build() {
    Navigation(this.pathStack) {
      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          Home()
        }.tabBar('首页')

        TabContent() {
          My()
        }.tabBar('我的')
      }
      .scrollable(false)
      .barHeight(60)
      .barMode(BarMode.Fixed)
    }
    .hideTitleBar(true)
    .navDestination(this.PageMap)
  }
}