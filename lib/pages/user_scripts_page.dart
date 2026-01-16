import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../database/user_scripts_database.dart';
import '../models/user_script_model.dart';
import '../services/script_export_service.dart';
import '../utils/script_installer.dart';
import 'user_script_editor_page.dart';

class UserScriptsPage extends StatefulWidget {
  const UserScriptsPage({super.key});

  @override
  State<UserScriptsPage> createState() => _UserScriptsPageState();
}

class _UserScriptsPageState extends State<UserScriptsPage> {
  final _database = UserScriptsDatabase();
  List<UserScriptModel> _scripts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final scripts = await _database.getAllScripts();
      if (mounted) {
        setState(() {
          _scripts = scripts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading scripts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleScript(UserScriptModel script) async {
    try {
      await _database.toggleScript(script.id, !script.enabled);
      await _loadScripts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(script.enabled ? '脚本已禁用' : '脚本已启用'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling script: $e');
    }
  }

  Future<void> _deleteScript(UserScriptModel script) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除脚本'),
        content: Text('确定要删除"${script.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _database.deleteScript(script.id);
        await _loadScripts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('脚本已删除'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        print('Error deleting script: $e');
      }
    }
  }

  Future<void> _addNewScript() async {
    // 显示选择对话框
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加脚本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('手动创建'),
              subtitle: const Text('编写自己的脚本'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('从 URL 安装'),
              subtitle: const Text('从 Greasyfork 等网站安装'),
              onTap: () => Navigator.pop(context, 'url'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'manual') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserScriptEditorPage(),
        ),
      );

      if (result == true) {
        await _loadScripts();
      }
    } else if (choice == 'url') {
      _installFromUrl();
    }
  }

  Future<void> _installFromUrl() async {
    final controller = TextEditingController();
    
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('从 URL 安装脚本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '脚本 URL',
                hintText: 'https://greasyfork.org/...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              '支持 Greasyfork、OpenUserJS 和 .user.js 文件',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context, url);
              }
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty && mounted) {
      // 使用 ScriptInstaller 处理安装
      await ScriptInstaller.handleUrl(context, url);
      await _loadScripts();
    }
  }

  Future<void> _editScript(UserScriptModel script) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserScriptEditorPage(script: script),
      ),
    );

    if (result == true) {
      await _loadScripts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户脚本'),
        actions: [
          // 导入导出菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportScripts();
                  break;
                case 'import':
                  _importScripts();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 12),
                    Text('导出脚本'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 12),
                    Text('导入脚本'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewScript,
            tooltip: '添加脚本',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scripts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _scripts.length,
                  itemBuilder: (context, index) {
                    final script = _scripts[index];
                    return _buildScriptCard(script);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.code_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有脚本',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 添加脚本',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptCard(UserScriptModel script) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _editScript(script),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: script.enabled
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.code,
                      color: script.enabled ? Colors.blue : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          script.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          script.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // 开关
                  Switch(
                    value: script.enabled,
                    onChanged: (value) => _toggleScript(script),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 匹配规则
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: script.matchUrls.take(3).map((url) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      url,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              if (script.matchUrls.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${script.matchUrls.length - 3} 更多',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // 操作按钮
              Row(
                children: [
                  if (script.author != null)
                    Text(
                      '作者: ${script.author}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (script.version != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      'v${script.version}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _deleteScript(script),
                    color: Colors.red,
                    tooltip: '删除',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导出脚本
  Future<void> _exportScripts() async {
    try {
      final exportService = ScriptExportService();
      final filePath = await exportService.exportAllScripts();
      
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有可导出的脚本')),
          );
        }
        return;
      }

      if (mounted) {
        // 显示分享对话框
        await exportService.shareScripts(filePath);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('脚本已导出')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  /// 导入脚本
  Future<void> _importScripts() async {
    try {
      // 使用 file_picker 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法读取文件')),
          );
        }
        return;
      }

      // 显示加载对话框
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final exportService = ScriptExportService();
      final importResult = await exportService.importFromFile(file.path!);

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.message),
            backgroundColor: importResult.success ? Colors.green : Colors.red,
          ),
        );

        if (importResult.success) {
          await _loadScripts();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }
}
