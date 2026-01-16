import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:provider/provider.dart';

class BrowserBottomNavigationBar extends StatelessWidget {
  final bool isHomePage;
  final VoidCallback onHomePressed;
  final VoidCallback onTabsPressed;
  final VoidCallback onMenuPressed;

  const BrowserBottomNavigationBar({
    super.key,
    this.isHomePage = false,
    required this.onHomePressed,
    required this.onTabsPressed,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final windowModel = Provider.of<WindowModel>(context);
    final webViewModel = Provider.of<WebViewModel>(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 后退按钮 - 首页时禁用
              _buildNavButton(
                context: context,
                icon: Icons.arrow_back,
                onPressed: isHomePage ? null : () async {
                  final controller = webViewModel.webViewController;
                  if (controller != null) {
                    final canGoBack = await controller.canGoBack();
                    if (canGoBack) {
                      await controller.goBack();
                    }
                  }
                },
                tooltip: l10n.back,
                webViewModel: isHomePage ? null : webViewModel,
                checkCanNavigate: (controller) => controller.canGoBack(),
              ),
              
              // 前进按钮 - 首页时禁用
              _buildNavButton(
                context: context,
                icon: Icons.arrow_forward,
                onPressed: isHomePage ? null : () async {
                  final controller = webViewModel.webViewController;
                  if (controller != null) {
                    final canGoForward = await controller.canGoForward();
                    if (canGoForward) {
                      await controller.goForward();
                    }
                  }
                },
                tooltip: l10n.forward,
                webViewModel: isHomePage ? null : webViewModel,
                checkCanNavigate: (controller) => controller.canGoForward(),
              ),
              
              // 主页按钮
              _buildNavButton(
                context: context,
                icon: Icons.home_outlined,
                onPressed: onHomePressed,
                tooltip: l10n.homepage,
              ),
              
              // 标签页按钮（带数字）
              _buildTabButton(
                context: context,
                count: windowModel.webViewTabs.length,
                onPressed: onTabsPressed,
              ),
              
              // 菜单按钮
              _buildNavButton(
                context: context,
                icon: Icons.menu,
                onPressed: onMenuPressed,
                tooltip: l10n.settings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    WebViewModel? webViewModel,
    Future<bool> Function(dynamic)? checkCanNavigate,
  }) {
    // 如果需要检查导航状态，使用 FutureBuilder
    if (webViewModel != null && checkCanNavigate != null) {
      return Expanded(
        child: FutureBuilder<bool>(
          future: webViewModel.webViewController != null
              ? checkCanNavigate(webViewModel.webViewController!)
              : Future.value(false),
          builder: (context, snapshot) {
            final canNavigate = snapshot.data ?? false;
            return IconButton(
              icon: Icon(icon),
              onPressed: canNavigate ? onPressed : null,
              tooltip: tooltip,
              color: canNavigate
                  ? Theme.of(context).iconTheme.color
                  : Theme.of(context).disabledColor,
              iconSize: 24,
            );
          },
        ),
      );
    }

    // 普通按钮
    return Expanded(
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        color: Theme.of(context).iconTheme.color,
        iconSize: 24,
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required int count,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).iconTheme.color ?? Colors.black,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: count > 99 ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
