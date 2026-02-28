import { IHMInterceptor, IHMInterceptorChain } from '../api/IHMInterceptor';
import { HMInterceptorAction } from './HMInterceptorAction';
import { HMInterceptorInfo, InterceptorContext } from './HMInterceptorInfo';
/**
 * Implementation of IHMInterceptorChain
 */
export declare class HMInterceptorChainImpl implements IHMInterceptorChain {
    private interceptors;
    private index;
    private info;
    private onCompleteCallback;
    private isCompleted;
    /**
     * Constructor
     * @param interceptors Array of interceptors
     * @param info Interceptor info
     * @param onCompleteCallback Callback when chain completes
     */
    constructor(interceptors: Array<IHMInterceptor>, info: HMInterceptorInfo, onCompleteCallback: (action: HMInterceptorAction) => void);
    /**
     * Continue to next interceptor
     */
    onContinue(): Promise<void>;
    /**
     * Intercept the chain and stop routing
     */
    onIntercept(): Promise<void>;
    /**
     * Skip remaining interceptors and proceed with routing
     */
    onTransition(): Promise<void>;
    /**
     * Get router info
     */
    getRouterInfo(): HMInterceptorInfo;
    /**
     * Get interceptor context
     */
    getContext(): InterceptorContext | undefined;
    /**
     * Start the interceptor chain
     */
    start(): Promise<HMInterceptorAction>;
    /**
     * Check if chain is completed and log error if true
     * @returns true if chain is completed
     */
    private checkCompleted;
    /**
     * Mark the chain as completed
     * @param action The final action
     */
    private complete;
    /**
     * Proceed to the next interceptor
     */
    private proceed;
}
