import { HMDefaultGlobalAnimator, HMNavigation } from '@hadss/hmrouter';
import { AttributeUpdater } from '@kit.ArkUI';

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
      // [End hum_navigation]
    }
    .backgroundColor(Color.Red)
    .height('100%')
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}