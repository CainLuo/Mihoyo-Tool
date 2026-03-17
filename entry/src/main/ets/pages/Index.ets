import { HMDefaultGlobalAnimator, HMNavigation } from '@hadss/hmrouter';
import { AttributeUpdater } from '@kit.ArkUI';
import './Main';
import './Setting';

class MyNavModifier extends AttributeUpdater<NavigationAttribute> {
  initializeModifier(instance: NavigationAttribute): void {
    instance.hideNavBar(true);
  }
}

@Entry
@Component
struct Index {
  modifier: MyNavModifier = new MyNavModifier();

  build() {
    Column() {
      HMNavigation({
        navigationId: 'mainNavigationId',
        homePageUrl: 'Main',
        options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          modifier: this.modifier
        }
      });
    }
    .backgroundColor(Color.Transparent)
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}