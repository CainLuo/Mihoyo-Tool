import { Home } from './Home';
import { My } from './My';
import { HMLifecycleState, HMPopInfo, HMRouter, HMRouterMgr } from '@hadss/hmrouter';

@HMRouter({ pageUrl: 'Main', lifecycle: 'ExitAppLifecycle' })
@Component
struct Main {
  build() {
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
}