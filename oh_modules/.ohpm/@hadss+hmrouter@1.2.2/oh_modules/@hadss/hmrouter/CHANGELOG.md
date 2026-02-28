# 更新记录

## 1.2.2 (2025.10.27)

### Bug Fixes

- [修复onWillAppear和onReady生命周期内获取id信息异常的稳定性问题](https://gitcode.com/openharmony-sig/ohrouter/issues/217)

## 1.2.0 (2025.09.17)

### Features

- 新增[适配API12后的生命周期](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#ihmlifecycle)
- 新增[支持设置默认navigationId](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#setDefaultNavigationId)

### Bug Fixes

- [修复注销生命周期、拦截器的问题](https://gitcode.com/openharmony-sig/ohrouter/issues/162)

## 1.2.0-rc.0 (2025.09.02)

### Features

- 新增[自定义日志代理](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#ihmlog)
- 新增[页面移除操作监听器](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#addremovelistener)

## 1.2.0-beta.1 (2025.07.29)

### Bug Fixes

- [修复HSP跨包跳转的问题](https://gitcode.com/openharmony-sig/ohrouter/issues/86)
- 废弃接口修改

## 1.2.0-beta.0 (2025.06.17)

### Features

- 支持[异步拦截器](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/AsyncInterceptor.md)，开发者可以在拦截器中调用异步接口
- 新增[链式调用API](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#to)
- 通过[HMServiceFactory](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#hmservicefactory)提供service能力的扩展性，开发者可以增强Service的实现，实现完整的IOC容器
- 新增[requestWithCallback接口](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#requestwithcallback)，通过回调处理服务调用的返回值
- 新增[handleUri接口](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Reference.md#handleUri)，提供处理外部跳转到应用内的请求

## 1.1.0-beta.0 (2025.04.11)

### Features

- 新增NavigationHelper/NavDestinationHelper类，用于[系统Navigation/NavDestination组件接入HMRouter](https://gitcode.com/openharmony-sig/ohrouter/blob/master/docs/Migration.md)
- @HMRouter注解新增useNavDst参数，用于已经定义的NavDestination页面
- 动画新增(modifier: AttributeUpdater<NavDestinationAttribute>) => void 回调类型，支持通过modifier修改页面动画属性

### Bug Fixes

- push/replace支持传入生命周期

## 1.0.0-rc.11 (2024.12.31)

### Features

- 支持@HMServiceProvider注解，定义服务路由在类上

### Bug Fixes

- 修复生命周期问题
- 修复systemBarStyle设置问题

## 1.0.0-rc.10 (2024.11.20)

### Features

- 支持自定义页面模版配置
- 页面路径支持正则匹配
- 支持url参数自动解析
- 注解参数支持跨模块常量定义
- 支持高阶转场动画（卡片一镜到底）

### Bug Fixes

- 全局拦截器逻辑变更，先执行全局拦截器再判断页面是否存在 #IARK6F
- 一次性动画执行逻辑修复
- 拦截器优先级问题修复 #IB2G9N

## 1.0.0-rc.6 (2024.09.27)

### Features

- 新增自动混淆配置参数`autoObfuscation`，开启可以自动配置HMRouter混淆白名单

### Refactor

- 优化初始化逻辑，去掉包管理接口，从文件中读取hsp模块名称

## 1.0.0-rc.5 (2024.09.14)

### Bug Fixes

- 修复popToIndex参数错误的bug
- 修复无法解析export default class定义的变量的bug

## 1.0.0-rc.4 (2024.09.13)

### Bug Fixes

- 修复HMNavigationOptions中toolbar设置失效的bug
- 修复IHMLifecycleOwner未导出的bug
- 修复启动框架无法初始化的bug
- 修复内置弹窗动画执行结束后状态未还原的bug

## 1.0.0-rc.3 (2024.08.31)

### Bug Fixes

- 修复动态加载在release模式下崩溃bug

## 1.0.0-rc.2 (2024.08.30)

### Features

- 支持服务路由，新增`@HMService`注解, `HMRouterMgr.request`接口
- `@HMRouter`中pageUrl支持字符串常量
- 新增`NavBar`生命周期

### Refactor

- 优化动态加载、生命周期、动画

### API Changes

- 移除`HMRouterMgr.getCurrentLifecycle()`接口
- 新增`HMRouterMgr.getCurrentLifecycleOwner()`接口，返回`IHMLifecycleOwner`生命周期托管者实例
- 变更`IHMLifecycle.addObserver()`：生命周期观察调用方式为使用`IHMLifecycleOwner.addObserver()`
- 变更`getCurrentLifecycle`：获取当前生命周期实例调用方式为使用`IHMLifecycleOwner.getCurrentLifecycle()`

## 1.0.0-rc.1 (2024.08.22)

### Bug Fixes

- 修复生命周期bug，README更新

## 1.0.0-rc.0 (2024.08.21)

### Initial

- 初版发布