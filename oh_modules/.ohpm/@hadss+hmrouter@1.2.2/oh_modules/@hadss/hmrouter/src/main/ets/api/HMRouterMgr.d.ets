import { collections } from '@kit.ArkTS';
import { HMInterceptorInstance, HMLifecycleInstance, HMPageInstance } from '../store/ComponentInstance';
import { HMRouterPathCallback } from './HMRouterPathCallback';
import { HMRouterPathInfo } from './HMRouterPathInfo';
import { IHMAnimator } from './IHMAnimator';
import { HMRouterConfig } from './HMRouterConfig';
import { HMPageLifecycle } from '../lifecycle/HMPageLifecycle';
import { IHMLifecycleOwner } from '../lifecycle/interface/IHMLifecycleOwner';
import { HMServiceResp } from './IHMService';
import { HMPageParam, HMParamType } from './HMParamType';
import { IHMRouterBuilder } from './IHMRouterBuilder';
import { RouterItem } from '../store/entity/BundleInfo';
import { HMUriInterceptor } from '../interceptor/HMUriInterceptor';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { RemoveCallback, RemoveListenerOptions } from '../removeservice/RemoveManager';
export declare class HMRouterMgr {
    static isInit: boolean;
    private static service;
    private static routerStore;
    private static pageLifecycleMgr;
    private static config;
    static sdkApiVersion: number;
    /**
     * Initialize HMRouter
     * @Param config
     */
    static init(config: HMRouterConfig): Promise<collections.Array<RouterItem>>;
    /**
     * Enable HMRouter logs
     * @param level
     */
    static openLog(level: 'DEBUG' | 'INFO'): void;
    /**
     * Push to target page
     * @param pathInfo
     * @param callback
     */
    static push(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): void;
    /**
     * Replace current page to target page
     * @param pathInfo
     * @param callback
     */
    static replace(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): void;
    /**
     * Back to target page
     * @param pathInfo
     * @param skipedLayerNumber
     * The number of levels returned by the page, default to 0, indicates returning to the previous level,
     * 1 indicates skipping one level of page return, two pages are pushed out at the same time,
     * and the pathInfo.pathInfo parameter has higher priority than skipedLayerNumber
     */
    static pop(pathInfo?: HMRouterPathInfo, skipedLayerNumber?: number): void;
    /**
     * Push to target page with async interceptor support
     * @param pathInfo
     * @param callback
     */
    static pushAsync(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): Promise<void>;
    /**
     * Replace current page to target page with async interceptor support
     * @param pathInfo
     * @param callback
     */
    static replaceAsync(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): Promise<void>;
    /**
     * Back to target page with async interceptor support
     * @param pathInfo
     * @param skipedLayerNumber
     * The number of levels returned by the page, default to 0, indicates returning to the previous level,
     * 1 indicates skipping one level of page return, two pages are pushed out at the same time,
     * and the pathInfo.pathInfo parameter has higher priority than skipedLayerNumber
     */
    static popAsync(pathInfo?: HMRouterPathInfo, skipedLayerNumber?: number): Promise<void>;
    /**
     * Get pathStack by navigationId
     * @param navigationId
     * @returns
     */
    static getPathStack(navigationId: string): NavPathStack | null;
    /**
     * Get current page params
     * @returns
     */
    static getCurrentParam(type?: HMParamType): HMPageParam | Map<string, Object> | Object | RegExpExecArray | null;
    /**
     * Get page parameters for specific component instance
     * @param component Component instance
     * @param type Parameter type
     * @returns
     */
    static getCurrentParam(component?: CustomComponent, type?: HMParamType): HMPageParam | Map<string, Object> | Object | RegExpExecArray | null;
    /**
     * Get the current page lifecycle management instance
     *
     * which can be used to retrieve the data content initialized during lifecycle stages
     * @returns
     */
    static getCurrentLifecycleOwner(): IHMLifecycleOwner | null;
    /**
     * Register global interceptor
     * @param interceptorInstance
     * @returns
     */
    static registerGlobalInterceptor(interceptorInstance: HMInterceptorInstance): void;
    /**
     * Unregister global interceptor
     * @param interceptorName
     * @returns
     */
    static unRegisterGlobalInterceptor(interceptorName: string): boolean;
    /**
     * Register global lifecycle
     * @param lifecycleInstance
     * @returns
     */
    static registerGlobalLifecycle(lifecycleInstance: HMLifecycleInstance): void;
    /**
     * Unregister global lifecycle
     * @param lifecycleName
     * @returns
     */
    static unRegisterGlobalLifecycle(lifecycleName: string): boolean;
    /**
     * Register global animator
     * @param key
     * @param animator
     */
    static registerGlobalAnimator(navigationId: string, key: 'standard' | 'dialog', animator: IHMAnimator): void;
    /**
     * Unregister global animator
     * @param key
     * @returns
     */
    static unRegisterGlobalAnimator(navigationId: string, key: 'standard' | 'dialog'): boolean;
    /**
     * Register custom dynamic router
     * @param pageInstance
     */
    static registerPageBuilder(pageInstance: HMPageInstance): boolean;
    /**
     * Generate page lifecycle management instance
     * @returns Unique identifier for page lifecycle instance
     */
    static generatePageLifecycleId(): string;
    /**
     * get page lifecycle by id
     * @param pageLifecycleId
     * @returns page lifecycle instance
     */
    static getPageLifecycleById(pageLifecycleId: string): HMPageLifecycle | undefined;
    /**
     * Execute service
     * @param serviceName
     * @param args
     * @returns service response
     */
    static request(serviceName: string, ...args: Object[]): HMServiceResp;
    /**
     * get service
     * @param serviceName
     * @returns serviceInstance
     */
    static getService<T>(serviceName: string, ...args: Object[]): T | undefined;
    /**
     * getPageBuilderByUrl
     * @param url
     * @returns WrappedBuilder
     */
    static getPageBuilderByUrl(url: string): WrappedBuilder<Object[]> | undefined;
    /**
     * to
     * @param url
     * @returns WrappedBuilder
     */
    static to(pageUrl?: string): IHMRouterBuilder;
    /**
     * 设置返回参数
     * @param pageUrl
     * @returns
     */
    static setPopParam(param: Object): void;
    /**
     * 同步import，napi_load_module_with_info提供的ArkTS层接口
     * @param modulePath eg: "entry/src/main/ets/Test"
     * @param moduleInfo eg: "com.example.application/entry"
     * @returns
     */
    static loadModule(modulePath: string, moduleInfo: string): ESObject;
    /**
     * Get pathStack by navigationId
     * @param navigationId
     * @returns
     */
    static getCurrentPathStack(): NavPathStack | null;
    static removeAll(animated?: boolean): void;
    /**
     * 判断url类型
     * @param pageUrl
     */
    static existUrl(url: string): boolean;
    static isService(url: string): boolean;
    static requestWithCallback(serviceName: string, callback: Callback<HMServiceResp, void>, ...args: Object[]): void;
    /**
     * 返回并跳过所有弹窗页面
     * @param pathInfo
     * @returns
     */
    static popSkipDialog(pathInfo?: HMRouterPathInfo): void;
    /**
     * 处理外部传入URI
     * @param want Want对象，包含URI信息
     * @param interceptor URI拦截器实例
     * @returns 是否成功处理
     */
    static handleUri(want: Want, interceptor: HMUriInterceptor, launchParam?: AbilityConstant.LaunchParam): boolean;
    /**
     * removeBy方法的操作监听
     * @param callback callback监听器回调，返回删除页面信息
     * @param options options设置监听导航容器ID
     * @returns 是否成功处理
     */
    static addRemoveListener(callback: RemoveCallback, options?: RemoveListenerOptions): void;
    static deleteRemoveListener(callback: RemoveCallback): void;
    static clearRemoveListener(): void;
    /**
     * 设置默认navigationId
     * @param navigationId
     */
    static setDefaultNavigationId(navigationId: string): void;
    static clearDefaultNavigationId(): void;
}
