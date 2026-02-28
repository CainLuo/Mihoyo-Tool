import { HMRouterUtils } from '../utils/HMRouterUtils';
import { HMRouterPathCallback } from '../api/HMRouterPathCallback';
import { HMRouterPathInfo } from '../api/HMRouterPathInfo';
export declare class HMNavPathStack extends NavPathStack {
    private _uiContext;
    private _navigationId;
    private component;
    private _isValidNavDst?;
    private popParamMap;
    private interceptorMgr;
    private animatorMgr;
    private navbarLifecycleMgr;
    private navDestinationLifecycleMgr;
    constructor(navigationId: string, component: CustomComponent);
    get navigationId(): string;
    get uiContext(): UIContext;
    set isValidNavDst(value: ((name: string, params: Object) => boolean) | undefined);
    destroy(): void;
    /**
     * 执行同步拦截器
     * @param srcPageInfo 源页面信息
     * @param params 路由操作参数
     * @param trace 跟踪对象
     * @returns 拦截器执行结果
     */
    private _executeInterceptor;
    /**
     * 执行异步拦截器
     * @param srcPageInfo 源页面信息
     * @param params 路由操作参数
     * @param trace 跟踪对象
     * @returns 拦截器执行结果的Promise
     */
    private _executeAsyncInterceptor;
    /**
     * 执行路由操作的共同逻辑 (push/replace)
     * @param params 路由操作参数
     * @param trace 跟踪对象
     * @param interceptorResult 拦截器执行结果
     */
    private _executeRouterAction;
    /**
     * 执行路由操作的共同逻辑 (pop)
     * @param params 路由操作参数
     * @param trace 跟踪对象
     * @param interceptorResult 拦截器执行结果
     */
    private _executePopAction;
    /**
     * Custom push method
     * @param pathInfo Route jump parameters
     * @param callback Route jump callback
     * @param mode Route jump mode
     */
    hmPush(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback, mode?: LaunchMode): void;
    /**
     * Custom push method with async interceptor support
     * @param pathInfo Route jump parameters
     * @param callback Route jump callback
     * @param mode Route jump mode
     */
    hmPushAsync(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback, mode?: LaunchMode): Promise<void>;
    /**
     * Custom replace method
     * @param pathInfo Route jump parameters
     * @param callback Route jump callback
     * @param mode Route jump mode
     */
    hmReplace(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback, mode?: LaunchMode): void;
    /**
     * Custom replace method with async interceptor support
     * @param pathInfo Route jump parameters
     * @param callback Route jump callback
     * @param mode Route jump mode
     */
    hmReplaceAsync(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback, mode?: LaunchMode): Promise<void>;
    hmPop(pathInfo: HMRouterPathInfo, targetPageInfo?: HMRouterUtils.PageInfo): void;
    /**
     * Custom pop method with async interceptor support
     * @param pathInfo Route jump parameters
     * @param targetPageInfo Target page info
     */
    hmPopAsync(pathInfo: HMRouterPathInfo, targetPageInfo?: HMRouterUtils.PageInfo): Promise<void>;
    setPopParam(param: Object): void;
    pushPath(info: NavPathInfo, animated?: boolean | undefined): void;
    pushPath(info: NavPathInfo, options?: NavigationOptions | undefined): void;
    pushPathByName(name: string, param: Object, animated?: boolean | undefined): void;
    pushPathByName(name: string, param: Object, onPop: Callback<PopInfo>, animated?: boolean | undefined): void;
    pushDestination(info: NavPathInfo, animated?: boolean | undefined): Promise<void>;
    pushDestination(info: NavPathInfo, options?: NavigationOptions | undefined): Promise<void>;
    pushDestinationByName(name: string, param: Object, animated?: boolean | undefined): Promise<void>;
    pushDestinationByName(name: string, param: Object, onPop: Callback<PopInfo>, animated?: boolean | undefined): Promise<void>;
    replacePath(info: NavPathInfo, animated?: boolean | undefined): void;
    replacePath(info: NavPathInfo, options?: NavigationOptions | undefined): void;
    replacePathByName(name: string, param: Object, animated?: boolean | undefined): void;
    removeByIndexes(indexes: number[]): number;
    removeByName(name: string): number;
    removeByNavDestinationId(navDestinationId: string): boolean;
    pop(animated?: boolean | undefined): NavPathInfo | undefined;
    pop(result: Object, animated?: boolean | undefined): NavPathInfo | undefined;
    popToName(name: string, animated?: boolean | undefined): number;
    popToName(name: string, result: Object, animated?: boolean | undefined): number;
    popToIndex(index: number, animated?: boolean | undefined): void;
    popToIndex(index: number, result: Object, animated?: boolean | undefined): void;
}
