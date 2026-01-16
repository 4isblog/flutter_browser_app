import 'package:flutter/material.dart';
import '../models/user_script_model.dart';
import '../database/user_scripts_database.dart';

class ScriptInstallDialog extends StatelessWidget {
  final UserScriptModel script;

  const ScriptInstallDialog({
    super.key,
    required this.script,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.extension, color: Colors.blue),
          const SizedBox(width: 8),
          const Expanded(child: Text('安装用户脚本')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 脚本名称
            _buildInfoRow('名称', script.name, Icons.title),
            const SizedBox(height: 12),
            
            // 描述
            _buildInfoRow('描述', script.description, Icons.description),
            const SizedBox(height: 12),
            
            // 作者
            if (script.author != null)
              _buildInfoRow('作者', script.author!, Icons.person),
            if (script.author != null) const SizedBox(height: 12),
            
            // 版本
            if (script.version != null)
              _buildInfoRow('版本', script.version!, Icons.info),
            if (script.version != null) const SizedBox(height: 12),
            
            // 匹配规则
            _buildMatchUrls(),
            
            const SizedBox(height: 16),
            
            // 警告提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '请确保脚本来自可信来源',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              final database = UserScriptsDatabase();
              await database.addScript(script);
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('安装失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, false);
              }
            }
          },
          icon: const Icon(Icons.download),
          label: const Text('安装'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchUrls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '匹配规则',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: script.matchUrls.take(5).map((url) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
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
        ),
        if (script.matchUrls.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${script.matchUrls.length - 5} 更多',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }
}
