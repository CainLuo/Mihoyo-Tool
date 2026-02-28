import { HMInterceptorAction } from '../router/HMInterceptorAction';
import { HMInterceptorInfo, InterceptorContext } from '../router/HMInterceptorInfo';
export interface IHMInterceptor {
    handle?(info: HMInterceptorInfo): HMInterceptorAction;
    intercept?(chain: IHMInterceptorChain): Promise<void>;
}
export interface IHMInterceptorChain {
    onContinue(): Promise<void>;
    onIntercept(): Promise<void>;
    onTransition(): Promise<void>;
    getRouterInfo(): HMInterceptorInfo;
    getContext(): InterceptorContext | undefined;
}
