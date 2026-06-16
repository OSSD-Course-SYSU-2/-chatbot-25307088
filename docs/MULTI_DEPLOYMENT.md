# HarmonyOS 多段部署配置指南

## 📋 概述

本项目已配置支持 HarmonyOS 的"一次开发，多端部署"（简称"一多"）能力，支持以下设备类型：
- **phone** - 手机设备
- **tablet** - 平板设备  
- **2in1** - 二合一设备（PC/平板混合）

## 🏗️ 三层架构

```
MyApplication2/
├── common/                 # 公共能力层（HSP共享包）
│   ├── src/main/ets/
│   │   ├── utils/         # 工具类（断点系统等）
│   │   ├── components/    # 公共组件（响应式布局）
│   │   └── index.ets      # 导出入口
│   └── module.json5       # 模块配置
├── entry/                  # 产品定制层（Entry HAP）
│   └── src/main/
│       ├── ets/           # 业务代码
│       └── module.json5   # 支持多设备类型
└── build-profile.json5    # 多目标产物配置
```

## 🎯 使用方法

### 1. 导入公共模块

```typescript
import { 
  BreakpointSystem, 
  BreakpointValue, 
  ResponsiveContainer,
  ResponsiveGrid,
  ResponsiveText 
} from 'common';
```

### 2. 使用断点系统

```typescript
@Component
struct MyPage {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  
  build() {
    Column() {
      // 根据断点调整字体大小
      Text('Hello')
        .fontSize(new BreakpointValue({
          xs: 12,  // 穿戴设备
          sm: 14,  // 手机
          md: 16,  // 平板
          lg: 18   // 大屏
        }).getValue(this.currentBreakpoint) || 14)
    }
  }
}
```

### 3. 响应式布局示例

```typescript
@Component
struct MyPage {
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  
  build() {
    // 响应式网格 - 自动调整列数
    ResponsiveGrid({ currentBreakpoint: this.currentBreakpoint }) {
      ForEach([1, 2, 3, 4], (item: number) => {
        GridItem() {
          Text(`Item ${item}`)
        }
      })
    }
  }
}
```

## 📱 断点范围

| 断点 | 范围 (vp) | 典型设备 |
|------|-----------|----------|
| xs | 0 - 320 | 智能穿戴 |
| sm | 320 - 600 | 手机竖屏 |
| md | 600 - 840 | 平板竖屏/折叠屏 |
| lg | 840+ | 平板横屏/PC |

## 🔧 构建配置

### 多目标产物

在 `build-profile.json5` 中配置了两个产品：
- **default** - 默认构建目标
- **tablet** - 平板专用构建目标

### 切换构建目标

在 DevEco Studio 中：
1. 点击工具栏的 Product 选择器
2. 选择 `default` 或 `tablet`
3. 点击 Apply 应用配置

## 📦 模块依赖

在 `oh-package.json5` 中已添加 common 模块依赖：
```json
{
  "dependencies": {
    "common": "file:./common"
  }
}
```

## 🎨 最佳实践

### 1. 使用断点值映射
```typescript
// 间距
new BreakpointValue({ xs: 8, sm: 12, md: 16, lg: 20 })

// 内边距
new BreakpointValue({ xs: 12, sm: 16, md: 24, lg: 32 })

// 字体大小
new BreakpointValue({ xs: 12, sm: 14, md: 16, lg: 18 })
```

### 2. 条件布局
```typescript
if (this.currentBreakpoint === 'sm') {
  // 手机布局
  Column() { /* ... */ }
} else {
  // 平板/大屏布局
  Row() { /* ... */ }
}
```

### 3. 栅格布局
```typescript
Grid() {
  // 内容
}
.columnsTemplate(new BreakpointValue({
  xs: '1fr',           // 单列
  sm: '1fr 1fr',       // 双列
  md: '1fr 1fr 1fr',   // 三列
  lg: '1fr 1fr 1fr 1fr' // 四列
}).getValue(this.currentBreakpoint) || '1fr 1fr')
```

## 🚀 下一步

1. 在页面中使用 `@StorageProp('currentBreakpoint')` 获取当前断点
2. 使用 `BreakpointValue` 工具类实现响应式样式
3. 使用 `ResponsiveContainer`、`ResponsiveGrid` 等组件快速实现响应式布局
4. 根据需要在 `common` 模块中添加更多公共组件和工具类
