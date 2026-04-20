import { ChatMessage, AIModelConfig } from '../model/ChatModel';
import http from '@ohos.net.http';

// 定义消息接口
interface AIMessage {
  role: string;
  content: string;
}

// 定义消息选择接口
interface AIMessageChoiceMessage {
  content: string;
}

interface AIMessageChoice {
  message?: AIMessageChoiceMessage;
}

// 定义响应接口
interface AIResponse {
  choices?: AIMessageChoice[];
  result?: string;
  response?: string;
  content?: string;
}

// 定义请求数据接口
interface AIRequestData {
  model: string;
  messages: AIMessage[];
  max_tokens: number;
  temperature: number;
  stream: boolean;
}

/**
 * AI服务类 - 处理与各种大模型API的通信
 */
export class AIService {
  private static instance: AIService;
  private httpRequest: http.HttpRequest;
  private currentConfig: AIModelConfig | null = null;

  private constructor() {
    this.httpRequest = http.createHttp();
  }

  public static getInstance(): AIService {
    if (!AIService.instance) {
      AIService.instance = new AIService();
    }
    return AIService.instance;
  }

  /**
   * 设置当前API配置
   */
  setConfig(config: AIModelConfig): void {
    this.currentConfig = config;
  }

  /**
   * 获取当前API配置
   */
  getCurrentConfig(): AIModelConfig | null {
    return this.currentConfig;
  }

  /**
   * 发送消息到AI模型
   */
  async sendMessage(
    messages: ChatMessage[], 
    personalityPrompt: string
  ): Promise<string> {
    if (!this.currentConfig) {
      throw new Error('未配置AI模型');
    }

    try {
      // 准备请求数据
      const requestData = this.prepareRequestData(messages, personalityPrompt);
      
      // 发送HTTP请求
      const response = await this.httpRequest.request(
        this.currentConfig.apiUrl,
        {
          method: http.RequestMethod.POST,
          header: this.getHeaders(),
          extraData: JSON.stringify(requestData),
          connectTimeout: 60000,
          readTimeout: 60000
        }
      );

      if (response.responseCode === 200) {
        return this.parseResponse(response.result as string);
      } else {
        throw new Error(`API请求失败: ${response.responseCode}`);
      }
    } catch (error) {
      console.error('AI服务错误:', error);
      throw new Error('AI服务请求失败');
    }
  }

  /**
   * 根据不同的API类型准备请求数据
   */
  private prepareRequestData(messages: ChatMessage[], personalityPrompt: string): AIRequestData {
    if (!this.currentConfig) {
      throw new Error('未配置AI模型');
    }

    const config = this.currentConfig;
    
    // 构建消息历史
    const formattedMessages: AIMessage[] = [
      { role: 'system', content: personalityPrompt || config.systemPrompt } as AIMessage
    ];

    messages.forEach(msg => {
      formattedMessages.push({
        role: msg.sender === 'user' ? 'user' : 'assistant',
        content: msg.content
      } as AIMessage);
    });

    // 通用OpenAI兼容格式
    const requestData: AIRequestData = {
      model: config.model,
      messages: formattedMessages,
      max_tokens: config.maxTokens,
      temperature: config.temperature,
      stream: false
    };
    return requestData;
  }

  /**
   * 获取请求头
   */
  private getHeaders(): Record<string, string> {
    if (!this.currentConfig) {
      throw new Error('未配置AI模型');
    }

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.currentConfig.apiKey}`,
      'User-Agent': 'HarmonyOS-AIChat/1.0'
    };
    return headers;
  }

  /**
   * 解析API响应
   */
  private parseResponse(responseText: string): string {
    try {
      const response: AIResponse = JSON.parse(responseText);
      
      // 支持多种API响应格式
      if (response.choices && response.choices[0] && response.choices[0].message) {
        // OpenAI格式
        return response.choices[0].message.content;
      } else if (response.result) {
        // 百度文心一言格式
        return response.result;
      } else if (response.response) {
        // 阿里通义千问格式
        return response.response;
      } else if (response.content) {
        // 通用格式
        return response.content;
      } else {
        console.warn('未知API响应格式:', response);
        return '抱歉，我无法理解API的响应格式。';
      }
    } catch (error) {
      console.error('解析响应失败:', error, '原始响应:', responseText);
      return '抱歉，处理API响应时出现错误。';
    }
  }

  /**
   * 测试API连接
   */
  async testConnection(config: AIModelConfig): Promise<boolean> {
    const originalConfig = this.currentConfig;
    this.currentConfig = config;

    try {
      const testMessage = new ChatMessage('你好', 'user');
      const response = await this.sendMessage([testMessage], '请回复"连接成功"');
      this.currentConfig = originalConfig;
      return response.includes('连接成功');
    } catch (error) {
      this.currentConfig = originalConfig;
      console.error('API连接测试失败:', error);
      return false;
    }
  }

  /**
   * 销毁资源
   */
  destroy(): void {
    if (this.httpRequest) {
      this.httpRequest.destroy();
    }
  }
}