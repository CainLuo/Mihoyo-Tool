/**
 * Interceptor annotation
 *
 * Define interceptor of the page
 * @param param
 * @returns
 */
export declare function HMInterceptor(param: HMInterceptorParam): ObjectConstructor;
export interface HMInterceptorParam {
    interceptorName: string;
    priority?: number;
    global?: boolean;
}
