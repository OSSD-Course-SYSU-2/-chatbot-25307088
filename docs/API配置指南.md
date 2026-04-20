# 大模型API配置指南

## 功能概述

本项目已完整实现大模型API接入功能，支持多种主流大模型API，包括：
- OpenAI (GPT-3.5, GPT-4)
- 百度文心一言
- 阿里通义千问
- 其他OpenAI兼容API

## 配置步骤

### 1. 进入设置页面

在应用主界面，点击右上角的"设置"按钮进入设置页面。

### 2. 添加AI模型配置

在"AI模型配置"区域，点击"添加配置"按钮，填写以下信息：

#### 必填字段

- **配置名称**: 为配置起一个易于识别的名称
  - 示例: "OpenAI GPT-3.5", "文心一言", "通义千问"

- **API地址**: 大模型API的请求地址
  - OpenAI: `https://api.openai.com/v1/chat/completions`
  - 文心一言: `https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions`
  - 通义千问: `https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation`

- **API密钥**: 从大模型平台获取的API Key
  - OpenAI: 在 https://platform.openai.com/api-keys 获取
  - 百度: 在 https://console.bce.baidu.com/ai/#/ai/wenxinworkshop/app/list 获取
  - 阿里: 在 https://dashscope.console.aliyun.com/apiKey 获取

- **模型名称**: 要使用的具体模型
  - OpenAI: `gpt-3.5-turbo`, `gpt-4`, `gpt-4-turbo`
  - 文心一言: `ernie-bot-4`, `ernie-bot-turbo`
  - 通义千问: `qwen-turbo`, `qwen-plus`, `qwen-max`

#### 可选字段

- **最大令牌数**: 控制响应的最大长度
  - 推荐值: 2000-4000
  - GPT-4可设置更高: 4000-8000

- **温度参数**: 控制回复的随机性
  - 范围: 0-2
  - 0: 最确定，回复更一致
  - 1: 平衡
  - 2: 最随机，回复更多样

- **系统提示词**: 定义AI的角色和行为
  - 示例: "你是一个乐于助人的AI助手。"
  - 可根据需要自定义

### 3. 测试连接

配置填写完成后，点击"测试连接"按钮验证配置是否正确：
- ✅ 连接成功：API配置有效
- ❌ 连接失败：请检查API地址和密钥

### 4. 保存配置

测试成功后，点击"保存"按钮保存配置。

### 5. 设为默认

在配置列表中，点击"设为默认"按钮将配置设为默认使用的模型。

## 常见API配置示例

### OpenAI GPT-3.5

```
配置名称: OpenAI GPT-3.5
API地址: https://api.openai.com/v1/chat/completions
API密钥: sk-xxxxxxxxxxxxxxxx
模型名称: gpt-3.5-turbo
最大令牌数: 2000
温度参数: 0.7
系统提示词: 你是一个乐于助人的AI助手。
```

### OpenAI GPT-4

```
配置名称: OpenAI GPT-4
API地址: https://api.openai.com/v1/chat/completions
API密钥: sk-xxxxxxxxxxxxxxxx
模型名称: gpt-4
最大令牌数: 4000
温度参数: 0.7
系统提示词: 你是一个乐于助人的AI助手。
```

### 百度文心一言

```
配置名称: 文心一言
API地址: https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions
API密钥: your-access-token
模型名称: ernie-bot-4
最大令牌数: 2000
温度参数: 0.7
系统提示词: 你是一个乐于助人的AI助手。
```

### 阿里通义千问

```
配置名称: 通义千问
API地址: https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation
API密钥: sk-xxxxxxxxxxxxxxxx
模型名称: qwen-turbo
最大令牌数: 2000
温度参数: 0.7
系统提示词: 你是一个乐于助人的AI助手。
```

## 人格模板功能

### 使用预设模板

应用提供了多种预设人格模板：
- 🤖 乐于助人: 友善、耐心的助手
- 💼 专业顾问: 专业、严谨的顾问
- 🎨 创意伙伴: 富有创造力的伙伴
- 😄 幽默朋友: 幽默风趣的朋友
- 👨‍🏫 耐心老师: 耐心细致的老师

点击"应用"按钮即可使用该模板。

### 自定义模板

点击"添加模板"创建自定义人格模板：
- 模板名称: 为模板命名
- 描述: 简要描述模板特点
- 提示词: 详细定义AI的行为和角色
- 图标: 选择一个emoji作为标识

## 常见问题

### 1. 连接失败

**原因**:
- API密钥错误
- API地址错误
- 网络连接问题
- API配额用尽

**解决方案**:
- 检查API密钥是否正确
- 确认API地址格式正确
- 检查网络连接
- 查看API账户余额

### 2. 响应慢

**原因**:
- 模型处理时间长
- 网络延迟
- 请求参数过大

**解决方案**:
- 减少最大令牌数
- 使用更快的模型
- 检查网络状况

### 3. 响应质量差

**原因**:
- 温度参数设置不当
- 系统提示词不够明确
- 模型能力限制

**解决方案**:
- 调整温度参数（降低温度）
- 优化系统提示词
- 使用更强大的模型

## 技术实现

### API请求格式

应用使用标准的OpenAI兼容格式发送请求：

```json
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {"role": "system", "content": "你是一个乐于助人的AI助手。"},
    {"role": "user", "content": "你好"}
  ],
  "max_tokens": 2000,
  "temperature": 0.7,
  "stream": false
}
```

### 响应解析

应用支持多种API响应格式：
- OpenAI格式: `choices[0].message.content`
- 百度格式: `result`
- 阿里格式: `response`
- 通用格式: `content`

## 安全建议

1. **保护API密钥**: 不要分享你的API密钥
2. **定期更换**: 定期更换API密钥
3. **监控使用**: 监控API使用量和费用
4. **设置限制**: 合理设置最大令牌数避免过度消费

## 更新日志

### v1.0.0
- ✅ 实现完整的API配置功能
- ✅ 支持多种大模型API
- ✅ 提供配置表单和验证
- ✅ 支持连接测试
- ✅ 实现人格模板功能
- ✅ 数据持久化存储