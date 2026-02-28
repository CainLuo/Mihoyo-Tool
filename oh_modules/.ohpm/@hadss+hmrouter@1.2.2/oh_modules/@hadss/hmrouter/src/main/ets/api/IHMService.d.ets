export declare class HMServiceResp {
    code: number;
    msg?: string;
    data?: ESObject;
    detail?: Error;
    constructor(code: number, msg: string);
}
export declare const SERVICE_NOT_EXIST: HMServiceResp;
export declare const SERVICE_EXECUTE_FAILED: HMServiceResp;
export declare const SERVICE_EXECUTE_SUCCESS: HMServiceResp;
