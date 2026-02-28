/**
 * Service annotation
 *
 * Define method as a service
 * @param param
 * @returns
 */
export declare function HMService(param: HMServiceParam): (target: ESObject, propertyKey: string, descriptor: PropertyDescriptor) => void;
export declare function HMServiceProvider(param: HMServiceParam): ObjectConstructor;
export interface HMServiceParam {
    serviceName: string;
    singleton?: boolean;
}
