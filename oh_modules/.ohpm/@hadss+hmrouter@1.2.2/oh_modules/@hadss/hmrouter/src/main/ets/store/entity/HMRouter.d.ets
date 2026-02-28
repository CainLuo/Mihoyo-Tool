import { collections } from '@kit.ArkTS';
import { HMComponent } from './HMComponent';
@Sendable
export declare class HMRouterData extends HMComponent {
    /**
     * 跳转路径pushName
     */
    pageUrl: string;
    /**
     * pageUrl是否是正则表达式
     */
    isRegex?: boolean;
    /**
     * 优先级
     */
    regexPriority: number;
    /**
     * 是否弹窗类型页面
     */
    dialog?: boolean;
    /**
     * 是否单例页面
     */
    singleton?: boolean;
    /**
     * 动效实例
     */
    animator?: string;
    /**
     * 路由拦截器
     */
    interceptors?: collections.Array<string>;
    /**
     * 生命周期处理
     */
    lifecycle?: string;
    /**
     * 页面定义绑定的function
     */
    bindFunction: string;
    constructor();
    importComponent<T>(): T | undefined;
}
export declare class HMRouterStoreData {
    builder?: WrappedBuilder<Object[]>;
    params?: ESObject;
    registerFlag: boolean;
    regexp?: RegExp;
    hmRouterData: HMRouterData;
}
