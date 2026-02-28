import { collections, lang } from '@kit.ArkTS';
import { HMComponent } from './HMComponent';
@Sendable
export declare class HspModuleInfo {
    /**
     * Module name from module.json5
     */
    moduleName: string;
    /**
     * Package name from oh-package.json5
     */
    packageName: string;
}
@Sendable
export declare class BundleInfo {
    routerMap: collections.Array<RouterItem>;
    /**
     * @deprecated Use hspModulesInfo instead
     */
    hspModuleNames: collections.Set<string>;
    /**
     * HSP modules information with both module name and package name
     */
    hspModulesInfo: collections.Array<HspModuleInfo>;
}
/**
 * RouterItem
 */
@Sendable
export declare class RouterItem {
    /**
     * name
     */
    name: string;
    /**
     * pageSourceFile
     */
    pageSourceFile: string;
    /**
     * buildFunction
     */
    buildFunction: string;
    /**
     * customData
     */
    customData?: lang.ISendable;
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
}
/**
 * HMStoreTempInfo
 */
export interface HMStoreTempInfo {
    hmComponentInfos: collections.Array<HMComponent>;
    installTime: number;
    updateTime: number;
}
