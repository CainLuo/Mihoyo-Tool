# HMRouter

HMRouter作为应用内页面跳转场景解决方案，为开发者提供了功能完备、高效易用的路由框架。

HMRouter底层对系统Navigation进行封装，集成了[Navigation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation)、[NavDestination](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navdestination)、[NavPathStack](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation#navpathstack10)的系统能力，提供了可复用的路由拦截、页面生命周期、自定义转场动画，并且在跳转传参、额外的生命周期、服务型路由方面对系统能力进行了扩展，同时开发者可以高效的将历史代码中的Navigation组件接入到HMRouter框架中。

目的是让开发者在开发过程中减少模板代码，降低拦截器、自定义转场动画、组件感知页面生命周期等高频开发场景的实现复杂度，帮助开发者更好的实现路由与业务模块间的解耦。

## 特性

- 基于注解声明路由信息（普通页面、Dialog页面、单例页面）
- 注解参数支持使用字符串常量定义
- 页面路径支持正则匹配
- 支持在Har、Hsp、Hap中使用
- 支持Navigation路由栈嵌套
- 支持服务型路由
- 跳转时支持标准URL解析
- 支持路由拦截器（包含全局拦截、单页面拦截、跳转时一次性拦截）
- 支持生命周期回调（包含全局生命周期、单页面生命周期、NavBar生命周期）
- 内置转场动画（普通页面、Dialog），支持交互式转场动画，同时支持配置某个页面的转场动画、跳转时的一次性动画
- 提供更多高阶转场动画，包括一镜到底等（需依赖`@hadss/hmrouter-transitions`）
- 支持配置自定义页面模版，可以更灵活的生成页面文件
- 支持混淆白名单自动配置
- 支持与系统Navigation/NavDestination组件混用

## 依赖系统版本

SDK: Ohos_sdk_public 5.0.3.135 (API 15 Release)及以上

## 快速开始

### 1. 安装依赖

#### 使用 ohpm 安装

```shell
# 安装路由框架核心库
ohpm install @hadss/hmrouter

# 如需高级转场动画，安装转场动画库
ohpm install @hadss/hmrouter-transitions
```

### 2. 配置编译插件

#### 依赖配置

修改工程根目录下的`hvigor/hvigor-config.json` 文件，加入路由编译插件

```json5
{
  "dependencies": {
    "@hadss/hmrouter-plugin": "^1.2.2"  // 使用npm仓版本号
  },
  // ...其余配置
}
```

#### 插件配置
修改工程根目录下的`hvigorfile.ts`，使用路由编译插件

```typescript
// 工程根目录/hvigorfile.ts
import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { appPlugin } from "@hadss/hmrouter-plugin";

export default {
  system: appTasks,
  plugins: [appPlugin({ ignoreModuleNames: [ /** 不需要扫描的模块 **/ ] })]
};
```

> 模块中单独配置，使用`modulePlugin()`
> 
> 插件配置详情请参考[插件使用说明](https://gitcode.com/openharmony-sig/ohrouter/tree/master/docs/PluginConfig.md)

### 3. 初始化路由框架

在 UIAbility 或者启动框架 AppStartup 中初始化路由框架

```extendtypescript
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 日志开启需在init之前调用，否则会丢失初始化日志
    HMRouterMgr.openLog("INFO")
    HMRouterMgr.init({
      context: this.context
    })
  }
}
```

使用启动框架请查看：[如何在启动框架中初始化HMRouter](https://gitee.com/hadss/hmrouter/wikis/如何在启动框架中初始化HMRouter)

### 4. 定义路由入口

HMRouter 依赖系统 Navigation 能力，**所以必须在页面中定义一个 `HMNavigation` 容器**，并设置相关参数，具体代码如下：

```extendtypescript
@Entry
@Component
export struct Index {
  modifier: MyNavModifier = new MyNavModifier();

  build() {
    // @Entry中需要再套一层容器组件,Column或者Stack
    Column(){
      // 使用HMNavigation容器
      HMNavigation({
        navigationId: 'MainNavigation', homePageUrl: 'HomePage',
        options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          dialogAnimator: HMDefaultGlobalAnimator.DIALOG_ANIMATOR,
          modifier: this.modifier
        }
      })
    }
    .height('100%')
    .width('100%')
  }
}

class MyNavModifier extends AttributeUpdater<NavigationAttribute> {
  initializeModifier(instance: NavigationAttribute): void {
    instance.hideNavBar(true);
  }
}
```

[Navigation](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation)的系统属性通过[modifier](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-attributes-attribute-modifier)传递，部分`modifier`不支持的属性使用`options`设置

### 5. 页面定义与路由跳转

使用 `@HMRouter` 标签定义页面，绑定拦截器、生命周期及自定义转场动画

```extendtypescript
@HMRouter({
  pageUrl: 'PageB',
  interceptor: ['PageInterceptor'],
  lifecycle: 'pageLifecycle',
  animator: 'pageAnimator'
})
@Component
export struct PageB {
  // 获取生命周期中定义的状态变量
  @State model: ObservedModel | null = (HMRouterMgr.getCurrentLifecycleOwner().getLifecycle() as PageLifecycle).model
  @State param: HMPageParam = HMRouterMgr.getCurrentParam(HMParamType.all)

  build() {
    Column() {
      Text(`${this.model?.property}`)
      Text(`${this.param.urlParam?.get('msg')}`)
    }
  }
}
```

定义页面 HomePage，使用 `HMRouterMgr.push` 执行路由跳转至 PageB

```extendtypescript
const PAGE_URL: string = 'HomePage'

@HMRouter({ pageUrl: PAGE_URL })
@Component
export struct HomePage {
  build() {
    Column() {
      Button('Push')
        .onClick(() => {
          HMRouterMgr.push({ pageUrl: 'PageB?msg=abcdef' })
        })
    }
  }
}
```

> 路由跳转支持URL带参数的方式，例如定义的页面pageUrl: `/pages1/users`，跳转时可以指定pageUrl为: `/pages1/users?msg=1234`
> 
> 通过HMRouterMgr.getCurrentParam传入HMParamType.all获取URL的参数内容

### 6. 定义拦截器

使用 `HMInterceptor` 定义拦截器，并实现`IHMInterceptor`接口

```extendtypescript
@HMInterceptor({ interceptorName: 'PageInterceptor' })
export class PageInterceptor implements IHMInterceptor {
  handle(info: HMInterceptorInfo): HMInterceptorAction {
    if (isLogin) {
      // 跳转下一个拦截器处理
      return HMInterceptorAction.DO_NEXT;
    } else {
      HMRouterMgr.push({
        pageUrl: 'LoginPage',
        param: { targetUrl: info.targetName },
        skipAllInterceptor: true
      })
      // 拦截结束，不再执行下一个拦截器，不再执行相关转场和路由栈操作
      return HMInterceptorAction.DO_REJECT;
    }
  }
}
```

### 7. 定义生命周期

#### 组件感知页面生命周期

通过 `addObserver` 接口，组件可以感知页面的生命周期事件：

```extendtypescript
@Component
struct ChildComponent {
  @State backPressCount: number = 0;
  private lifecycleOwner = HMRouterMgr.getCurrentLifecycleOwner();
  private handleCallback = () => {
    this.showToast();
    this.backPressCount++;
    return true;
  }

  aboutToAppear(): void {
    this.lifecycleOwner?.addObserver(HMLifecycleState.onBackPressed, this.handleCallback);
  }

  aboutToDisappear(): void {
    this.lifecycleOwner?.removeObserver(HMLifecycleState.onBackPressed, this.handleCallback);
  }

  // 组件内定义的方法
  showToast() {
    this.getUIContext().getPromptAction().showToast({ message: RouterPageConstant.LIFECYCLE_CASE1_TOAST });
  }

  build() {
    // UI内容
  }
}
```

#### 页面绑定生命周期

使用`@HMLifecycle`标签定义生命周期处理器，并实现`IHMLifecycle`接口，页面可在 `@HMRouter` 注解中通过 `lifecycle` 属性来绑定

```extendtypescript
@HMLifecycle({ lifecycleName: 'PageLifecycle' })
export class PageLifecycle implements IHMLifecycle {
  model: ObservedModel = new ObservedModel()
  private time: number = 0;

  onShown(ctx: HMLifecycleContext): void {
    this.time = new Date().getTime();
  }

  onHidden(ctx: HMLifecycleContext): void {
    const duration = new Date().getTime() - this.time;
    console.info(`Page ${ctx.navContext?.pathInfo.name} stay ${duration}`);
  }
}
```
### 8. 定义转场动画

通过`@HMAnimator`标签定义转场动画，并实现`IHMAnimator`接口

```extendtypescript
@HMAnimator({ animatorName: 'PageAnimator' })
export class PageAnimator implements IHMAnimator {
  effect(enterHandle: HMAnimatorHandle, exitHandle: HMAnimatorHandle): void {
    // 入场动画
    enterHandle.start((modifier: AttributeUpdater<NavDestinationAttribute>) => {
      modifier.attribute?.translate({ y: "100%" }).opacity(0.4);
    }).finish((modifier: AttributeUpdater<NavDestinationAttribute>) => {
      modifier.attribute?.translate({ y: "0" }).opacity(1);
    }).onFinish((modifier: AttributeUpdater<NavDestinationAttribute>) => {
      modifier.attribute?.translate({ y: "0" }).opacity(1);
    });

    // 出场动画
    exitHandle.start((modifier: AttributeUpdater<NavDestinationAttribute>) => {
      modifier.attribute?.translate({ y: "0" }).opacity(1);
    }).finish((modifier: AttributeUpdater<NavDestinationAttribute>) => {
      modifier.attribute?.translate({ y: "100%" }).opacity(0.4);
    }).onFinish((modifier: AttributeUpdater<NavDestinationAttribute>) => {
      modifier.attribute?.translate({ y: "0" }).opacity(1);
    });
  }
}
```

自定义转场动画的详细使用：[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/CustomTransition.md)

### 9. 服务路由使用

服务路由用于类似服务提供发现机制(Service Provider Interface)，通过不依赖实现模块的方式获取接口实例并调用方法，可以直接获取服务实例对象，也可以直接进行方法级服务调用

```extendtypescript
// 方法级服务
export class CustomService {
  @HMService({ serviceName: 'testFunWithReturn' })
  testFunWithReturn(param1: string, param2: string): string {
    return `调用服务 testFunWithReturn:${param1} ${param2}`
  }
}

// 定义服务接口
interface IDataService {
  fetchData(page: number, size: number): Promise<Object[]>;
}
// 实现服务提供者
@HMServiceProvider({ serviceName: 'DataService', singleton: true })
class DataServiceImpl implements IDataService {
  async fetchData(page: number, size: number): Promise<Object[]> {
    // 实现数据获取逻辑
    return [];
  }
}

@HMRouter({ pageUrl: 'test://MainPage' })
@Component
export struct Index {

  build() {
    Row() {
      Column({ space: 8 }) {
        Button('service').onClick(() => {
          // 使用getService拿到实例对象
          let data = HMRouterMgr.getService<IDataService>('DataService').fetchData();
          // 直接调用方法级服务
          Logger.info(HMRouterMgr.request('testFunWithReturn', 'home', 'service').data)
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

## 应用内页面跳转场景解决方案

[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Scene.md)

## 与系统Navigation/NavDestination组件混用说明

[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Migration.md)

## 混淆说明

[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Obfuscation.md)

## API参考

[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md)

## 插件使用说明

[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/PluginConfig.md)

## FAQ

[查看详情](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/FAQ.md)

## Sample参考

- [Sample示例代码](https://gitee.com/harmonyos_samples/HMRouter)，通过购物App展示`HMRouter`在页面跳转场景中的使用

- 更丰富、更完整的API示例代码[查看详情](https://gitcode.com/openharmony-sig/ohrouter/tree/master/HMRouterExamples)

## 原理介绍

[查看详情](https://developer.huawei.com/consumer/cn/forum/topic/0207153170697988820?fid=0109140870620153026) 

## 贡献代码

使用过程中发现任何问题都可以提 [Issue](https://gitcode.com/openharmony-sig/ohrouter/issues) ，当然，也非常欢迎发 [PullRequest](https://gitcode.com/openharmony-sig/ohrouter/pulls) 共建。

## 开源协议

本项目基于 [Apache License 2.0](https://gitcode.com/openharmony-sig/ohrouter/blob/master/LICENSE) ，请自由地享受和参与开源。