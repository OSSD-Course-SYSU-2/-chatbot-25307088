import { AIModelConfig, PersonalityTemplate, AppSettings } from '../model/ChatModel';
import { AIService } from '../service/AIService';
import { StorageService } from '../service/StorageService';

@Component
export struct SettingsPage {
  @State modelConfigs: AIModelConfig[] = [];
  @State personalityTemplates: PersonalityTemplate[] = [];
  @State appSettings: AppSettings = {
    currentSessionId: null,
    defaultModelConfigId: 'openai-gpt-3.5',
    personalityPrompt: '你是一个乐于助人的AI助手。',
    autoSave: true,
    darkMode: false
  };
  
  @State showModelConfigForm: boolean = false;
  @State editingModelConfig: AIModelConfig | null = null;
  @State newModelConfig: AIModelConfig = {
    id: '',
    name: '',
    apiUrl: '',
    apiKey: '',
    model: 'gpt-3.5-turbo',
    maxTokens: 2000,
    temperature: 0.7,
    systemPrompt: '你是一个乐于助人的AI助手。',
    enabled: true
  };
  
  @State showPersonalityTemplateForm: boolean = false;
  @State editingPersonalityTemplate: PersonalityTemplate | null = null;
  @State newPersonalityTemplate: PersonalityTemplate = {
    id: '',
    name: '',
    description: '',
    prompt: '',
    icon: '🤖'
  };
  
  @State testingConnection: boolean = false;
  @State testResult: string = '';
  @State modelConfigFormErrors: Map<string, string> = new Map();
  @State personalityTemplateFormErrors: Map<string, string> = new Map();
  @State appliedTemplateId: string = ''; // 已应用的人格模板ID
  
  private storageService: StorageService = StorageService.getInstance();
  private aiService: AIService = AIService.getInstance();
  
  aboutToAppear(): void {
    this.loadData();
  }
  
  async loadData(): Promise<void> {
    try {
      await this.storageService.initialize();
      this.modelConfigs = await this.storageService.getModelConfigs();
      this.personalityTemplates = await this.storageService.getPersonalityTemplates();
      this.appSettings = await this.storageService.getAppSettings();
    } catch (error) {
      console.error('加载设置数据失败:', error);
    }
  }
  
  async setDefaultConfig(configId: string): Promise<void> {
    this.appSettings.defaultModelConfigId = configId;
    await this.storageService.saveAppSettings(this.appSettings);
    
    const config = this.modelConfigs.find((c: AIModelConfig) => c.id === configId);
    if (config) {
      this.aiService.setConfig(config);
    }
  }
  
  async applyPersonalityTemplate(template: PersonalityTemplate): Promise<void> {
    try {
      this.appSettings.personalityPrompt = template.prompt;
      this.appliedTemplateId = template.id;
      await this.storageService.saveAppSettings(this.appSettings);
      // 显示成功提示
      this.testResult = `已应用人格模板：${template.name}`;
      // 3秒后清除提示
      setTimeout(() => {
        this.testResult = '';
      }, 3000);
    } catch (error) {
      console.error('应用人格模板失败:', error);
      this.testResult = '应用失败: ' + (error as Error).message;
    }
  }
  
  async saveAppSettings(): Promise<void> {
    await this.storageService.saveAppSettings(this.appSettings);
  }
  
  async clearAllData(): Promise<void> {
    try {
      await this.storageService.clearAllData();
      await this.loadData();
    } catch (error) {
      console.error('清理数据失败:', error);
    }
  }
  
