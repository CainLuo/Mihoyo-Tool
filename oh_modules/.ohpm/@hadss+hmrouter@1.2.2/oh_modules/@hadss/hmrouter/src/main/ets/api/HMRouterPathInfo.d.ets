import { IHMAnimator } from './IHMAnimator';
import { IHMInterceptor } from './IHMInterceptor';
import { IHMLifecycle } from './IHMLifecycle';
/**
 * Router push/replace/pop params
 */
export interface HMRouterPathInfo {
    navigationId?: string;
    pageUrl?: string;
    param?: ESObject;
    interceptors?: IHMInterceptor[];
    lifecycle?: IHMLifecycle;
    animator?: IHMAnimator | boolean;
    skipAllInterceptor?: boolean;
}
