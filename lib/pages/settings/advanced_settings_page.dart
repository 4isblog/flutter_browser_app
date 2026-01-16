import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/user_agent_model.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:flutter_browser/pages/ad_block_page.dart';
import 'package:flutter_browser/pages/settings/user_agent_page.dart';
import 'package:flutter_browser/pages/user_scripts_page.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage> {
  String _getUserAgentDisplay(BrowserSettings settings) {
    if (settings.userAgentIndex >= 0 && settings.userAgentIndex < PresetUserAgents.length) {
      final preset = PresetUserAgents[settings.userAgentIndex];
      if (preset.value == 'custom' && settings.customUserAgent.isNotEmpty) {
        return settings.customUserAgent;
      }
      return preset.name;
    }
    return '默认（移动端）';
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

          // 广告拦截
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('广告拦截'),
            subtitle: const Text('订阅广告拦截规则'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdBlockPage(),
                ),
              );
            },
          ),

          // 用户脚本
          ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('用户脚本'),
            subtitle: const Text('管理自定义 JavaScript 脚本'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserScriptsPage(),
                ),
              );
            },
          ),

          const Divider(),

          // 用户代理选择
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('用户代理'),
            subtitle: Text(
              _getUserAgentDisplay(settings),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserAgentPage(),
                ),
              );
            },
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
}