  openModelConfigForm(config?: AIModelConfig): void {
    if (config) {
      this.editingModelConfig = config;
      this.newModelConfig = {
        id: config.id,
        name: config.name,
        apiUrl: config.apiUrl,
        apiKey: config.apiKey,
        model: config.model,
        maxTokens: config.maxTokens,
        temperature: config.temperature,
        systemPrompt: config.systemPrompt,
        enabled: config.enabled
      };
    } else {
      this.editingModelConfig = null;
      this.newModelConfig = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        name: '',
        apiUrl: 'https://api.openai.com/v1/chat/completions',
        apiKey: '',
        model: 'gpt-3.5-turbo',
        maxTokens: 2000,
        temperature: 0.7,
        systemPrompt: '你是一个乐于助人的AI助手。',
        enabled: true
      };
    }
    this.showModelConfigForm = true;
    this.modelConfigFormErrors = new Map();
    this.testResult = '';
  }
  
  closeModelConfigForm(): void {
    this.showModelConfigForm = false;
    this.editingModelConfig = null;
    this.newModelConfig = {
      id: '',
      name: '',
      apiUrl: '',
      apiKey: '',
      model: 'gpt-3.5-turbo',
      maxTokens: 2000,
      temperature: 0.7,
      systemPrompt: '你是一个乐于助人的AI助手。',
      enabled: true
    };
    this.modelConfigFormErrors = new Map();
  }
  
  validateModelConfig(): boolean {
    const errors: Map<string, string> = new Map();
    
    if (!this.newModelConfig.name.trim()) {
      errors.set('name', '名称不能为空');
    }
    
    if (!this.newModelConfig.apiUrl.trim()) {
      errors.set('apiUrl', 'API地址不能为空');
    } else if (!this.newModelConfig.apiUrl.startsWith('http://') && 
               !this.newModelConfig.apiUrl.startsWith('https://')) {
      errors.set('apiUrl', 'API地址必须以http://或https://开头');
    }
    
    if (!this.newModelConfig.apiKey.trim()) {
      errors.set('apiKey', 'API密钥不能为空');
    }
    
    if (!this.newModelConfig.model.trim()) {
      errors.set('model', '模型名称不能为空');
    }
    
    if (this.newModelConfig.maxTokens < 1 || this.newModelConfig.maxTokens > 100000) {
      errors.set('maxTokens', '最大令牌数必须在1-100000之间');
    }
    
    if (this.newModelConfig.temperature < 0 || this.newModelConfig.temperature > 2) {
      errors.set('temperature', '温度参数必须在0-2之间');
    }
    
    this.modelConfigFormErrors = errors;
    return errors.size === 0;
  }
  
  async saveModelConfig(): Promise<void> {
    if (!this.validateModelConfig()) {
      return;
    }
    
    try {
      if (this.editingModelConfig) {
        await this.storageService.updateModelConfig(this.newModelConfig);
      } else {
        await this.storageService.addModelConfig(this.newModelConfig);
      }
      
      await this.loadData();
      this.closeModelConfigForm();
    } catch (error) {
      console.error('保存模型配置失败:', error);
      this.testResult = '保存失败: ' + (error as Error).message;
    }
  }
  
  async deleteModelConfig(id: string): Promise<void> {
    try {
      await this.storageService.deleteModelConfig(id);
      await this.loadData();
    } catch (error) {
      console.error('删除模型配置失败:', error);
    }
  }
  
  openPersonalityTemplateForm(template?: PersonalityTemplate): void {
    if (template) {
      this.editingPersonalityTemplate = template;
      this.newPersonalityTemplate = {
        id: template.id,
        name: template.name,
        description: template.description,
        prompt: template.prompt,
        icon: template.icon
      };
    } else {
      this.editingPersonalityTemplate = null;
      this.newPersonalityTemplate = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        name: '',
        description: '',
        prompt: '',
        icon: '🤖'
      };
    }
    this.showPersonalityTemplateForm = true;
    this.personalityTemplateFormErrors = new Map();
  }
  
  closePersonalityTemplateForm(): void {
    this.showPersonalityTemplateForm = false;
    this.editingPersonalityTemplate = null;
    this.newPersonalityTemplate = {
      id: '',
      name: '',
      description: '',
      prompt: '',
      icon: '🤖'
    };
    this.personalityTemplateFormErrors = new Map();
  }
  
  validatePersonalityTemplate(): boolean {
    const errors: Map<string, string> = new Map();
    
    if (!this.newPersonalityTemplate.name.trim()) {
      errors.set('name', '名称不能为空');
    }
    
    if (!this.newPersonalityTemplate.description.trim()) {
      errors.set('description', '描述不能为空');
    }
    
    if (!this.newPersonalityTemplate.prompt.trim()) {
      errors.set('prompt', '提示词不能为空');
    }
    
    this.personalityTemplateFormErrors = errors;
    return errors.size === 0;
  }
  
  async savePersonalityTemplate(): Promise<void> {
    if (!this.validatePersonalityTemplate()) {
      return;
    }
    
    try {
      if (this.editingPersonalityTemplate) {
        await this.storageService.updatePersonalityTemplate(this.newPersonalityTemplate);
      } else {
        await this.storageService.addPersonalityTemplate(this.newPersonalityTemplate);
      }
      
      await this.loadData();
      this.closePersonalityTemplateForm();
    } catch (error) {
      console.error('保存人格模板失败:', error);
      this.testResult = '保存失败: ' + (error as Error).message;
    }
  }
  
  async deletePersonalityTemplate(id: string): Promise<void> {
    try {
      await this.storageService.deletePersonalityTemplate(id);
      await this.loadData();
    } catch (error) {
      console.error('删除人格模板失败:', error);
    }
  }
  
  async testApiConnection(): Promise<void> {
    if (!this.validateModelConfig()) {
      return;
    }
    
    this.testingConnection = true;
    this.testResult = '正在测试连接...';
    
    try {
      const testService = AIService.getInstance();
      const originalConfig = testService.getCurrentConfig();
      testService.setConfig(this.newModelConfig);
      
      const result = await testService.testConnection(this.newModelConfig);
      this.testResult = result ? '连接成功！API配置有效。' : '连接失败，请检查API配置。';
      
      if (originalConfig) {
        testService.setConfig(originalConfig);
      }
    } catch (error) {
      console.error('测试连接失败:', error);
      this.testResult = '连接失败: ' + (error as Error).message;
    } finally {
      this.testingConnection = false;
    }
  }
  
  build() {
    Stack() {
      // 主内容
      Column() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24, bottom: 16 })
        
        Scroll() {
          Column() {
            Row() {
              Text('AI模型配置')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .margin({ top: 16, bottom: 12 })
                .layoutWeight(1)
              
              Button('添加配置')
                .fontSize(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('#34C759')
                .fontColor(Color.White)
                .borderRadius(4)
                .onClick(() => {
                  this.openModelConfigForm();
                })
            }
            .width('100%')
          
          ForEach(this.modelConfigs, (config: AIModelConfig) => {
            Row() {
              Column() {
                Text(config.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                
                Text(config.model)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ top: 4 })
              }
              .layoutWeight(1)
              
              Row() {
                if (config.id === this.appSettings.defaultModelConfigId) {
                  Text('默认')
                    .fontSize(12)
                    .fontColor('#007AFF')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#E3F2FD')
                    .borderRadius(4)
                } else {
                  Button('设为默认')
                    .fontSize(12)
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#F2F2F7')
                    .fontColor('#666666')
                    .onClick(() => {
                      this.setDefaultConfig(config.id);
                    })
                }
                
                Button('编辑')
                  .fontSize(12)
                  .margin({ left: 8 })
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F2F2F7')
                  .fontColor('#666666')
                  .onClick(() => {
                    this.openModelConfigForm(config);
                  })
                
                Button('删除')
                  .fontSize(12)
                  .margin({ left: 8 })
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#FF3B30')
                  .fontColor(Color.White)
                  .onClick(() => {
                    this.deleteModelConfig(config.id);
                  })
              }
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderWidth(1)
            .borderColor('#E0E0E0')
            .borderRadius(8)
            .margin({ bottom: 8 })
          })
          
          Row() {
            Text('人格模板')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .margin({ top: 24, bottom: 12 })
              .layoutWeight(1)
            
            Button('添加模板')
              .fontSize(12)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor('#34C759')
              .fontColor(Color.White)
              .borderRadius(4)
              .onClick(() => {
                this.openPersonalityTemplateForm();
              })
          }
          .width('100%')
          
          // 显示应用结果提示
          if (this.testResult && this.testResult.includes('人格模板')) {
            Text(this.testResult)
              .fontSize(14)
              .fontColor('#34C759')
              .padding(12)
              .backgroundColor('#E8F5E9')
              .borderRadius(8)
              .width('100%')
              .margin({ top: 8, bottom: 8 })
          }
          
          ForEach(this.personalityTemplates, (template: PersonalityTemplate) => {
            Column() {
              Row() {
                Column() {
                  Text(template.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  
                  Text(template.description)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 4 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                
                Row() {
                  Button(this.appliedTemplateId === template.id ? '已应用' : '应用')
                    .fontSize(12)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .backgroundColor(this.appliedTemplateId === template.id ? '#34C759' : '#007AFF')
                    .fontColor(Color.White)
                    .borderRadius(4)
                    .onClick(() => {
                      this.applyPersonalityTemplate(template);
                    })
                  
                  Button('编辑')
                    .fontSize(12)
                    .margin({ left: 8 })
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#F2F2F7')
                    .fontColor('#666666')
                    .onClick(() => {
                      this.openPersonalityTemplateForm(template);
                    })
                  
                  Button('删除')
                    .fontSize(12)
                    .margin({ left: 8 })
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#FF3B30')
                    .fontColor(Color.White)
                    .onClick(() => {
                      this.deletePersonalityTemplate(template.id);
                    })
                }
              }
              
              Text(template.prompt)
                .fontSize(12)
                .fontColor('#8E8E93')
                .margin({ top: 8 })
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderWidth(1)
            .borderColor('#E0E0E0')
            .borderRadius(8)
            .margin({ bottom: 8 })
          })
          
          Text('应用设置')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
            .margin({ top: 24, bottom: 12 })
          
          Column() {
            Row() {
              Text('自动保存会话')
                .fontSize(16)
                .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.appSettings.autoSave })
                .onChange((isOn: boolean) => {
                  this.appSettings.autoSave = isOn;
                  this.saveAppSettings();
                })
            }
            .padding({ top: 12, bottom: 12 })
            
            Row() {
              Text('深色模式')
                .fontSize(16)
                .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.appSettings.darkMode })
                .onChange((isOn: boolean) => {
                  this.appSettings.darkMode = isOn;
                  this.saveAppSettings();
                })
            }
            .padding({ top: 12, bottom: 12 })
          }
          .backgroundColor(Color.White)
          .borderWidth(1)
          .borderColor('#E0E0E0')
          .borderRadius(8)
          .margin({ bottom: 16 })
          
          Button('清理所有数据')
            .width('100%')
            .fontSize(16)
            .padding(12)
            .backgroundColor('#FF3B30')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.clearAllData();
            })
            .margin({ top: 24, bottom: 32 })
        }
          .padding({ left: 16, right: 16 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      
      // AI模型配置表单弹窗
      if (this.showModelConfigForm) {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.closeModelConfigForm();
          })
        
        // 表单容器
        Column() {
        // 标题栏
        Row() {
          Text(this.editingModelConfig ? '编辑模型配置' : '添加模型配置')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          
          Button('×')
            .fontSize(24)
            .fontColor('#666666')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.closeModelConfigForm();
            })
        }
        .width('100%')
        .padding(16)
        
        Scroll() {
          Column() {
            // 配置名称
            Column() {
              Text('配置名称')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextInput({ text: this.newModelConfig.name, placeholder: '请输入配置名称' })
                .width('100%')
                .height(40)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.newModelConfig.name = value;
                })
              
              if (this.modelConfigFormErrors.has('name')) {
                Text(this.modelConfigFormErrors.get('name')!)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // API地址
            Column() {
              Text('API地址')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextInput({ text: this.newModelConfig.apiUrl, placeholder: 'https://api.openai.com/v1/chat/completions' })
                .width('100%')
                .height(40)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.newModelConfig.apiUrl = value;
                })
              
              if (this.modelConfigFormErrors.has('apiUrl')) {
                Text(this.modelConfigFormErrors.get('apiUrl')!)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // API密钥
            Column() {
              Text('API密钥')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextInput({ text: this.newModelConfig.apiKey, placeholder: '请输入API密钥' })
                .width('100%')
                .height(40)
                .type(InputType.Password)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.newModelConfig.apiKey = value;
                })
              
              if (this.modelConfigFormErrors.has('apiKey')) {
                Text(this.modelConfigFormErrors.get('apiKey')!)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // 模型名称
            Column() {
              Text('模型名称')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextInput({ text: this.newModelConfig.model, placeholder: 'gpt-3.5-turbo' })
                .width('100%')
                .height(40)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.newModelConfig.model = value;
                })
              
              if (this.modelConfigFormErrors.has('model')) {
                Text(this.modelConfigFormErrors.get('model')!)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // 最大令牌数
            Column() {
              Text('最大令牌数')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextInput({ text: this.newModelConfig.maxTokens.toString(), placeholder: '2000' })
                .width('100%')
                .height(40)
                .type(InputType.Number)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.newModelConfig.maxTokens = parseInt(value) || 2000;
                })
              
              if (this.modelConfigFormErrors.has('maxTokens')) {
                Text(this.modelConfigFormErrors.get('maxTokens')!)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // 温度参数
            Column() {
              Text('温度参数 (0-2)')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextInput({ text: this.newModelConfig.temperature.toString(), placeholder: '0.7' })
                .width('100%')
                .height(40)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.newModelConfig.temperature = parseFloat(value) || 0.7;
                })
              
              if (this.modelConfigFormErrors.has('temperature')) {
                Text(this.modelConfigFormErrors.get('temperature')!)
                  .fontSize(12)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // 系统提示词
            Column() {
              Text('系统提示词')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              
              TextArea({ text: this.newModelConfig.systemPrompt, placeholder: '你是一个乐于助人的AI助手。' })
                .width('100%')
                .height(80)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
                .padding(12)
                .onChange((value: string) => {
                  this.newModelConfig.systemPrompt = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 12 })
            
            // 测试结果
            if (this.testResult) {
              Text(this.testResult)
                .fontSize(14)
                .fontColor(this.testResult.includes('成功') ? '#34C759' : '#FF3B30')
                .margin({ top: 12 })
                .padding(8)
                .backgroundColor('#F2F2F7')
                .borderRadius(8)
            }
            
            // 操作按钮
            Row() {
              Button('测试连接')
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor('#007AFF')
                .fontColor(Color.White)
                .borderRadius(8)
                .enabled(!this.testingConnection)
                .onClick(() => {
                  this.testApiConnection();
                })
              
              Button('保存')
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor('#34C759')
                .fontColor(Color.White)
                .borderRadius(8)
                .margin({ left: 12 })
                .onClick(() => {
                  this.saveModelConfig();
                })
              
              Button('取消')
                .fontSize(14)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .backgroundColor('#F2F2F7')
                .fontColor('#666666')
                .borderRadius(8)
                .margin({ left: 12 })
                .onClick(() => {
                  this.closeModelConfigForm();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 20 })
          }
          .width('100%')
          .padding(16)
        }
          .layoutWeight(1)
        }
        .width('90%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.3)', offsetX: 0, offsetY: 4 })
        .margin({ left: '5%', top: '10%' })
      }
      
      // 人格模板表单弹窗
      if (this.showPersonalityTemplateForm) {
        // 遮罩层
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.closePersonalityTemplateForm();
          })
        
        // 表单容器
        Column() {
        // 标题栏
        Row() {
          Text(this.editingPersonalityTemplate ? '编辑人格模板' : '添加人格模板')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
          
          Button('×')
            .fontSize(24)
            .fontColor('#666666')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.closePersonalityTemplateForm();
            })
        }
        .width('100%')
        .padding(16)
        
        Column() {
          // 模板名称
          Column() {
            Text('模板名称')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            TextInput({ text: this.newPersonalityTemplate.name, placeholder: '请输入模板名称' })
              .width('100%')
              .height(40)
              .backgroundColor('#F2F2F7')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.newPersonalityTemplate.name = value;
              })
            
            if (this.personalityTemplateFormErrors.has('name')) {
              Text(this.personalityTemplateFormErrors.get('name')!)
                .fontSize(12)
                .fontColor('#FF3B30')
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 12 })
          
          // 描述
          Column() {
            Text('描述')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            TextInput({ text: this.newPersonalityTemplate.description, placeholder: '请输入描述' })
              .width('100%')
              .height(40)
              .backgroundColor('#F2F2F7')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.newPersonalityTemplate.description = value;
              })
            
            if (this.personalityTemplateFormErrors.has('description')) {
              Text(this.personalityTemplateFormErrors.get('description')!)
                .fontSize(12)
                .fontColor('#FF3B30')
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 12 })
          
          // 提示词
          Column() {
            Text('提示词')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            TextArea({ text: this.newPersonalityTemplate.prompt, placeholder: '请输入提示词' })
              .width('100%')
              .height(120)
              .backgroundColor('#F2F2F7')
              .borderRadius(8)
              .padding(12)
              .onChange((value: string) => {
                this.newPersonalityTemplate.prompt = value;
              })
            
            if (this.personalityTemplateFormErrors.has('prompt')) {
              Text(this.personalityTemplateFormErrors.get('prompt')!)
                .fontSize(12)
                .fontColor('#FF3B30')
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 12 })
          
          // 图标
          Column() {
            Text('图标')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            
            TextInput({ text: this.newPersonalityTemplate.icon, placeholder: '🤖' })
              .width('100%')
              .height(40)
              .backgroundColor('#F2F2F7')
              .borderRadius(8)
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.newPersonalityTemplate.icon = value || '🤖';
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 12 })
          
          // 操作按钮
          Row() {
            Button('保存')
              .fontSize(14)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor('#34C759')
              .fontColor(Color.White)
              .borderRadius(8)
              .onClick(() => {
                this.savePersonalityTemplate();
              })
            
            Button('取消')
              .fontSize(14)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor('#F2F2F7')
              .fontColor('#666666')
              .borderRadius(8)
              .margin({ left: 12 })
              .onClick(() => {
                this.closePersonalityTemplateForm();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 20 })
        }
          .width('100%')
          .padding(16)
        }
        .width('90%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.3)', offsetX: 0, offsetY: 4 })
        .margin({ left: '5%', top: '10%' })
      }
    }
    .width('100%')
    .height('100%')
  }
}