import { collections, HashMap, TreeSet } from '@kit.ArkTS';
import { IHMAnimator } from '../api/IHMAnimator';
import { HMRouterConfig } from '../api/HMRouterConfig';
import { HMInterceptorStoreData } from './entity/HMInterceptor';
import { HMLifecycleStoreData } from './entity/HMLifecycle';
import { HMAnimatorStoreData } from './entity/HMAnimator';
import { HMServiceData } from './entity/HMService';
import { HMInterceptorInstance, HMLifecycleInstance, HMPageInstance } from './ComponentInstance';
import { IHMRouterStore } from './IHMRouterStore';
import { HMRouterStoreData } from './entity/HMRouter';
import { RouterItem } from './entity/BundleInfo';
export declare class HMRouterStoreImpl implements IHMRouterStore {
    private static instance;
    /**
     * Store route table configuration information
     */
    private routerMap;
    /**
     * Regular expression path storage object
     */
    private regexRouterList;
    /**
     * Store the mapping between real paths and the route table to improve lookup performance
     */
    private tempPathMapRoute;
    /**
     * Global interceptor, triggered once for each page navigation (including Dialog type NavDestination). This list
     * is sorted; any new additions require re-sorting.
     */
    private globalInterceptors;
    /**
     * key:interceptor，globally unique; value:HMInterceptorInstance
     */
    private interceptorMap;
    /**
     * Global lifecycle, triggered once for each page navigation (including Dialog type NavDestination). This list
     * is sorted; any new additions require re-sorting.
     */
    private globalLifecycles;
    /**
     * key:lifecycle name，globally unique，value:HMLifecycleInstance
     */
    private lifecycleMap;
    /**
     * key:animator name，globally unique; value:HMAnimatorInstance
     */
    private animatorMap;
    private serviceMap;
    private constructor();
    getGlobalInterceptors(): HMInterceptorInstance[];
    getInterceptorMap(): HashMap<string, HMInterceptorStoreData>;
    getGlobalLifecycles(): HMLifecycleInstance[];
    getLifecycleMap(): HashMap<string, HMLifecycleStoreData>;
    getRouterMap(): HashMap<string, HMRouterStoreData>;
    getRegexRouterList(): TreeSet<HMRouterStoreData>;
    getAnimatorMap(): HashMap<string, HMAnimatorStoreData>;
    getServiceMap(): HashMap<string, HMServiceData>;
    static getInstance(): IHMRouterStore;
    init(config: HMRouterConfig): Promise<collections.Array<RouterItem>>;
    getRouterDataByPageUrl(pageUrl: string): HMRouterStoreData | null;
    getBuilderByPageUrl(pageUrl: string): WrappedBuilder<ESObject> | undefined;
    getBuilderOnlyDynamicPageUrl(pageUrl: string): WrappedBuilder<ESObject> | undefined;
    getInterceptorByPageUrl(pageUrl: string): Array<HMInterceptorInstance>;
    getLifecycleByPageUrl(pageUrl: string): HMLifecycleInstance | null;
    getAnimatorByPageUrl(pageUrl: string): IHMAnimator | null;
    getAnimatorByName(name: string): IHMAnimator | null;
    registerAnimator(name: string, hmAnimator: IHMAnimator): boolean;
    unRegisterAnimator(name: string): boolean;
    registerHMPageInstance(hmPageInstance: HMPageInstance): boolean;
    registerGlobalInterceptor(interceptor: HMInterceptorInstance): void;
    unRegisterGlobalInterceptor(interceptorName: string): boolean;
    registerGlobalLifecycle(lifecycle: HMLifecycleInstance): void;
    unRegisterGlobalLifecycle(lifecycleName: string): boolean;
    isServiceConfig(url: string): boolean;
    private existGlobalInterceptor;
    private existGlobalLifecycle;
    private initModuleInfo;
    private initStoreInfo;
}
