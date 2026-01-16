import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  String _themeMode = 'system';
  double _fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('外观'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('主题'),
            subtitle: Text(_getThemeName()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('字体大小'),
            subtitle: Text('${_fontSize.toInt()}'),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: _fontSize,
              min: 12,
              max: 24,
              divisions: 12,
              label: _fontSize.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                });
              },
            ),
          ),

          const Divider(),

          SwitchListTile(
            secondary: const Icon(Icons.fullscreen),
            title: const Text('全屏模式'),
            subtitle: const Text('隐藏状态栏'),
            value: false,
            onChanged: (value) {
              // TODO: 实现全屏模式
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.image),
            title: const Text('显示图片'),
            subtitle: const Text('加载网页图片'),
            value: true,
            onChanged: (value) {
              // TODO: 实现图片显示设置
            },
          ),
        ],
      ),
    );
  }

  String _getThemeName() {
    switch (_themeMode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      case 'system':
      default:
        return '跟随系统';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('浅色'),
              value: 'light',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('深色'),
              value: 'dark',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('跟随系统'),
              value: 'system',
              groupValue: _themeMode,
              onChanged: (value) {
                setState(() {
                  _themeMode = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
