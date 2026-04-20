import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { ChatSession, ChatMessage, AIModelConfig, PersonalityTemplate, AppSettings } from '../model/ChatModel';

// 定义消息数据接口
interface MessageData {
  id: string;
  content: string;
  sender: 'user' | 'assistant';
  timestamp: number;
}

// 定义会话数据接口
interface SessionData {
  id: string;
  title: string;
  createdAt: number;
  updatedAt: number;
  messages: MessageData[];
}

// 定义设置数据接口
interface SettingsData {
  currentSessionId: string | null;
  defaultModelConfigId: string;
  personalityPrompt: string;
  autoSave: boolean;
  darkMode: boolean;
}

// 定义模拟上下文接口
interface MockContext {
  bundleName: string;
  moduleName: string;
}

/**
 * 数据存储服务 - 使用Preferences存储会话和配置数据
 */
export class StorageService {
  private static instance: StorageService;
  private preferences: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME = 'ai_chat_preferences';
  private readonly SESSIONS_KEY = 'chat_sessions';
  private readonly MODEL_CONFIGS_KEY = 'model_configs';
  private readonly PERSONALITY_TEMPLATES_KEY = 'personality_templates';
  private readonly SETTINGS_KEY = 'app_settings';
  private context: common.UIAbilityContext | null = null;

  private constructor() {}

