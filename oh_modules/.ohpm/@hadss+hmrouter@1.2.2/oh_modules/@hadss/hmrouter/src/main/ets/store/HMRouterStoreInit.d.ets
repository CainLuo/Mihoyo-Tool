import { common } from '@kit.AbilityKit';
import { collections } from '@kit.ArkTS';
import { RouterItem } from './entity/BundleInfo';
import { HMComponent } from './entity/HMComponent';
/**
 * get bundle info from rawfile
 * @returns
 */
export declare function getComponentInfosFromRawfile(context: common.Context, hspModuleNames: collections.Set<string>): Promise<collections.Map<string, collections.Array<HMComponent | RouterItem>>>;
/**
 * get bundle info from bundleManager
 * @param context
 * @param hspModuleNames
 * @returns
 */
export declare function getComponentInfosFromBundleManager(context: common.Context, hspModuleNames: collections.Set<string>): Promise<collections.Map<string, collections.Array<HMComponent | RouterItem>>>;
