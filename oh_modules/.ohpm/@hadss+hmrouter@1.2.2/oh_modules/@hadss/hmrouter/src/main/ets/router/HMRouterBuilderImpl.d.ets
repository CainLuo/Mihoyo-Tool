import { HMPopInfo } from '../api/HMRouterPathCallback';
import { IHMAnimator } from '../api/IHMAnimator';
import { IHMInterceptor } from '../api/IHMInterceptor';
import { IHMLifecycle } from '../api/IHMLifecycle';
import { IHMRouterBuilder } from '../api/IHMRouterBuilder';
export declare class HMRouterBuilderImpl implements IHMRouterBuilder {
    private pathInfo;
    private callback;
    constructor(pageUrl?: string);
    withNavigation(navigationId: string): IHMRouterBuilder;
    withParam(param: ESObject): IHMRouterBuilder;
    addInterceptors(interceptors: IHMInterceptor[]): IHMRouterBuilder;
    skipAllInterceptors(): IHMRouterBuilder;
    withLifecycle(lifecycle: IHMLifecycle): IHMRouterBuilder;
    withAnimator(animator: boolean | IHMAnimator): IHMRouterBuilder;
    onArrival(callback: Callback<void>): IHMRouterBuilder;
    onResult(callback: Callback<HMPopInfo>): IHMRouterBuilder;
    onLost(callback: Callback<void>): IHMRouterBuilder;
    pop(skipedLayerNumber?: number): void;
    push(): void;
    replace(): void;
    pushAsync(): Promise<void>;
    replaceAsync(): Promise<void>;
    popAsync(skipedLayerNumber?: number): Promise<void>;
}
