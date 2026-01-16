import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_browser/models/locale_model.dart';
import 'package:flutter_browser/pages/settings/general_settings_page.dart';
import 'package:flutter_browser/pages/settings/privacy_settings_page.dart';
import 'package:flutter_browser/pages/settings/appearance_settings_page.dart';
import 'package:flutter_browser/pages/settings/advanced_settings_page.dart';
import 'package:flutter_browser/pages/settings/about_page.dart';
import 'package:provider/provider.dart';

class ModernSettingsPage extends StatelessWidget {
  const ModernSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 通用设置
          _buildSettingCategory(
            context: context,
            icon: Icons.tune,
            title: l10n.generalSettings,
            subtitle: '搜索引擎、主页、语言',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GeneralSettingsPage(),
                ),
              );
            },
          ),

          // 隐私与安全
          _buildSettingCategory(
            context: context,
            icon: Icons.security,
            title: l10n.privacySettings,
            subtitle: '清除数据、Cookie、权限',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsPage(),
                ),
              );
            },
          ),

          // 外观设置
          _buildSettingCategory(
            context: context,
            icon: Icons.palette_outlined,
            title: '外观',
            subtitle: '主题、字体大小、显示设置',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppearanceSettingsPage(),
                ),
              );
            },
          ),

          // 高级设置
          _buildSettingCategory(
            context: context,
            icon: Icons.settings_suggest,
            title: '高级',
            subtitle: 'JavaScript、缓存、用户代理',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedSettingsPage(),
                ),
              );
            },
          ),

          const Divider(height: 32),

          // 关于
          _buildSettingCategory(
            context: context,
            icon: Icons.info_outline,
            title: l10n.about,
            subtitle: '版本信息、开源许可',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCategory({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
