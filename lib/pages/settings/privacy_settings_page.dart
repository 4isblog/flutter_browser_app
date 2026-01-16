import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacySettings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.clearBrowsingData),
            subtitle: const Text('清除历史记录、缓存和 Cookie'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearDataDialog(context, l10n);
            },
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.clearHistory),
            subtitle: const Text('清除浏览历史记录'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('历史记录已清除')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.cached),
            title: Text(l10n.clearCache),
            subtitle: const Text('清除缓存文件'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('缓存已清除')),
              );
            },
          ),

          const Divider(),

          SwitchListTile(
            secondary: const Icon(Icons.cookie),
            title: const Text('接受 Cookie'),
            subtitle: const Text('允许网站保存 Cookie'),
            value: true,
            onChanged: (value) {
              // TODO: 实现 Cookie 设置
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('位置权限'),
            subtitle: const Text('允许网站访问位置信息'),
            value: false,
            onChanged: (value) {
              // TODO: 实现位置权限设置
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.camera_alt),
            title: const Text('相机权限'),
            subtitle: const Text('允许网站访问相机'),
            value: false,
            onChanged: (value) {
              // TODO: 实现相机权限设置
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.mic),
            title: const Text('麦克风权限'),
            subtitle: const Text('允许网站访问麦克风'),
            value: false,
            onChanged: (value) {
              // TODO: 实现麦克风权限设置
            },
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearBrowsingData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text(l10n.history),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: Text(l10n.clearCache),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Cookie'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清除')),
              );
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
