/**
 * SegmentedTabModels.ets — SegmentedTabBar 的数据模型
 *
 * 放在 models/ 中，供 ViewModel 构建 Tab 列表时引用，避免 ViewModel 反向依赖组件文件。
 * components/common/SegmentedTabBar.ets 会重新导出 SegmentedTabItem，原有导入路径保持可用。
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
