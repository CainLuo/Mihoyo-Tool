export declare enum HMParamType {
    all = 0,
    urlParam = 1,
    routeParam = 2,
    regexParam = 3
}
export interface HMPageParam {
    data: Object | null;
    urlParam: Map<string, Object> | null;
    regexParam: RegExpExecArray | null;
}
