# HarmonyOS AI聊天应用

一个功能完整的HarmonyOS AI聊天应用，支持接入多种大模型API。

## 功能特性

### 🤖 大模型API支持
- ✅ **OpenAI**: GPT-3.5, GPT-4, GPT-4 Turbo
- ✅ **百度文心一言**: ERNIE Bot系列
- ✅ **阿里通义千问**: Qwen系列
- ✅ **其他OpenAI兼容API**

### ⚙️ 配置管理
- ✅ 可视化配置界面
- ✅ 多配置管理
- ✅ 连接测试功能
- ✅ 配置验证
- ✅ 默认配置设置

### 🎭 人格模板
- ✅ 预设人格模板
- ✅ 自定义模板
- ✅ 快速切换
- ✅ 模板管理

### 💬 聊天功能
- ✅ 多会话管理
- ✅ 会话历史
- ✅ 消息记录
- ✅ 自动保存

### 🎨 用户界面
- ✅ 现代化UI设计
- ✅ 流畅交互体验
- ✅ 响应式布局
- ✅ 深色模式支持

## 快速开始

### 1. 配置API

1. 打开应用，点击右上角"设置"按钮
2. 在"AI模型配置"区域点击"添加配置"
3. 填写API信息（参考[API配置指南](docs/API配置指南.md)）
4. 点击"测试连接"验证配置
5. 保存配置并设为默认

### 2. 开始聊天

1. 返回主界面
2. 在输入框输入消息
3. 点击发送按钮
4. 等待AI回复

## 项目结构

```
MyApplication2/
├── entry/
│   └── src/main/ets/
│       ├── model/
│       │   └── ChatModel.ets          # 数据模型
│       ├── service/
│       │   ├── AIService.ets          # AI服务
│       │   └── StorageService.ets     # 存储服务
│       └── pages/
│           ├── Index.ets              # 主页面
│           └── SettingsPage.ets       # 设置页面
└── docs/
    └── API配置指南.md                  # 详细配置文档
```

## 核心组件

### AIService
负责与大模型API通信：
- 支持多种API格式
- 自动适配不同响应格式
- 错误处理和重试机制

### StorageService
负责数据持久化：
- 会话历史存储
- 配置信息管理
- 人格模板管理

### SettingsPage
提供完整的配置界面：
- API配置表单
- 连接测试
- 人格模板管理
- 应用设置

## 技术栈

- **HarmonyOS**: 原生应用开发框架
- **ArkTS**: TypeScript扩展语言
- **ArkUI**: 声明式UI框架
- **HTTP**: 网络请求
- **Preferences**: 本地存储

## API配置示例

### OpenAI
```typescript
{
  name: "OpenAI GPT-3.5",
  apiUrl: "https://api.openai.com/v1/chat/completions",
  apiKey: "sk-xxxxxx",
  model: "gpt-3.5-turbo",
  maxTokens: 2000,
  temperature: 0.7
}
```

### 百度文心一言
```typescript
{
  name: "文心一言",
  apiUrl: "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions",
  apiKey: "your-access-token",
  model: "ernie-bot-4",
  maxTokens: 2000,
  temperature: 0.7
}
```

### 阿里通义千问
```typescript
{
  name: "通义千问",
  apiUrl: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation",
  apiKey: "sk-xxxxxx",
  model: "qwen-turbo",
  maxTokens: 2000,
  temperature: 0.7
}
```

## 安全建议

⚠️ **重要提示**:
1. 不要在代码中硬编码API密钥
2. 不要分享你的API密钥
3. 定期更换API密钥
4. 监控API使用量和费用
5. 合理设置最大令牌数

## 常见问题

### Q: 连接失败怎么办？
A: 检查API密钥、地址是否正确，网络是否正常，API余额是否充足。

### Q: 如何切换不同的模型？
A: 在设置页面可以添加多个配置，点击"设为默认"切换。

### Q: 如何自定义AI的回复风格？
A: 使用人格模板功能，创建自定义提示词。

### Q: 数据存储在哪里？
A: 使用HarmonyOS Preferences API进行本地存储。

## 开发说明

### 构建项目
```bash
hvigorw assembleHap
```

### 运行项目
在DevEco Studio中点击运行按钮。

### 修改配置
所有配置在 `entry/src/main/ets/service/StorageService.ets` 中定义。

## 更新日志

### v1.0.0 (2024-04-20)
- ✅ 完整的大模型API接入功能
- ✅ 可视化配置界面
- ✅ 多种API支持
- ✅ 人格模板功能
- ✅ 会话管理
- ✅ 数据持久化

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！

## 联系方式

如有问题，请查看[API配置指南](docs/API配置指南.md)或提交Issue。