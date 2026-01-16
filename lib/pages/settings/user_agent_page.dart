import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/user_agent_model.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:provider/provider.dart';

class UserAgentPage extends StatefulWidget {
  const UserAgentPage({super.key});

  @override
  State<UserAgentPage> createState() => _UserAgentPageState();
}

class _UserAgentPageState extends State<UserAgentPage> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _getUserAgent(BrowserSettings settings) {
    if (settings.userAgentIndex >= 0 && settings.userAgentIndex < PresetUserAgents.length) {
      final preset = PresetUserAgents[settings.userAgentIndex];
      if (preset.value == 'custom') {
        return settings.customUserAgent;
      }
      return preset.value;
    }
    return '';
  }

  void _applyUserAgentToAllTabs(WindowModel windowModel, String userAgent) {
    // 应用到所有标签页
    for (var tab in windowModel.webViewTabs) {
      final webViewModel = tab.webViewModel;
      if (webViewModel.settings != null) {
        webViewModel.settings!.userAgent = userAgent.isEmpty ? null : userAgent;
        webViewModel.webViewController?.setSettings(
          settings: webViewModel.settings!,
        );
      }
    }
    windowModel.saveInfo();
  }

  @override
  Widget build(BuildContext context) {
    final browserModel = Provider.of<BrowserModel>(context);
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final settings = browserModel.getSettings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户代理'),
      ),
      body: ListView.builder(
        itemCount: PresetUserAgents.length,
        itemBuilder: (context, index) {
          final userAgent = PresetUserAgents[index];
          final isSelected = settings.userAgentIndex == index;
          final isCustom = userAgent.value == 'custom';

          return Column(
            children: [
              RadioListTile<int>(
                value: index,
                groupValue: settings.userAgentIndex,
                onChanged: (value) {
                  if (value != null) {
                    if (isCustom) {
                      // 如果选择自定义，显示输入对话框
                      _showCustomDialog(context, settings, browserModel, windowModel);
                    } else {
                      setState(() {
                        settings.userAgentIndex = value;
                        browserModel.updateSettings(settings);
                        
                        // 应用到所有标签页
                        final ua = _getUserAgent(settings);
                        _applyUserAgentToAllTabs(windowModel, ua);
                      });
                    }
                  }
                },
                title: Text(
                  userAgent.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userAgent.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isCustom && isSelected && settings.customUserAgent.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          settings.customUserAgent,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                secondary: Icon(
                  _getIconForUserAgent(index),
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
              if (index < PresetUserAgents.length - 1) const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForUserAgent(int index) {
    switch (index) {
      case 0:
        return Icons.phone_android;
      case 1:
        return Icons.smartphone;
      case 2:
        return Icons.desktop_windows;
      case 3:
        return Icons.tablet_mac;
      case 4:
        return Icons.edit;
      default:
        return Icons.devices;
    }
  }

  void _showCustomDialog(
    BuildContext context,
    BrowserSettings settings,
    BrowserModel browserModel,
    WindowModel windowModel,
  ) {
    _customController.text = settings.customUserAgent;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义用户代理'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _customController,
              decoration: const InputDecoration(
                hintText: '输入自定义 User-Agent',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '提示：输入完整的 User-Agent 字符串',
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
              final customUA = _customController.text.trim();
              if (customUA.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入 User-Agent')),
                );
                return;
              }

              setState(() {
                settings.userAgentIndex = 4; // 自定义索引
                settings.customUserAgent = customUA;
                browserModel.updateSettings(settings);
                
                // 应用到所有标签页
                _applyUserAgentToAllTabs(windowModel, customUA);
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User-Agent 已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
