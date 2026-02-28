import { IHMAnimator } from '../api/IHMAnimator';
import { HMRouterConfig } from '../api/HMRouterConfig';
import { HMInterceptorInstance, HMLifecycleInstance, HMPageInstance } from './ComponentInstance';
import { HMRouterStoreData } from './entity/HMRouter';
import { RouterItem } from './entity/BundleInfo';
import { collections } from '@kit.ArkTS';
/**
 * Router store
 *
 * use for store the instance of the page, service, interceptor, and animator
 */
export interface IHMRouterStore {
    /**
     * Init Router store
     * @returns void
     */
    init(config: HMRouterConfig): Promise<collections.Array<RouterItem>>;
    /**
     * Get global interceptor
     * @returns Array<HMInterceptorInstance>
     */
    getGlobalInterceptors(): Array<HMInterceptorInstance>;
    /**
     * Get global lifecycle array
     * @returns Array<HMLifecycleInstance>
     */
    getGlobalLifecycles(): Array<HMLifecycleInstance>;
    /**
     * Get the corresponding interceptor based on the pageURL
     * @param pageUrl
     * @returns Array<HMInterceptorInstance>
     */
    getInterceptorByPageUrl(pageUrl: string): Array<HMInterceptorInstance>;
    /**
     * Get the lifecycle of the corresponding page by pageUrl
     * @param pageUrl
     * @returns HMLifecycleInstance | null
     */
    getLifecycleByPageUrl(pageUrl: string): HMLifecycleInstance | null;
    /**
     * Get the animator of the corresponding page by pageUrl
     * @param pageUrl
     * @returns IHMAnimator | null
     */
    getAnimatorByPageUrl(pageUrl: string): IHMAnimator | null;
    /**
     * Retrieve the animator based on its name. This API currently only provides
     * registered animators and does not dynamically import them. It returns synchronously
     * @param name
     * @returns IHMAnimator | null
     */
    getAnimatorByName(name: string): IHMAnimator | null;
    /**
     * register animator
     * @param name
     * @param hmAnimator IHMAnimator
     * @returns Registration success or failure
     */
    registerAnimator(name: string, hmAnimator: IHMAnimator): boolean;
    /**
     * delete animator
     * @param name
     * @returns 取消Animator
     */
    unRegisterAnimator(name: string): boolean;
    /**
     * register HMPageInstance
     * @param hmPageInstance HMPageInstance
     * @returns boolean
     */
    registerHMPageInstance(hmPageInstance: HMPageInstance): boolean;
    /**
     * register global animator
     * @param interceptor HMInterceptorInstance
     */
    registerGlobalInterceptor(interceptor: HMInterceptorInstance): void;
    /**
     * Log out the global interceptor with the interceptor
     * name as the parameter, and return whether the logout was successful
     * @param interceptorName
     * @returns
     */
    unRegisterGlobalInterceptor(interceptorName: string): boolean;
    /**
     * register global lifecycle
     * @param lifecycle HMLifecycleInstance
     */
    registerGlobalLifecycle(lifecycle: HMLifecycleInstance): void;
    /**
     * Register the global lifecycle, with the parameter being the global lifecycle name,
     * and return whether the logout was successful
     * @param interceptorName
     * @returns
     */
    unRegisterGlobalLifecycle(lifecycleName: string): boolean;
    /**
     * Get page info
     * @param pageUrl
     * @returns HMPageInstance | null
     */
    getRouterDataByPageUrl(pageUrl: string): HMRouterStoreData | null;
    /**
     * Get page builder by pageUrl
     * @param pageUrl
     * @returns HMPageInstance | null
     */
    getBuilderByPageUrl(pageUrl: string): WrappedBuilder<ESObject[]> | undefined;
    getBuilderOnlyDynamicPageUrl(name: string): WrappedBuilder<ESObject[]> | undefined;
    isServiceConfig(url: string): boolean;
}
