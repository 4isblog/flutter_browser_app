import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:provider/provider.dart';

class SearchEnginePage extends StatefulWidget {
  const SearchEnginePage({super.key});

  @override
  State<SearchEnginePage> createState() => _SearchEnginePageState();
}

class _SearchEnginePageState extends State<SearchEnginePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchUrlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _searchUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final browserModel = Provider.of<BrowserModel>(context);
    final settings = browserModel.getSettings();

    // 合并预设和自定义搜索引擎
    final allEngines = [
      ...SearchEngines,
      if (settings.customSearchEngine != null) settings.customSearchEngine!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索引擎'),
      ),
      body: ListView.builder(
        itemCount: allEngines.length + 1, // +1 for "添加自定义"
        itemBuilder: (context, index) {
          if (index == allEngines.length) {
            // 添加自定义搜索引擎按钮
            return ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('添加自定义搜索引擎'),
              onTap: () => _showCustomSearchEngineDialog(context, browserModel, settings),
            );
          }

          final engine = allEngines[index];
          final isSelected = settings.searchEngine.name == engine.name &&
              settings.searchEngine.searchUrl == engine.searchUrl;
          final isCustom = index >= SearchEngines.length;

          return RadioListTile<SearchEngineModel>(
            value: engine,
            groupValue: settings.searchEngine,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  settings.searchEngine = value;
                  browserModel.updateSettings(settings);
                });
                // 保存到数据库
                await browserModel.save();
              }
            },
            title: Row(
              children: [
                if (engine.assetIcon.isNotEmpty)
                  Image.asset(
                    engine.assetIcon,
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.search, size: 20);
                    },
                  )
                else
                  const Icon(Icons.search, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        engine.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isCustom)
                        Text(
                          engine.searchUrl,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteCustomSearchEngine(browserModel, settings),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCustomSearchEngineDialog(
    BuildContext context,
    BrowserModel browserModel,
    BrowserSettings settings,
  ) {
    // 如果已有自定义搜索引擎，预填充
    if (settings.customSearchEngine != null) {
      _nameController.text = settings.customSearchEngine!.name;
      _searchUrlController.text = settings.customSearchEngine!.searchUrl;
    } else {
      _nameController.clear();
      _searchUrlController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义搜索引擎'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：百度',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchUrlController,
                decoration: const InputDecoration(
                  labelText: '搜索 URL',
                  hintText: 'https://www.baidu.com/s?wd=',
                  border: OutlineInputBorder(),
                  helperText: '搜索词会自动添加到 URL 末尾',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Text(
                '提示：搜索 URL 应该以 = 结尾',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final searchUrl = _searchUrlController.text.trim();

              if (name.isEmpty || searchUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写完整信息')),
                );
                return;
              }

              if (!searchUrl.startsWith('http://') && !searchUrl.startsWith('https://')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('搜索 URL 必须以 http:// 或 https:// 开头')),
                );
                return;
              }

              // 创建自定义搜索引擎
              final customEngine = SearchEngineModel(
                name: name,
                url: searchUrl,
                searchUrl: searchUrl,
                assetIcon: '',
              );

              setState(() {
                settings.customSearchEngine = customEngine;
                settings.searchEngine = customEngine;
                browserModel.updateSettings(settings);
              });

              // 保存到数据库
              await browserModel.save();

              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('自定义搜索引擎已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomSearchEngine(
    BrowserModel browserModel,
    BrowserSettings settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除自定义搜索引擎'),
        content: const Text('确定要删除自定义搜索引擎吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        // 如果当前使用的是自定义搜索引擎，切换到 Google
        if (settings.searchEngine.name == settings.customSearchEngine?.name) {
          settings.searchEngine = GoogleSearchEngine;
        }
        settings.customSearchEngine = null;
        browserModel.updateSettings(settings);
      });

      // 保存到数据库
      await browserModel.save();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除自定义搜索引擎')),
        );
      }
    }
  }
}
