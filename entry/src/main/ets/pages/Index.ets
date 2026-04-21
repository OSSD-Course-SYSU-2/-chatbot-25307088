import { ChatSession, ChatMessage, AIModelConfig, PersonalityTemplate, AppSettings } from '../model/ChatModel';
import { AIService } from '../service/AIService';
import { StorageService } from '../service/StorageService';
import { SettingsPage } from './SettingsPage';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  // 状态管理
  @State currentSession: ChatSession = new ChatSession();
  @State sessions: ChatSession[] = [];
  @State messageInput: string = '';
  @State isSending: boolean = false;
  @State showHistory: boolean = false;
  @State showPersonality: boolean = false;
  @State showSettings: boolean = false;
  @State personalityPrompt: string = '你是一个乐于助人的AI助手。';
  
  // 服务实例
  private aiService: AIService = AIService.getInstance();
  private storageService: StorageService = StorageService.getInstance();
  private uiAbilityContext: common.UIAbilityContext | null = null;
  
  // 页面生命周期
  aboutToAppear(): void {
    // 获取UIAbilityContext
    const uiContext = this.getUIContext();
    if (uiContext) {
      this.uiAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
      // 更新StorageService实例的上下文
      this.storageService = StorageService.getInstance(this.uiAbilityContext);
    }
    this.loadData();
  }
  
  // 页面每次显示时重新加载设置（确保人格模板更新生效）
  onPageShow(): void {
    this.loadPersonalityPrompt();
  }
  
  // 加载人格提示词
  async loadPersonalityPrompt(): Promise<void> {
    try {
      const settings = await this.storageService.getAppSettings();
      this.personalityPrompt = settings.personalityPrompt;
    } catch (error) {
      console.error('加载人格提示词失败:', error);
    }
  }
  
  // 加载数据
  async loadData(): Promise<void> {
    try {
      await this.storageService.initialize();
      
      // 加载会话历史
      this.sessions = await this.storageService.getChatSessions();
      
      // 加载应用设置
      const settings = await this.storageService.getAppSettings();
      this.personalityPrompt = settings.personalityPrompt;
      
      // 如果有当前会话ID，加载该会话
      if (settings.currentSessionId) {
        const session = await this.storageService.getChatSessionById(settings.currentSessionId);
        if (session) {
          this.currentSession = session;
        }
      }
      
      // 加载AI模型配置
      const modelConfigs = await this.storageService.getModelConfigs();
      const defaultConfig = modelConfigs.find(config => config.enabled);
      if (defaultConfig) {
        this.aiService.setConfig(defaultConfig);
      }
      
    } catch (error) {
      console.error('加载数据失败:', error);
    }
  }
  
  // 发送消息
  async sendMessage(): Promise<void> {
    if (!this.messageInput.trim() || this.isSending) return;
    
    const userMessage = new ChatMessage(this.messageInput, 'user');
    this.currentSession.addMessage(userMessage);
    this.messageInput = '';
    
    // 如果是新会话，添加到会话列表
    if (!this.sessions.find(s => s.id === this.currentSession.id)) {
      this.sessions.unshift(this.currentSession);
    }
    
    // 保存会话
    await this.saveCurrentSession();
    
    // 显示AI思考中
    const thinkingMessage = new ChatMessage('思考中...', 'assistant');
    thinkingMessage.isThinking = true;
    this.currentSession.addMessage(thinkingMessage);
    
    this.isSending = true;
    
    try {
      // 发送到AI
      const response = await this.aiService.sendMessage(
        this.currentSession.messages.filter(m => !m.isThinking),
        this.personalityPrompt
      );
      
      // 移除思考消息，添加真实响应
      this.currentSession.messages = this.currentSession.messages.filter(m => !m.isThinking);
      const aiMessage = new ChatMessage(response, 'assistant');
      this.currentSession.addMessage(aiMessage);
      
      // 保存更新后的会话
      await this.saveCurrentSession();
      
    } catch (error) {
      console.error('发送消息失败:', error);
      
      // 移除思考消息，添加错误消息
      this.currentSession.messages = this.currentSession.messages.filter(m => !m.isThinking);
      const errorMessage = new ChatMessage('抱歉，我遇到了问题。请检查网络连接和API配置。', 'assistant');
      this.currentSession.addMessage(errorMessage);
      
      await this.saveCurrentSession();
    } finally {
      this.isSending = false;
    }
  }
  
  // 保存当前会话
  async saveCurrentSession(): Promise<void> {
    try {
      await this.storageService.saveChatSession(this.currentSession);
      
      // 更新会话列表
      const index = this.sessions.findIndex(s => s.id === this.currentSession.id);
      if (index >= 0) {
        this.sessions[index] = this.currentSession;
      } else {
        this.sessions.unshift(this.currentSession);
      }
      
      // 保存当前会话ID到设置
      const settings = await this.storageService.getAppSettings();
      settings.currentSessionId = this.currentSession.id;
      await this.storageService.saveAppSettings(settings);
      
    } catch (error) {
      console.error('保存会话失败:', error);
    }
  }
  
  // 创建新会话
  createNewSession(): void {
    this.currentSession = new ChatSession();
    this.saveCurrentSession();
  }
  
  // 选择会话
  async selectSession(session: ChatSession): Promise<void> {
    this.currentSession = session;
    this.showHistory = false;
    
    // 保存当前会话ID到设置
    const settings = await this.storageService.getAppSettings();
    settings.currentSessionId = session.id;
    await this.storageService.saveAppSettings(settings);
  }
  
  // 删除会话
  async deleteSession(sessionId: string): Promise<void> {
    try {
      await this.storageService.deleteChatSession(sessionId);
      this.sessions = this.sessions.filter(s => s.id !== sessionId);
      
      // 如果删除的是当前会话，创建新会话
      if (this.currentSession.id === sessionId) {
        this.createNewSession();
      }
    } catch (error) {
      console.error('删除会话失败:', error);
    }
  }
  
  // 更新人格提示词
  async updatePersonalityPrompt(): Promise<void> {
    const settings = await this.storageService.getAppSettings();
    settings.personalityPrompt = this.personalityPrompt;
    await this.storageService.saveAppSettings(settings);
    this.showPersonality = false;
  }
  
  // 渲染消息项
  @Builder
  MessageItem(message: ChatMessage) {
    Column() {
      if (message.sender === 'user') {
        // 用户消息
        Row() {
          Text(message.content)
            .fontSize(16)
            .fontColor(Color.White)
            .padding(12)
            .backgroundColor('#007AFF')
            .borderRadius(20)
            .width('80%')
        }
        .justifyContent(FlexAlign.End)
        .width('100%')
        .margin({ bottom: 12 })
      } else {
        // AI消息
        Row() {
          if (message.isThinking) {
            // 思考中动画
            LoadingProgress()
              .color(Color.Blue)
              .width(24)
              .height(24)
          } else {
            Text(message.content)
              .fontSize(16)
              .fontColor(Color.Black)
              .padding(12)
              .backgroundColor('#F2F2F7')
              .borderRadius(20)
              .width('80%')
          }
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .margin({ bottom: 12 })
      }
    }
  }
  
  // 格式化日期
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    if (date >= today) {
      return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
    } else if (date >= yesterday) {
      return '昨天';
    } else {
      return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' });
    }
  }
  
  build() {
    Stack() {
      // 主内容区域
      Column() {
        // 顶部工具栏
        Row() {
          // 应用标题
          Text('AI聊天助手')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          
          // 工具栏按钮
          Row() {
            Button('历史')
              .fontSize(14)
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.showHistory = !this.showHistory;
              })
            
            Button('人格')
              .fontSize(14)
              .backgroundColor(Color.Transparent)
              .margin({ left: 8 })
              .onClick(() => {
                this.showPersonality = true;
              })
            
            Button('设置')
              .fontSize(14)
              .fontColor('#666666')
              .backgroundColor(Color.Transparent)
              .margin({ left: 8 })
              .onClick(() => {
                this.showSettings = true;
              })
          }
        }
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 2, color: '#000000', offsetX: 0, offsetY: 2 })
        
        // 主内容区域
        Row() {
          // 左侧会话历史（可折叠）
          if (this.showHistory) {
            Column() {
              // 会话历史标题
              Row() {
                Text('会话历史')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                
                Button('新建')
                  .fontSize(12)
                  .type(ButtonType.Circle)
                  .size({ width: 32, height: 32 })
                  .onClick(() => {
                    this.createNewSession();
                  })
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              
              // 会话列表
              List() {
                ForEach(this.sessions, (session: ChatSession) => {
                  ListItem() {
                    Column() {
                      Row() {
                        Text(session.title)
                          .fontSize(14)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                        
                        // 删除按钮
                        if (session.id !== this.currentSession.id) {
                          Button('×')
                            .fontSize(12)
                            .type(ButtonType.Circle)
                            .size({ width: 24, height: 24 })
                            .backgroundColor(Color.Red)
                            .fontColor(Color.White)
                            .onClick(() => {
                              this.deleteSession(session.id);
                            })
                        }
                      }
                      
                      Text(this.formatDate(session.updatedAt))
                        .fontSize(12)
                        .fontColor('#8E8E93')
                        .margin({ top: 4 })
                    }
                    .padding(12)
                    .backgroundColor(session.id === this.currentSession.id ? '#E3F2FD' : Color.White)
                    .borderRadius(8)
                    .onClick(() => {
                      this.selectSession(session);
                    })
                  }
                })
              }
              .layoutWeight(1)
            }
            .width('30%')
            .backgroundColor('#F5F5F5')
            .border({ width: 1, color: '#E0E0E0' })
          }
          
          // 右侧聊天区域
          Column() {
            // 聊天标题
            Row() {
              Text(this.currentSession.title)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
            }
            .padding(16)
            .backgroundColor(Color.White)
            .border({ width: { bottom: 1 }, color: '#E0E0E0' })
            
            // 消息列表
            Scroll() {
              Column() {
                ForEach(this.currentSession.messages, (message: ChatMessage) => {
                  this.MessageItem(message)
                })
              }
              .padding(16)
              .width('100%')
            }
            .layoutWeight(1)
            
            // 输入区域
            Column() {
              Row() {
                TextInput({ placeholder: '输入消息...', text: this.messageInput })
                  .layoutWeight(1)
                  .fontSize(16)
                  .padding(12)
                  .borderRadius(20)
                  .backgroundColor('#F2F2F7')
                  .onChange((value: string) => {
                    this.messageInput = value;
                  })
                  .onSubmit(() => {
                    this.sendMessage();
                  })
                
                Button(this.isSending ? '发送中...' : '发送')
                  .fontSize(16)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(this.isSending || !this.messageInput.trim() ? '#CCCCCC' : '#007AFF')
                  .fontColor(Color.White)
                  .borderRadius(20)
                  .enabled(!this.isSending && !!this.messageInput.trim())
                  .onClick(() => {
                    this.sendMessage();
                  })
                  .margin({ left: 8 })
              }
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            }
            .backgroundColor(Color.White)
            .border({ width: { top: 1 }, color: '#E0E0E0' })
          }
          .layoutWeight(1)
        }
        .layoutWeight(1)
      }
      .height('100%')
      .width('100%')
      .backgroundColor('#FFFFFF')
      
      // 设置页面（使用条件渲染）
      if (this.showSettings) {
        Stack() {
          // 半透明背景遮罩
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .opacity(0.5)
            .onClick(() => {
              this.showSettings = false;
            })
          
          // 设置页面内容
          SettingsPage()
            .width('80%')
            .height('80%')
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 10, color: '#000000', offsetX: 0, offsetY: 2 })
            .align(Alignment.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
      }
    }
    .height('100%')
    .width('100%')
  }
}