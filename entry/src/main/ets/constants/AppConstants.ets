/**
 * AppConstants — 应用级通用常量
 *
 * 存放与业务逻辑无关、跨组件复用的固定值。
 * 包括响应式布局断点、骨架屏占位索引等。
 *
 * 命名规则：
 *   - 布局相关：GRID_xxx / BREAKPOINTS_xxx
 *   - 骨架屏相关：SKELETON_xxx
 *   - 其他通用：按语义命名
 *
 * 注意：
 *   - 游戏业务常量（如树脂上限）请放对应的 XxxConstants.ets，不要放这里。
 *   - GridRow columns 列数配置（{ xs, sm, md, lg }）因 ArkTS 严格模式限制，
 *     无法以 object 类型存为静态常量，应在各组件调用处直接内联。
 */

export class AppConstants {
  /**
   * 响应式网格断点值（基于窗口 vp），配合 GridRow.breakpoints 使用
   *   xs  < 600vp    → 竖屏手机（360-480vp）
   *   sm  600-840vp  → 横屏手机 / 小折叠展开
   *   md  840-1200vp → 大折叠展开 / 平板
   *   lg  > 1200vp   → PC / 2in1
   */
  static readonly GRID_BREAKPOINTS: string[] = ['600vp', '840vp', '1200vp'];

  /**
   * 角色骨架屏占位卡片索引列表
   * 数量与列数匹配，保证骨架屏视觉上填满两行
   */
  static readonly SKELETON_CHARACTER_INDICES: number[] = [0, 1, 2, 3, 4, 5, 6, 7];

  /**
   * 数据同步/自动刷新间隔（毫秒）：30 分钟
   * 适用于所有需要按需同步的场景（首页 daily_note、角色列表等）
   */
  static readonly AUTO_REFRESH_INTERVAL_MS: number = 30 * 60 * 1000;
}
