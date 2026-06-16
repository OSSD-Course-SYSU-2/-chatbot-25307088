/**
 * 响应式布局组件
 * 根据断点自动调整布局
 */
import { BreakpointValue, BreakpointType } from '../utils/BreakpointSystem';

// 断点数值选项接口
interface BreakpointNumberOptions {
  xs?: number;
  sm?: number;
  md?: number;
  lg?: number;
}

// 断点字符串选项接口
interface BreakpointStringOptions {
  xs?: string;
  sm?: string;
  md?: string;
  lg?: string;
}

/**
 * 响应式容器组件
 * 根据断点调整间距、内边距等布局参数
 */
@Component
export struct ResponsiveContainer {
  @Prop currentBreakpoint: BreakpointType = 'sm';
  
  // 子组件内容
  @BuilderParam content: () => void;
  
  build() {
    Column() {
      this.content();
    }
    .width('100%')
    .height('100%')
    .padding({
      left: new BreakpointValue<number>({
        xs: 12,
        sm: 16,
        md: 24,
        lg: 32
      } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 16,
      right: new BreakpointValue<number>({
        xs: 12,
        sm: 16,
        md: 24,
        lg: 32
      } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 16,
      top: new BreakpointValue<number>({
        xs: 8,
        sm: 12,
        md: 16,
        lg: 20
      } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 12,
      bottom: new BreakpointValue<number>({
        xs: 8,
        sm: 12,
        md: 16,
        lg: 20
      } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 12
    })
  }
}

/**
 * 响应式网格组件
 * 根据断点调整列数
 */
@Component
export struct ResponsiveGrid {
  @Prop currentBreakpoint: BreakpointType = 'sm';
  @BuilderParam content: () => void;
  
  build() {
    Grid() {
      this.content();
    }
    .columnsTemplate(new BreakpointValue<string>({
      xs: '1fr',
      sm: '1fr 1fr',
      md: '1fr 1fr 1fr',
      lg: '1fr 1fr 1fr 1fr'
    } as BreakpointStringOptions).getValue(this.currentBreakpoint) || '1fr 1fr')
    .rowsGap(new BreakpointValue<number>({
      xs: 8,
      sm: 12,
      md: 16,
      lg: 20
    } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 12)
    .columnsGap(new BreakpointValue<number>({
      xs: 8,
      sm: 12,
      md: 16,
      lg: 20
    } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 12)
    .width('100%')
  }
}

/**
 * 响应式文本组件
 * 根据断点调整字体大小
 */
@Component
export struct ResponsiveText {
  @Prop currentBreakpoint: BreakpointType = 'sm';
  @Prop text: string = '';
  @Prop fontWeight: FontWeight = FontWeight.Normal;
  
  build() {
    Text(this.text)
      .fontSize(new BreakpointValue<number>({
        xs: 12,
        sm: 14,
        md: 16,
        lg: 18
      } as BreakpointNumberOptions).getValue(this.currentBreakpoint) || 14)
      .fontWeight(this.fontWeight)
  }
}
