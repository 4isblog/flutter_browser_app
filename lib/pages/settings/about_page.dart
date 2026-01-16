import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.about),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),

          // App 图标
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/icon/icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App 名称
          Center(
            child: Text(
              l10n.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          const SizedBox(height: 32),

          // 版本信息
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final packageInfo = snapshot.data!;
              return Column(
                children: [
                  _buildInfoTile(
                    context: context,
                    icon: Icons.info_outline,
                    title: l10n.version,
                    value: packageInfo.version,
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.build,
                    title: l10n.buildNumber,
                    value: packageInfo.buildNumber,
                  ),
                  _buildInfoTile(
                    context: context,
                    icon: Icons.apps,
                    title: l10n.packageName,
                    value: packageInfo.packageName,
                  ),
                ],
              );
            },
          ),

          const Divider(height: 32),

          // 项目链接
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.code,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(l10n.flutterInAppWebViewProject),
            subtitle: const Text('https://github.com/pichillilorenzo/flutter_inappwebview'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              final url = Uri.parse('https://github.com/pichillilorenzo/flutter_inappwebview');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),

          const Divider(),

          // 开源许可
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('开源许可'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: l10n.appName,
                applicationIcon: Image.asset(
                  'assets/icon/icon.png',
                  width: 48,
                  height: 48,
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // 版权信息
          Center(
            child: Text(
              '© 2024 ${l10n.appName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 20),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已复制到剪贴板')),
          );
        },
      ),
    );
  }
}
