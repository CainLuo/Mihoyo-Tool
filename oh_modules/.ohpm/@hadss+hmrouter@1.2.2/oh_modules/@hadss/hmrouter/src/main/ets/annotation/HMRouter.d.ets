/**
 * Router annotation
 *
 * Define the struct as route page
 * @param param
 * @returns
 */
export declare function HMRouter(param: HMRouterParam): ObjectConstructor;
export interface HMRouterParam {
    pageUrl: string;
    isRegex?: boolean;
    regexPriority?: number;
    dialog?: boolean;
    singleton?: boolean;
    interceptors?: string[];
    animator?: string;
    lifecycle?: string;
    useNavDst?: boolean;
}