  public static getInstance(context?: common.UIAbilityContext): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService();
    }
    if (context) {
      StorageService.instance.context = context;
    }
    return StorageService.instance;
  }

  /**
   * 初始化存储
   */
  async initialize(): Promise<void> {
    try {
      if (!this.context) {
        throw new Error('上下文未设置，请先调用getInstance(context)设置上下文');
      }
      const prefs = await preferences.getPreferences(this.context, this.PREFERENCES_NAME);
      this.preferences = prefs;
      await this.initializeDefaultData();
    } catch (error) {
      console.error('初始化存储失败:', error);
      throw new Error('存储初始化失败');
    }
  }



  /**
   * 初始化默认数据
   */
  private async initializeDefaultData(): Promise<void> {
    if (!this.preferences) return;

    // 检查是否有默认模型配置
    const hasModelConfigs = await this.preferences.has(this.MODEL_CONFIGS_KEY);
    if (!hasModelConfigs) {
      const defaultConfigs = this.getDefaultModelConfigs();
      await this.saveModelConfigs(defaultConfigs);
    }

    // 检查是否有人格模板
    const hasTemplates = await this.preferences.has(this.PERSONALITY_TEMPLATES_KEY);
    if (!hasTemplates) {
      const defaultTemplates = this.getDefaultPersonalityTemplates();
      await this.savePersonalityTemplates(defaultTemplates);
    }

    // 检查是否有应用设置
    const hasSettings = await this.preferences.has(this.SETTINGS_KEY);
    if (!hasSettings) {
      const defaultSettings = this.getDefaultAppSettings();
      await this.saveAppSettings(defaultSettings);
    }
  }

  /**
   * 保存聊天会话
   */
  async saveChatSession(session: ChatSession): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const sessions = await this.getChatSessions();
      const existingIndex = sessions.findIndex(s => s.id === session.id);
      
      if (existingIndex >= 0) {
        sessions[existingIndex] = session;
      } else {
        sessions.push(session);
      }

      await this.preferences!.put(this.SESSIONS_KEY, JSON.stringify(sessions));
      await this.preferences!.flush();
    } catch (error) {
      console.error('保存会话失败:', error);
      throw new Error('保存会话失败');
    }
  }

  /**
   * 获取所有聊天会话
   */
  async getChatSessions(): Promise<ChatSession[]> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const sessionsJson = await this.preferences!.get(this.SESSIONS_KEY, '[]') as string;
      const sessionsData: SessionData[] = JSON.parse(sessionsJson);
      
      // 将普通对象转换为ChatSession实例
      return sessionsData.map((data: SessionData) => {
        const session = new ChatSession(data.title);
        session.id = data.id || session.id;
        session.title = data.title || session.title;
        session.createdAt = data.createdAt || session.createdAt;
        session.updatedAt = data.updatedAt || session.updatedAt;
        // 转换消息数据
        session.messages = data.messages.map(msg => {
          const chatMessage = new ChatMessage(msg.content, msg.sender);
          chatMessage.id = msg.id;
          chatMessage.timestamp = msg.timestamp;
          return chatMessage;
        });
        return session;
      });
    } catch (error) {
      console.error('获取会话失败:', error);
      return [];
    }
  }

  /**
   * 根据ID获取聊天会话
   */
  async getChatSessionById(id: string): Promise<ChatSession | null> {
    const sessions = await this.getChatSessions();
    return sessions.find(session => session.id === id) || null;
  }

  /**
   * 删除聊天会话
   */
  async deleteChatSession(id: string): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const sessions = await this.getChatSessions();
      const filteredSessions = sessions.filter(session => session.id !== id);
      await this.preferences!.put(this.SESSIONS_KEY, JSON.stringify(filteredSessions));
      await this.preferences!.flush();
    } catch (error) {
      console.error('删除会话失败:', error);
      throw new Error('删除会话失败');
    }
  }

  /**
   * 保存AI模型配置
   */
  async saveModelConfigs(configs: AIModelConfig[]): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      await this.preferences!.put(this.MODEL_CONFIGS_KEY, JSON.stringify(configs));
      await this.preferences!.flush();
    } catch (error) {
      console.error('保存模型配置失败:', error);
      throw new Error('保存模型配置失败');
    }
  }

  /**
   * 获取所有AI模型配置
   */
  async getModelConfigs(): Promise<AIModelConfig[]> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const configsJson = await this.preferences!.get(this.MODEL_CONFIGS_KEY, '[]') as string;
      return JSON.parse(configsJson);
    } catch (error) {
      console.error('获取模型配置失败:', error);
      return this.getDefaultModelConfigs();
    }
  }

  /**
   * 保存人格模板
   */
  async savePersonalityTemplates(templates: PersonalityTemplate[]): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      await this.preferences!.put(this.PERSONALITY_TEMPLATES_KEY, JSON.stringify(templates));
      await this.preferences!.flush();
    } catch (error) {
      console.error('保存人格模板失败:', error);
      throw new Error('保存人格模板失败');
    }
  }

  /**
   * 获取所有人格模板
   */
  async getPersonalityTemplates(): Promise<PersonalityTemplate[]> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const templatesJson = await this.preferences!.get(this.PERSONALITY_TEMPLATES_KEY, '[]') as string;
      return JSON.parse(templatesJson);
    } catch (error) {
      console.error('获取人格模板失败:', error);
      return this.getDefaultPersonalityTemplates();
    }
  }

  /**
   * 根据ID获取AI模型配置
   */
  async getModelConfigById(id: string): Promise<AIModelConfig | null> {
    const configs = await this.getModelConfigs();
    return configs.find(config => config.id === id) || null;
  }

  /**
   * 添加新的AI模型配置
   */
  async addModelConfig(config: AIModelConfig): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const configs = await this.getModelConfigs();
      
      // 检查是否已存在相同ID的配置
      const existingIndex = configs.findIndex(c => c.id === config.id);
      if (existingIndex >= 0) {
        throw new Error(`已存在ID为 ${config.id} 的模型配置`);
      }
      
      configs.push(config);
      await this.saveModelConfigs(configs);
    } catch (error) {
      console.error('添加模型配置失败:', error);
      throw new Error('添加模型配置失败');
    }
  }

  /**
   * 更新AI模型配置
   */
  async updateModelConfig(config: AIModelConfig): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const configs = await this.getModelConfigs();
      const existingIndex = configs.findIndex(c => c.id === config.id);
      
      if (existingIndex < 0) {
        throw new Error(`未找到ID为 ${config.id} 的模型配置`);
      }
      
      configs[existingIndex] = config;
      await this.saveModelConfigs(configs);
    } catch (error) {
      console.error('更新模型配置失败:', error);
      throw new Error('更新模型配置失败');
    }
  }

  /**
   * 删除AI模型配置
   */
  async deleteModelConfig(id: string): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const configs = await this.getModelConfigs();
      const filteredConfigs = configs.filter(config => config.id !== id);
      
      // 如果删除的是默认配置，需要更新应用设置
      const settings = await this.getAppSettings();
      if (settings.defaultModelConfigId === id) {
        settings.defaultModelConfigId = filteredConfigs.length > 0 ? filteredConfigs[0].id : '';
        await this.saveAppSettings(settings);
      }
      
      await this.saveModelConfigs(filteredConfigs);
    } catch (error) {
      console.error('删除模型配置失败:', error);
      throw new Error('删除模型配置失败');
    }
  }

  /**
   * 根据ID获取人格模板
   */
  async getPersonalityTemplateById(id: string): Promise<PersonalityTemplate | null> {
    const templates = await this.getPersonalityTemplates();
    return templates.find(template => template.id === id) || null;
  }

  /**
   * 添加新的人格模板
   */
  async addPersonalityTemplate(template: PersonalityTemplate): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const templates = await this.getPersonalityTemplates();
      
      // 检查是否已存在相同ID的模板
      const existingIndex = templates.findIndex(t => t.id === template.id);
      if (existingIndex >= 0) {
        throw new Error(`已存在ID为 ${template.id} 的人格模板`);
      }
      
      templates.push(template);
      await this.savePersonalityTemplates(templates);
    } catch (error) {
      console.error('添加人格模板失败:', error);
      throw new Error('添加人格模板失败');
    }
  }

  /**
   * 更新人格模板
   */
  async updatePersonalityTemplate(template: PersonalityTemplate): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const templates = await this.getPersonalityTemplates();
      const existingIndex = templates.findIndex(t => t.id === template.id);
      
      if (existingIndex < 0) {
        throw new Error(`未找到ID为 ${template.id} 的人格模板`);
      }
      
      templates[existingIndex] = template;
      await this.savePersonalityTemplates(templates);
    } catch (error) {
      console.error('更新人格模板失败:', error);
      throw new Error('更新人格模板失败');
    }
  }

  /**
   * 删除人格模板
   */
  async deletePersonalityTemplate(id: string): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const templates = await this.getPersonalityTemplates();
      const filteredTemplates = templates.filter(template => template.id !== id);
      await this.savePersonalityTemplates(filteredTemplates);
    } catch (error) {
      console.error('删除人格模板失败:', error);
      throw new Error('删除人格模板失败');
    }
  }

  /**
   * 保存应用设置
   */
  async saveAppSettings(settings: AppSettings): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      await this.preferences!.put(this.SETTINGS_KEY, JSON.stringify(settings));
      await this.preferences!.flush();
    } catch (error) {
      console.error('保存应用设置失败:', error);
      throw new Error('保存应用设置失败');
    }
  }

  /**
   * 获取应用设置
   */
  async getAppSettings(): Promise<AppSettings> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      const settingsJson = await this.preferences!.get(this.SETTINGS_KEY, '{}') as string;
      const settings: SettingsData = JSON.parse(settingsJson);
      
      // 合并默认设置
      const defaultSettings = this.getDefaultAppSettings();
      const settingsData = settings as SettingsData;
      return {
        currentSessionId: settingsData.currentSessionId || defaultSettings.currentSessionId,
        defaultModelConfigId: settingsData.defaultModelConfigId || defaultSettings.defaultModelConfigId,
        personalityPrompt: settingsData.personalityPrompt || defaultSettings.personalityPrompt,
        autoSave: settingsData.autoSave !== undefined ? settingsData.autoSave : defaultSettings.autoSave,
        darkMode: settingsData.darkMode !== undefined ? settingsData.darkMode : defaultSettings.darkMode
      };
    } catch (error) {
      console.error('获取应用设置失败:', error);
      return this.getDefaultAppSettings();
    }
  }

  /**
   * 获取默认AI模型配置
   */
  private getDefaultModelConfigs(): AIModelConfig[] {
    return [
      {
        id: 'openai-gpt-3.5',
        name: 'OpenAI GPT-3.5',
        apiUrl: 'https://api.openai.com/v1/chat/completions',
        apiKey: '',
        model: 'gpt-3.5-turbo',
        maxTokens: 2000,
        temperature: 0.7,
        systemPrompt: '你是一个乐于助人的AI助手。',
        enabled: true
      },
      {
        id: 'openai-gpt-4',
        name: 'OpenAI GPT-4',
        apiUrl: 'https://api.openai.com/v1/chat/completions',
        apiKey: '',
        model: 'gpt-4',
        maxTokens: 4000,
        temperature: 0.7,
        systemPrompt: '你是一个乐于助人的AI助手。',
        enabled: false
      }
    ];
  }

  /**
   * 获取默认人格模板
   */
  private getDefaultPersonalityTemplates(): PersonalityTemplate[] {
    return [
      {
        id: 'helpful',
        name: '乐于助人',
        description: '友善、耐心的助手',
        prompt: '你是一个乐于助人的AI助手，总是以友好、耐心的态度回答用户的问题，提供详细、准确的帮助。',
        icon: '🤖'
      },
      {
        id: 'professional',
        name: '专业顾问',
        description: '专业、严谨的顾问',
        prompt: '你是一个专业的顾问，回答问题时要严谨、专业，提供基于事实和数据的建议。',
        icon: '💼'
      },
      {
        id: 'creative',
        name: '创意伙伴',
        description: '富有创造力的伙伴',
        prompt: '你是一个富有创造力的伙伴，思维活跃，能提供新颖的想法和创意解决方案。',
        icon: '🎨'
      },
      {
        id: 'humorous',
        name: '幽默朋友',
        description: '幽默风趣的朋友',
        prompt: '你是一个幽默风趣的朋友，回答问题时可以适当加入幽默元素，让对话更加轻松愉快。',
        icon: '😄'
      },
      {
        id: 'teacher',
        name: '耐心老师',
        description: '耐心细致的老师',
        prompt: '你是一个耐心的老师，善于用简单易懂的方式解释复杂概念，引导用户学习新知识。',
        icon: '👨‍🏫'
      }
    ];
  }

  /**
   * 获取默认应用设置
   */
  private getDefaultAppSettings(): AppSettings {
    return {
      currentSessionId: null,
      defaultModelConfigId: 'openai-gpt-3.5',
      personalityPrompt: '你是一个乐于助人的AI助手。',
      autoSave: true,
      darkMode: false
    };
  }

  /**
   * 清理所有数据
   */
  async clearAllData(): Promise<void> {
    if (!this.preferences) {
      await this.initialize();
    }

    try {
      await this.preferences!.delete(this.SESSIONS_KEY);
      await this.preferences!.delete(this.MODEL_CONFIGS_KEY);
      await this.preferences!.delete(this.PERSONALITY_TEMPLATES_KEY);
      await this.preferences!.delete(this.SETTINGS_KEY);
      await this.preferences!.flush();
      
      // 重新初始化默认数据
      await this.initializeDefaultData();
    } catch (error) {
      console.error('清理数据失败:', error);
      throw new Error('清理数据失败');
    }
  }
}