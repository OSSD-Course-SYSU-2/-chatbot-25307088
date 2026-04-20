/**
 * 聊天消息模型
 */
export class ChatMessage {
  id: string;
  content: string;
  sender: 'user' | 'assistant';
  timestamp: number;
  isThinking?: boolean = false;

  constructor(content: string, sender: 'user' | 'assistant') {
    this.id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    this.content = content;
    this.sender = sender;
    this.timestamp = Date.now();
  }
}

/**
 * 聊天会话模型
 */
export class ChatSession {
  id: string;
  title: string;
  messages: ChatMessage[];
  createdAt: number;
  updatedAt: number;
  personalityPrompt: string;

  constructor(title?: string) {
    this.id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    this.title = title || '新对话';
    this.messages = [];
    this.createdAt = Date.now();
    this.updatedAt = Date.now();
    this.personalityPrompt = '你是一个乐于助人的AI助手。';
  }

  addMessage(message: ChatMessage): void {
    this.messages.push(message);
    this.updatedAt = Date.now();
    
    // 如果这是第一条消息，更新会话标题
    if (this.messages.length === 1 && message.sender === 'user') {
      const firstMessage = message.content.substring(0, 30);
      this.title = firstMessage + (message.content.length > 30 ? '...' : '');
    }
  }

  getLastMessage(): ChatMessage | null {
    return this.messages.length > 0 ? this.messages[this.messages.length - 1] : null;
  }
}

/**
 * AI模型配置
 */
export interface AIModelConfig {
  id: string;
  name: string;
  apiUrl: string;
  apiKey: string;
  model: string;
  maxTokens: number;
  temperature: number;
  systemPrompt: string;
  enabled: boolean;
}

/**
 * 人格提示词模板
 */
export interface PersonalityTemplate {
  id: string;
  name: string;
  description: string;
  prompt: string;
  icon: string;
}

/**
 * 应用设置
 */
export interface AppSettings {
  currentSessionId: string | null;
  defaultModelConfigId: string;
  personalityPrompt: string;
  autoSave: boolean;
  darkMode: boolean;
}