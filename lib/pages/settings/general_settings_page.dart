import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/locale_model.dart';
import 'package:flutter_browser/pages/settings/search_engine_page.dart';
import 'package:provider/provider.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  final TextEditingController _homePageController = TextEditingController();

  @override
  void dispose() {
    _homePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final browserModel = Provider.of<BrowserModel>(context);
    final localeModel = Provider.of<LocaleModel>(context);
    final settings = browserModel.getSettings();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.generalSettings),
      ),
      body: ListView(
        children: [
          // 语言设置
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_getLanguageName(localeModel.locale, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, localeModel, l10n),
          ),

          const Divider(),

          // 启动行为
          ListTile(
            leading: const Icon(Icons.power_settings_new),
            title: const Text('启动时'),
            subtitle: Text(_getStartupBehaviorName(settings.startupBehavior)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStartupBehaviorDialog(context, browserModel, settings),
          ),

          const Divider(),

          // 搜索引擎
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(l10n.searchEngine),
            subtitle: Text(settings.searchEngine.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchEnginePage(),
                ),
              );
            },
          ),

          // 主页设置
          SwitchListTile(
            secondary: const Icon(Icons.home),
            title: const Text('起始页'),
            subtitle: Text(settings.homePageEnabled
                ? (settings.customUrlHomePage.isEmpty
                    ? l10n.on
                    : settings.customUrlHomePage)
                : l10n.off),
            value: settings.homePageEnabled,
            onChanged: (value) {
              setState(() {
                settings.homePageEnabled = value;
                browserModel.updateSettings(settings);
              });
            },
          ),

          if (settings.homePageEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _homePageController
                  ..text = settings.customUrlHomePage,
                decoration: InputDecoration(
                  labelText: '自定义起始页 URL',
                  hintText: 'https://www.example.com',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      settings.customUrlHomePage = _homePageController.text;
                      browserModel.updateSettings(settings);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.save)),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getStartupBehaviorName(String behavior) {
    switch (behavior) {
      case 'home':
        return '显示主页';
      case 'restore':
        return '恢复上次的标签页';
      case 'custom':
        return '打开自定义网址';
      default:
        return '显示主页';
    }
  }

  void _showStartupBehaviorDialog(
    BuildContext context,
    BrowserModel browserModel,
    dynamic settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('启动时'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('显示主页'),
              subtitle: const Text('每次启动都显示主页'),
              value: 'home',
              groupValue: settings.startupBehavior,
              onChanged: (value) {
                setState(() {
                  settings.startupBehavior = value!;
                  browserModel.updateSettings(settings);
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('恢复上次的标签页'),
              subtitle: const Text('继续上次浏览的内容'),
              value: 'restore',
              groupValue: settings.startupBehavior,
              onChanged: (value) {
                setState(() {
                  settings.startupBehavior = value!;
                  browserModel.updateSettings(settings);
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('打开自定义网址'),
              subtitle: const Text('打开指定的网址'),
              value: 'custom',
              groupValue: settings.startupBehavior,
              onChanged: (value) {
                setState(() {
                  settings.startupBehavior = value!;
                  browserModel.updateSettings(settings);
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'zh':
        return l10n.chinese;
      case 'en':
        return l10n.english;
      default:
        return l10n.chinese;
    }
  }

  void _showLanguageDialog(
    BuildContext context,
    LocaleModel localeModel,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.chinese),
              value: 'zh',
              groupValue: localeModel.locale.languageCode,
              onChanged: (value) {
                localeModel.setLocale(const Locale('zh', ''));
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.english),
              value: 'en',
              groupValue: localeModel.locale.languageCode,
              onChanged: (value) {
                localeModel.setLocale(const Locale('en', ''));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
