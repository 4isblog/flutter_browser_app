import 'package:flutter/material.dart';
import 'package:flutter_browser/database/history_database.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _clearHistory = true;
  bool _clearCache = true;
  bool _clearCookies = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacySettings),
      ),
      body: ListView(
        children: [
          // 清除浏览数据（合并）
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清除浏览数据'),
            subtitle: const Text('清除历史记录、缓存和 Cookie'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearDataDialog(context, l10n);
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

  Future<void> _clearBrowsingData() async {
    try {
      // 清除历史记录
      if (_clearHistory) {
        await HistoryDatabase.instance.clearAllHistory();
      }

      // 清除缓存和 Cookie
      if (_clearCache || _clearCookies) {
        await InAppWebViewController.clearAllCache();
      }

      // 清除 Cookie（额外处理）
      if (_clearCookies) {
        final cookieManager = CookieManager.instance();
        await cookieManager.deleteAllCookies();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('浏览数据已清除'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('清除浏览数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择要清除的数据类型：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('浏览历史'),
                subtitle: const Text('清除所有访问记录'),
                value: _clearHistory,
                onChanged: (value) {
                  setDialogState(() {
                    _clearHistory = value ?? true;
                  });
                  setState(() {
                    _clearHistory = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('缓存'),
                subtitle: const Text('清除网页缓存文件'),
                value: _clearCache,
                onChanged: (value) {
                  setDialogState(() {
                    _clearCache = value ?? true;
                  });
                  setState(() {
                    _clearCache = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Cookie'),
                subtitle: const Text('清除网站 Cookie'),
                value: _clearCookies,
                onChanged: (value) {
                  setDialogState(() {
                    _clearCookies = value ?? true;
                  });
                  setState(() {
                    _clearCookies = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text(
                '注意：此操作无法撤销',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearBrowsingData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('清除'),
            ),
          ],
        ),
      ),
    );
  }
}
