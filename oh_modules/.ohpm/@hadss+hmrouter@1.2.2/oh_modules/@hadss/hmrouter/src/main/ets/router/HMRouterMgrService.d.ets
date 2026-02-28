import { HMNavPathStack } from './HMNavPathStack';
import { HMRouterPathInfo } from '../api/HMRouterPathInfo';
import { HMRouterPathCallback } from '../api/HMRouterPathCallback';
import { IHMLifecycleOwner } from '../lifecycle/interface/IHMLifecycleOwner';
import { HMPageParam, HMParamType } from '../api/HMParamType';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { HMUriInterceptor } from '../interceptor/HMUriInterceptor';
export interface PendingUriData {
    want: Want;
    launchParam?: AbilityConstant.LaunchParam;
}
export declare class HMRouterMgrService {
    private static instance;
    private navPathStackMap;
    private lastNavigationId;
    private navbarLifecycleMgr;
    private navDestinationLifecycleMgr;
    private pendingUriData;
    private onNavigationReady?;
    private defaultNavigationId;
    private constructor();
    /**
     * Get HMRouterMgrService instance
     * @returns
     */
    static getInstance(): HMRouterMgrService;
    /**
     * Retrieve routing information, and when no navigationId is passed in, use the most recent navigationId passed in
     * @param navigationId
     * @returns
     */
    getPathStack(navigationId?: string): HMNavPathStack | null;
    /**
     * 设置默认navigationId
     * @param navigationId
     */
    setDefaultNavigationId(navigationId: string): void;
    clearDefaultNavigationId(): void;
    /**
     * Routing operations: push
     * @param pathInfo
     * @param callback
     */
    push(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): void;
    pushAndClear(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): void;
    /**
     * Routing operations: replace
     * @param pathInfo
     * @param callback
     */
    replace(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): void;
    /**
     * Routing operations: Pop
     * @param pathInfo
     * @param skipedLayerNumber
     */
    pop(pathInfo?: HMRouterPathInfo, skipedLayerNumber?: number): void;
    /**
     * Routing operations: pushAsync (with async interceptor support)
     * @param pathInfo
     * @param callback
     */
    pushAsync(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): Promise<void>;
    /**
     * Routing operations: replaceAsync (with async interceptor support)
     * @param pathInfo
     * @param callback
     */
    replaceAsync(pathInfo: HMRouterPathInfo, callback?: HMRouterPathCallback): Promise<void>;
    /**
     * Routing operations: popAsync (with async interceptor support)
     * @param pathInfo
     * @param skipedLayerNumber
     */
    popAsync(pathInfo?: HMRouterPathInfo, skipedLayerNumber?: number): Promise<void>;
    /**
     * Implementation of getCurrentParam
     */
    getCurrentParam(componentOrType?: CustomComponent | HMParamType, maybeType?: HMParamType): HMPageParam | Map<string, Object> | Object | null;
    /**
     * Get the lifecycle instance corresponding to the current page
     * @returns
     */
    getCurrentLifecycleOwner(): IHMLifecycleOwner | null;
    setPopParam(param: Object): void;
    isService(url: string): boolean;
    isPage(url: string): boolean;
    removeAll(animated?: boolean): void;
    popSkipDialog(pathInfo?: HMRouterPathInfo): void;
    handleUri(want: Want, interceptor: HMUriInterceptor, launchParam?: AbilityConstant.LaunchParam): boolean;
    getPendingUriData(): PendingUriData | null;
    clearPendingUriData(): void;
    getNavigationReadyCallback(): (() => void) | undefined;
    clearNavigationReadyCallback(): void;
    /**
     * 获取URL参数
     * @param pageUrl 页面URL
     * @returns URL参数Map
     */
    private getUrlParams;
    /**
     * 根据参数类型格式化返回结果
     * @param type 参数类型
     * @param param 路由参数
     * @param urlParam URL参数
     * @param regexParam 正则参数
     * @returns 格式化后的结果
     */
    private formatReturnResult;
    private getLastNavigationId;
}
