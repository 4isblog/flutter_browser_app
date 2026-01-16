import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';

class BottomMenu extends StatelessWidget {
  final VoidCallback onNewTab;
  final VoidCallback onNewIncognitoTab;
  final VoidCallback onFavorites;
  final VoidCallback onHistory;
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  final VoidCallback onShare;
  final VoidCallback onFindOnPage;
  final VoidCallback onDesktopMode;
  final bool isDesktopMode;

  const BottomMenu({
    super.key,
    required this.onNewTab,
    required this.onNewIncognitoTab,
    required this.onFavorites,
    required this.onHistory,
    required this.onDownloads,
    required this.onSettings,
    required this.onShare,
    required this.onFindOnPage,
    required this.onDesktopMode,
    required this.isDesktopMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 定义所有菜单项
    final menuItems = [
      {'icon': Icons.add, 'title': l10n.newTab, 'onTap': onNewTab},
      {'icon': Icons.privacy_tip_outlined, 'title': l10n.incognitoMode, 'onTap': onNewIncognitoTab},
      {'icon': Icons.star_outline, 'title': l10n.favorites, 'onTap': onFavorites},
      {'icon': Icons.history, 'title': l10n.history, 'onTap': onHistory},
      {'icon': Icons.download_outlined, 'title': l10n.downloads, 'onTap': onDownloads},
      {'icon': Icons.share_outlined, 'title': l10n.share, 'onTap': onShare},
      {'icon': Icons.search, 'title': l10n.findOnPage, 'onTap': onFindOnPage},
      {'icon': Icons.desktop_windows_outlined, 'title': l10n.desktopMode, 'onTap': onDesktopMode, 'isSwitch': true},
      {'icon': Icons.settings_outlined, 'title': l10n.settings, 'onTap': onSettings},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示器
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 网格布局 - 每行5个
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSwitch = item['isSwitch'] == true;
                  
                  return _buildMenuItem(
                    context: context,
                    icon: item['icon'] as IconData,
                    title: item['title'] as String,
                    onTap: item['onTap'] as VoidCallback,
                    isSwitch: isSwitch,
                    switchValue: isSwitch ? isDesktopMode : false,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSwitch = false,
    bool switchValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).iconTheme.color,
              ),
              // 如果是开关项，显示小圆点指示状态
              if (isSwitch && switchValue)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 文字
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
