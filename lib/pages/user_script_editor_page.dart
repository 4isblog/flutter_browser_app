import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/user_scripts_database.dart';
import '../models/user_script_model.dart';

class UserScriptEditorPage extends StatefulWidget {
  final UserScriptModel? script;

  const UserScriptEditorPage({super.key, this.script});

  @override
  State<UserScriptEditorPage> createState() => _UserScriptEditorPageState();
}

class _UserScriptEditorPageState extends State<UserScriptEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _database = UserScriptsDatabase();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _codeController;
  late TextEditingController _matchUrlsController;
  late TextEditingController _authorController;
  late TextEditingController _versionController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.script?.name ?? '');
    _descriptionController = TextEditingController(text: widget.script?.description ?? '');
    _codeController = TextEditingController(text: widget.script?.code ?? '');
    _matchUrlsController = TextEditingController(
      text: widget.script?.matchUrls.join('\n') ?? '',
    );
    _authorController = TextEditingController(text: widget.script?.author ?? '');
    _versionController = TextEditingController(text: widget.script?.version ?? '1.0.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _matchUrlsController.dispose();
    _authorController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _saveScript() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final matchUrls = _matchUrlsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final script = UserScriptModel(
        id: widget.script?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        code: _codeController.text,
        matchUrls: matchUrls,
        enabled: widget.script?.enabled ?? true,
        createdAt: widget.script?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        author: _authorController.text.trim().isEmpty 
            ? null 
            : _authorController.text.trim(),
        version: _versionController.text.trim().isEmpty 
            ? null 
            : _versionController.text.trim(),
      );

      if (widget.script == null) {
        await _database.addScript(script);
      } else {
        await _database.updateScript(script);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving script: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.script == null ? '添加脚本' : '编辑脚本'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveScript,
              tooltip: '保存',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 脚本名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '脚本名称',
                hintText: '例如：去广告脚本',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入脚本名称';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 脚本描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '脚本描述',
                hintText: '简要描述脚本的功能',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入脚本描述';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 作者
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: '作者（可选）',
                hintText: '脚本作者',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 版本
            TextFormField(
              controller: _versionController,
              decoration: const InputDecoration(
                labelText: '版本（可选）',
                hintText: '例如：1.0.0',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 匹配规则
            TextFormField(
              controller: _matchUrlsController,
              decoration: const InputDecoration(
                labelText: 'URL 匹配规则',
                hintText: '每行一个规则，支持通配符 * 和 ?\n例如：https://www.example.com/*',
                border: OutlineInputBorder(),
                helperText: '* 匹配任意字符，? 匹配单个字符',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入至少一个匹配规则';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 脚本代码
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'JavaScript 代码',
                hintText: '// 在这里输入 JavaScript 代码\nconsole.log("Hello World");',
                border: OutlineInputBorder(),
              ),
              maxLines: 15,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入脚本代码';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // 示例脚本按钮
            OutlinedButton.icon(
              onPressed: _showExamples,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('查看示例脚本'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExamples() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('示例脚本'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExample(
                '去广告',
                "// 移除广告元素\ndocument.querySelectorAll('.ad, .advertisement, [class*=\"ad-\"]').forEach(el => el.remove());",
              ),
              const Divider(),
              _buildExample(
                '自动翻页',
                "// 滚动到底部时自动加载下一页\nwindow.addEventListener('scroll', () => {\n  if (window.innerHeight + window.scrollY >= document.body.offsetHeight) {\n    // 触发加载下一页的逻辑\n  }\n});",
              ),
              const Divider(),
              _buildExample(
                '修改样式',
                "// 修改页面样式\nconst style = document.createElement('style');\nstyle.textContent = 'body { font-size: 16px !important; }';\ndocument.head.appendChild(style);",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String title, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
