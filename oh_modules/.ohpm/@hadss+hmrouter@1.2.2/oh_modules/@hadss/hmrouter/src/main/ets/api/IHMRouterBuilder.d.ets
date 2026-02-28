import { Callback } from '@kit.BasicServicesKit';
import { IHMAnimator } from './IHMAnimator';
import { IHMInterceptor } from './IHMInterceptor';
import { IHMLifecycle } from './IHMLifecycle';
import { HMPopInfo } from './HMRouterPathCallback';
export interface IHMRouterBuilder {
    /**
     * Set navigationId
     * @param navigationId
     * @returns
     */
    withNavigation(navigationId: string): IHMRouterBuilder;
    /**
     * Setting route parameters
     * @param param
     * @returns
     */
    withParam(param: ESObject): IHMRouterBuilder;
    /**
     * Setting up the interceptor
     * @param interceptors
     * @returns
     */
    addInterceptors(interceptors: IHMInterceptor[]): IHMRouterBuilder;
    /**
     * Set to jump all interceptors
     * @returns
     */
    skipAllInterceptors(): IHMRouterBuilder;
    /**
     * Setting the page lifecycle
     * @param lifecycle
     * @returns
     */
    withLifecycle(lifecycle: IHMLifecycle): IHMRouterBuilder;
    /**
     * Setting up route animation
     * @param animator
     * @returns
     */
    withAnimator(animator: IHMAnimator | boolean): IHMRouterBuilder;
    /**
     * Set the route jump completion callback
     * @param callback
     * @returns
     */
    onArrival(callback: Callback<void>): IHMRouterBuilder;
    /**
     * Set the callback triggered when the route returns
     * @param callback
     * @returns
     */
    onResult(callback: Callback<HMPopInfo>): IHMRouterBuilder;
    /**
     * When setting route jump, route invalid callback
     * @param callback
     * @returns
     */
    onLost(callback: Callback<void>): IHMRouterBuilder;
    /**
     * Execution of routing returns
     * @param skipedLayerNumber
     */
    pop(skipedLayerNumber?: number): void;
    /**
     * Execution of routing jumps
     */
    push(): void;
    /**
     * Execution of routing replace
     */
    replace(): void;
    /**
     * Asynchronous execution of routing jumps
     * @returns
     */
    pushAsync(): Promise<void>;
    /**
     * Asynchronous execution of routing replace
     * @returns
     */
    replaceAsync(): Promise<void>;
    /**
     * Asynchronous execution of routing pop
     * @returns
     */
    popAsync(): Promise<void>;
}
