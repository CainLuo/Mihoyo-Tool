import { HMInterceptorInfo } from './HMInterceptorInfo';
export declare class HMInterceptorMgr {
    private static instance;
    static getInstance(): HMInterceptorMgr;
    /**
     * Execute interceptor synchronously
     * @param {HMInterceptorInfo} info - interceptor info
     * @return {boolean}
     * If the interceptor returns DO-REJECT and no longer executes subsequent interceptors and intercepts
     * jumps, it is true.
     * If it returns DO-NEXT or DO_TRANSITION and no longer executes subsequent interceptors and does not intercept
     * jumps, it is false
     */
    executeInterceptor(info: HMInterceptorInfo): boolean;
    /**
     * Execute interceptor asynchronously
     * @param {HMInterceptorInfo} info - interceptor info
     * @return {Promise<boolean>}
     * If the interceptor returns DO-REJECT and no longer executes subsequent interceptors and intercepts
     * jumps, it is true.
     * If it returns DO-NEXT or DO_TRANSITION and no longer executes subsequent interceptors and does not intercept
     * jumps, it is false
     */
    executeAsyncInterceptor(info: HMInterceptorInfo): Promise<boolean>;
    private initInterceptor;
    private getInterceptorResult;
    private runInterceptor;
    private initAsyncInterceptor;
    private getAsyncInterceptorResult;
    private runAsyncInterceptor;
}
