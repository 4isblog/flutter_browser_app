# 搜索引擎设置修复和自定义功能

## 问题修复

### 原问题
搜索引擎设置在重启应用后会恢复到默认值（Google）。

### 原因分析
在 `BrowserModel` 中，`updateSettings()` 方法只更新了内存中的设置，但没有调用 `save()` 方法将设置持久化到数据库。

### 解决方案
修改 `updateSettings()` 方法，自动调用 `save()` 进行持久化：

```dart
void updateSettings(BrowserSettings settings) {
  _settings = settings;
  save(); // 自动保存到数据库
  notifyListeners();
}
```

## 新增功能：自定义搜索引擎

### 功能特性

1. **预设搜索引擎**
   - Google
   - Yahoo
   - Bing
   - DuckDuckGo
   - Ecosia

2. **自定义搜索引擎**
   - 添加任意搜索引擎
   - 自定义名称和搜索 URL
   - 编辑已有的自定义搜索引擎
   - 删除自定义搜索引擎

### 使用方法

#### 选择预设搜索引擎
1. 打开设置 → 通用设置
2. 点击"搜索引擎"
3. 选择想要的搜索引擎
4. 自动保存并生效

#### 添加自定义搜索引擎
1. 打开设置 → 通用设置 → 搜索引擎
2. 点击"添加自定义搜索引擎"
3. 输入名称（例如：百度）
4. 输入搜索 URL（例如：https://www.baidu.com/s?wd=）
5. 点击"保存"

#### 编辑自定义搜索引擎
1. 在搜索引擎列表中找到自定义搜索引擎
2. 点击"添加自定义搜索引擎"
3. 修改名称或 URL
4. 点击"保存"覆盖原有设置

#### 删除自定义搜索引擎
1. 在搜索引擎列表中找到自定义搜索引擎
2. 点击右侧的删除图标
3. 确认删除

### 常用搜索引擎 URL

#### 中文搜索引擎
- **百度**: `https://www.baidu.com/s?wd=`
- **搜狗**: `https://www.sogou.com/web?query=`
- **360搜索**: `https://www.so.com/s?q=`
- **必应中国**: `https://cn.bing.com/search?q=`

#### 国际搜索引擎
- **Google**: `https://www.google.com/search?q=`
- **Bing**: `https://www.bing.com/search?q=`
- **DuckDuckGo**: `https://duckduckgo.com/?q=`
- **Yahoo**: `https://search.yahoo.com/search?p=`

#### 专业搜索引擎
- **GitHub**: `https://github.com/search?q=`
- **Stack Overflow**: `https://stackoverflow.com/search?q=`
- **Wikipedia**: `https://en.wikipedia.org/wiki/Special:Search?search=`

### 技术实现

#### 数据结构

```dart
class BrowserSettings {
  SearchEngineModel searchEngine;           // 当前使用的搜索引擎
  SearchEngineModel? customSearchEngine;    // 自定义搜索引擎
  // ... 其他字段
}
```

#### 文件结构

```
lib/
├── models/
│   ├── browser_model.dart          # 添加 customSearchEngine 字段
│   └── search_engine_model.dart    # 搜索引擎模型
└── pages/
    └── settings/
        ├── general_settings_page.dart    # 通用设置（入口）
        └── search_engine_page.dart       # 搜索引擎选择页面（新增）
```

#### 核心功能

**SearchEnginePage**
- 显示所有预设和自定义搜索引擎
- 单选按钮选择当前搜索引擎
- 添加/编辑/删除自定义搜索引擎
- 自动保存到数据库

**数据持久化**
- 使用 SQLite 存储设置
- `updateSettings()` 自动调用 `save()`
- 应用重启后自动恢复设置

### UI 设计

#### 搜索引擎列表
- 预设搜索引擎显示图标
- 自定义搜索引擎显示搜索图标
- 当前选中的搜索引擎加粗显示
- 自定义搜索引擎显示完整 URL

#### 添加/编辑对话框
- 名称输入框
- 搜索 URL 输入框（支持多行）
- 提示信息
- 保存/取消按钮

#### 删除确认
- 确认对话框
- 如果删除的是当前使用的搜索引擎，自动切换到 Google

### 验证规则

1. **名称验证**
   - 不能为空
   - 建议简短明了

2. **URL 验证**
   - 必须以 `http://` 或 `https://` 开头
   - 建议以 `=` 结尾（搜索参数）
   - 示例：`https://www.baidu.com/s?wd=`

3. **搜索词拼接**
   - 用户输入的搜索词会自动添加到 URL 末尾
   - 例如：搜索"flutter" → `https://www.baidu.com/s?wd=flutter`

### 注意事项

1. **URL 格式**
   - 确保 URL 正确，否则搜索会失败
   - 建议先在浏览器中测试搜索 URL

2. **唯一性**
   - 只能添加一个自定义搜索引擎
   - 如需更换，先删除再添加

3. **数据安全**
   - 自定义搜索引擎存储在本地数据库
   - 不会上传到服务器

4. **兼容性**
   - 支持所有标准的搜索引擎 URL 格式
   - 某些特殊格式可能需要调整

### 测试建议

#### 基础功能测试
- [ ] 选择预设搜索引擎
- [ ] 添加自定义搜索引擎
- [ ] 编辑自定义搜索引擎
- [ ] 删除自定义搜索引擎
- [ ] 重启应用后设置保持

#### 搜索功能测试
- [ ] 使用预设搜索引擎搜索
- [ ] 使用自定义搜索引擎搜索
- [ ] 搜索中文关键词
- [ ] 搜索英文关键词
- [ ] 搜索特殊字符

#### 边界情况测试
- [ ] 空名称
- [ ] 空 URL
- [ ] 无效 URL（不以 http 开头）
- [ ] 非常长的 URL
- [ ] 删除当前使用的搜索引擎

### 未来优化

- [ ] 支持多个自定义搜索引擎
- [ ] 搜索引擎图标上传
- [ ] 搜索引擎导入/导出
- [ ] 搜索建议功能
- [ ] 搜索历史记录
- [ ] 快速切换搜索引擎（地址栏）

## 修复总结

1. **修复了设置不保存的问题** - `updateSettings()` 现在会自动调用 `save()`
2. **添加了自定义搜索引擎功能** - 用户可以添加任意搜索引擎
3. **优化了 UI 交互** - 独立的搜索引擎选择页面，更清晰直观
4. **完善了数据持久化** - 所有设置都会正确保存到数据库

现在搜索引擎设置可以正常保存，并且支持自定义搜索引擎了！
