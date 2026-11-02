/**
 * SegmentedTabItemModel.ets — SegmentedTabBar 的数据模型
 *
 * 放在 model/ 中（与 SegmentedTabBar 组件分离），供 ViewModel 构建 Tab 列表时引用，
 * 避免 ViewModel 反向依赖组件文件。统一从 'basic' 桶文件导入，
 * shares/SegmentedTabBar.ets 不再重新导出本类型。
 */

/** Tab 项数据模型 */
export class SegmentedTabItem {
  /** 唯一标识 */
  key: string = '';
  /** 显示文本 */
  label: ResourceStr = '';

  constructor(key: string, label: ResourceStr) {
    this.key = key;
    this.label = label;
  }
}
