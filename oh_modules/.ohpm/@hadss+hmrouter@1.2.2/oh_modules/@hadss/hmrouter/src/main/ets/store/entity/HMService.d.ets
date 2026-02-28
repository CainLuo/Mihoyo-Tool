import { HMComponent } from './HMComponent';
@Sendable
export declare class HMServiceData extends HMComponent {
    /**
     * 服务名称 serviceName
     */
    serviceName: string;
    /**
     * 函数名称 functionName
     */
    functionName: string;
    /**
     * 是否单例
     */
    singleton?: boolean;
    constructor();
}
