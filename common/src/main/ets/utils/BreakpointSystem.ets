/**
 * 断点系统 - 实现响应式布局
 * 支持多设备适配：xs(穿戴)、sm(手机)、md(平板)、lg(大屏)
 */
import { window } from '@kit.ArkUI';

// 断点类型
export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg';

// 断点配置接口
interface Breakpoint {
  name: BreakpointType;
  size: number;
}

// 全局断点状态管理（V2）
@ObservedV2
class BreakpointState {
  @Trace currentBreakpoint: BreakpointType = 'sm';
}

// 创建全局单例
const breakpointState = new BreakpointState();
export { breakpointState };

/**
 * 断点系统类
 * 用于监听窗口尺寸变化并计算当前断点
 */
export class BreakpointSystem {
  private windowClass: window.Window | null = null;
  private uiContext: UIContext | null = null;
  private state: BreakpointState = breakpointState;
  
  // 断点配置
  private breakpoints: Breakpoint[] = [
    { name: 'xs', size: 0 },    // 超小屏（0-320vp）- 智能穿戴
    { name: 'sm', size: 320 },  // 小屏（320-600vp）- 手机竖屏
    { name: 'md', size: 600 },  // 中屏（600-840vp）- 平板竖屏/折叠屏
    { name: 'lg', size: 840 }   // 大屏（840vp+）- 平板横屏/PC
  ];
  
  private windowSizeChangeCallback: ((size: window.Size) => void) | null = null;

  /**
   * 根据窗口宽度计算断点
   */
  private calculateBreakpoint(width: number): BreakpointType {
    for (let i = this.breakpoints.length - 1; i >= 0; i--) {
      if (width >= this.breakpoints[i].size) {
        return this.breakpoints[i].name;
      }
    }
    return 'xs';
  }

  /**
   * 更新当前断点
   */
  private updateCurrentBreakpoint(breakpoint: BreakpointType): void {
    if (this.state.currentBreakpoint !== breakpoint) {
      this.state.currentBreakpoint = breakpoint;
      // 同步到AppStorage（兼容旧版订阅）
      AppStorage.setOrCreate<BreakpointType>('currentBreakpoint', breakpoint);
    }
  }

  /**
   * 注册断点监听
   */
  public register(windowClass: window.Window): void {
    try {
      this.windowClass = windowClass;
      this.uiContext = windowClass.getUIContext();
      
      // 获取初始窗口尺寸并计算断点
      const windowProperties = windowClass.getWindowProperties();
      const initialWidth: number = this.uiContext.px2vp(windowProperties.windowRect.width);
      const initialBreakpoint = this.calculateBreakpoint(initialWidth);
      this.updateCurrentBreakpoint(initialBreakpoint);
      
      // 监听窗口尺寸变化
      this.windowSizeChangeCallback = (size: window.Size) => {
        if (this.uiContext) {
          const newWidth: number = this.uiContext.px2vp(size.width);
          const newBreakpoint = this.calculateBreakpoint(newWidth);
          this.updateCurrentBreakpoint(newBreakpoint);
        }
      };
      
      windowClass.on('windowSizeChange', this.windowSizeChangeCallback);
      console.info('[BreakpointSystem] Window size change listener registered');
    } catch (err) {
      console.error(`[BreakpointSystem] Failed to register: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 注销断点监听
   */
  public unregister(): void {
    if (this.windowClass && this.windowSizeChangeCallback) {
      this.windowClass.off('windowSizeChange', this.windowSizeChangeCallback);
      this.windowSizeChangeCallback = null;
      console.info('[BreakpointSystem] Window size change listener unregistered');
    }
  }

  /**
   * 获取当前断点
   */
  public getCurrentBreakpoint(): BreakpointType {
    return this.state.currentBreakpoint;
  }
}

/**
 * 断点值映射工具
 * 根据当前断点返回对应的值
 */

// 断点选项接口
interface BreakpointOptions<T> {
  xs?: T;
  sm?: T;
  md?: T;
  lg?: T;
}

export class BreakpointValue<T> {
  private options: Record<BreakpointType, T | undefined>;

  constructor(options: BreakpointOptions<T>) {
    // 创建一个Map来初始化options
    const optionsMap: Map<BreakpointType, T | undefined> = new Map();
    optionsMap.set('xs', options.xs);
    optionsMap.set('sm', options.sm);
    optionsMap.set('md', options.md);
    optionsMap.set('lg', options.lg);
    
    // 转换为Record
    this.options = {
      'xs': optionsMap.get('xs'),
      'sm': optionsMap.get('sm'),
      'md': optionsMap.get('md'),
      'lg': optionsMap.get('lg')
    } as Record<BreakpointType, T | undefined>;
  }

  getValue(breakpoint: BreakpointType): T | undefined {
    return this.options[breakpoint];
  }
}
