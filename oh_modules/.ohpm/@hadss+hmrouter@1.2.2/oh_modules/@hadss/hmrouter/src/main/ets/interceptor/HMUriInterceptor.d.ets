import { IHMInterceptor, IHMInterceptorChain } from '../api/IHMInterceptor';
import { HMRouterPathInfo } from '../api/HMRouterPathInfo';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { HMInterceptorInfo } from '../router/HMInterceptorInfo';
/**
 * URI拦截器抽象基类
 *
 * 继承此类的拦截器将自动具备URI处理能力
 * 子类只需要实现parseUri方法来定义URI解析逻辑
 */
export declare abstract class HMUriInterceptor implements IHMInterceptor {
    /**
     * 抽象方法：子类必须实现URI解析逻辑
     * @param want Want对象，包含URI信息
     * @param launchParam 启动参数，可选
     * @returns 解析后的路由信息，返回null表示无法处理该URI
     */
    abstract parseUri(info: HMInterceptorInfo, want: Want, launchParam?: AbilityConstant.LaunchParam): Promise<HMRouterPathInfo | null>;
    intercept(chain: IHMInterceptorChain): Promise<void>;
}
