import { collections } from '@kit.ArkTS';
import { IHMInterceptor } from '../api/IHMInterceptor';
import { IHMLifecycle } from '../api/IHMLifecycle';
export interface HMLifecycleInstance {
    lifecycle: IHMLifecycle;
    lifecycleName: string;
    priority: number;
}
export interface HMInterceptorInstance {
    interceptor: IHMInterceptor;
    interceptorName: string;
    priority: number;
}
export interface HMServiceInstance {
    serviceName: string;
    functionName: string;
    singleton?: boolean;
    serviceClass: ESObject;
    instance?: ESObject;
}
export interface HMPageInstance {
    builder?: WrappedBuilder<ESObject[]>;
    pageUrl: string;
    interceptorArray?: collections.Array<string>;
    singleton?: boolean;
}
