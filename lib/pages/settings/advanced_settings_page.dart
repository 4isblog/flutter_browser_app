import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  final TextEditingController _userAgentController = TextEditingController();

  @override
  void dispose() {
    _userAgentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final browserModel = Provider.of<BrowserModel>(context);
    final windowModel = Provider.of<WindowModel>(context);
    final settings = browserModel.getSettings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('高级设置'),
      ),
      body: ListView(
        children: [
          // JavaScript
          SwitchListTile(
            secondary: const Icon(Icons.code),
            title: const Text('JavaScript'),
            subtitle: const Text('启用 JavaScript 执行'),
            value: true,
            onChanged: (value) {
              // TODO: 实现 JavaScript 设置
            },
          ),

          // 缓存
          SwitchListTile(
            secondary: const Icon(Icons.storage),
            title: const Text('缓存'),
            subtitle: const Text('启用浏览器缓存'),
            value: true,
            onChanged: (value) {
              // TODO: 实现缓存设置
            },
          ),

          // 调试模式
          SwitchListTile(
            secondary: const Icon(Icons.bug_report),
            title: Text(l10n.debuggingEnabled),
            subtitle: Text(l10n.debuggingDescription),
            value: settings.debuggingEnabled,
            onChanged: (value) {
              setState(() {
                settings.debuggingEnabled = value;
                browserModel.updateSettings(settings);
                if (windowModel.webViewTabs.isNotEmpty) {
                  var webViewModel = windowModel.getCurrentTab()?.webViewModel;
                  if (Util.isAndroid()) {
                    InAppWebViewController.setWebContentsDebuggingEnabled(
                        settings.debuggingEnabled);
                  }
                  webViewModel?.settings?.isInspectable =
                      settings.debuggingEnabled;
                  webViewModel?.webViewController?.setSettings(
                      settings: webViewModel.settings ?? InAppWebViewSettings());
                  windowModel.saveInfo();
                }
              });
            },
          ),

          const Divider(),

          // 用户代理
          FutureBuilder(
            future: InAppWebViewController.getDefaultUserAgent(),
            builder: (context, snapshot) {
              var defaultUserAgent = "";
              if (snapshot.hasData) {
                defaultUserAgent = snapshot.data as String;
              }

              return ListTile(
                leading: const Icon(Icons.phone_android),
                title: Text(l10n.defaultUserAgent),
                subtitle: Text(
                  defaultUserAgent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: defaultUserAgent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已复制到剪贴板')),
                    );
                  },
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('自定义用户代理'),
            subtitle: const Text('设置自定义 User-Agent'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUserAgentDialog(context),
          ),

          const Divider(),

          // 桌面模式
          SwitchListTile(
            secondary: const Icon(Icons.desktop_windows),
            title: Text(l10n.desktopMode),
            subtitle: const Text('默认使用桌面版网站'),
            value: false,
            onChanged: (value) {
              // TODO: 实现桌面模式设置
            },
          ),

          // 支持缩放
          SwitchListTile(
            secondary: const Icon(Icons.zoom_in),
            title: const Text('支持缩放'),
            subtitle: const Text('允许网页缩放'),
            value: true,
            onChanged: (value) {
              // TODO: 实现缩放设置
            },
          ),
        ],
      ),
    );
  }

  void _showUserAgentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义用户代理'),
        content: TextField(
          controller: _userAgentController,
          decoration: const InputDecoration(
            hintText: '输入自定义 User-Agent',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 保存自定义 User-Agent
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User-Agent 已保存')),
              );
            },
            child: Text(AppLocalizations.of(context).save),
          ),
        ],
      ),
    );
  }
}
