import { IHMInterceptor } from '../../api/IHMInterceptor';
import { HMComponent } from './HMComponent';
/**
 * HMInterceptorData
 */
@Sendable
export declare class HMInterceptorData extends HMComponent {
    /**
     * InterceptorName:非空，唯一
     */
    interceptorName: string;
    /**
     * 优先级，名，默认9，值越大优先级越高
     */
    priority: number;
    /**
     * 是否全局，默认false
     */
    global?: boolean;
    constructor();
}
/**
 * HMInterceptorStoreData
 */
export declare class HMInterceptorStoreData {
    interceptor?: IHMInterceptor;
    hmInterceptorData: HMInterceptorData;
}
