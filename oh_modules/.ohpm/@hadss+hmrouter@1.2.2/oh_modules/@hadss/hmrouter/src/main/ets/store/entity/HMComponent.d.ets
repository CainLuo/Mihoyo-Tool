import { RouterItem } from './BundleInfo';
/**
 * HMComponent
 */
@Sendable
export declare class HMComponent {
    /**
     * 名称
     */
    name: string;
    /**
     * 动态import所需要的className
     */
    className: string;
    /**
     * pageSourceFile
     */
    pageSourceFile: string;
    /**
     * moduleName,eg:entry
     */
    moduleName: string;
    /**
     * bundleName,eg:com.example.hmrouter
     */
    bundleName: string;
    /**
     * ohmurl,eg:@normalized:N&&&entry/src/main/ets/animation/CustomPageAnimator&
     */
    ohmurl: string;
    /**
     * importComponent
     * @returns T|undefined
     */
    importComponent<T>(): T | undefined;
    convertItem(item: RouterItem): void;
}
