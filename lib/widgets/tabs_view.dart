import 'package:flutter/material.dart';
import 'package:flutter_browser/l10n/app_localizations.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:provider/provider.dart';

class TabsView extends StatelessWidget {
  final VoidCallback onNewTab;
  final VoidCallback onClose;

  const TabsView({
    super.key,
    required this.onNewTab,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final windowModel = Provider.of<WindowModel>(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${windowModel.webViewTabs.length} ${l10n.newTab}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 标签页列表
          Expanded(
            child: windowModel.webViewTabs.isEmpty
                ? _buildEmptyState(context, l10n)
                : _buildTabsList(context, windowModel),
          ),
          
          // 底部添加按钮
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[300]!,
                  width: 0.5,
                ),
              ),
            ),
            child: Center(
              child: InkWell(
                onTap: onNewTab,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 28,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.tab,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无标签页',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsList(BuildContext context, WindowModel windowModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: windowModel.webViewTabs.length,
      itemBuilder: (context, index) {
        final tab = windowModel.webViewTabs[index];
        final isCurrentTab = windowModel.getCurrentTabIndex() == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTabItem(
            context,
            tab,
            index,
            isCurrentTab,
            windowModel,
          ),
        );
      },
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    WebViewTab tab,
    int index,
    bool isCurrentTab,
    WindowModel windowModel,
  ) {
    final url = tab.webViewModel.url?.toString() ?? '';
    
    // 判断标题显示
    String title;
    if (tab.webViewModel.title?.isNotEmpty == true) {
      title = tab.webViewModel.title!;
    } else if (url.isEmpty || url == 'about:blank') {
      title = '首页';
    } else {
      title = '新标签页';
    }

    // 获取网站图标
    final favicon = tab.webViewModel.favicon;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            windowModel.showTab(index);
            onClose();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: favicon != null
                      ? ClipOval(
                          child: Image.network(
                            favicon.url.toString(),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultIcon(context, url);
                            },
                          ),
                        )
                      : _buildDefaultIcon(context, url),
                ),
                
                const SizedBox(width: 14),
                
                // 中间标题
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 右侧关闭按钮
                InkWell(
                  onTap: () {
                    windowModel.closeTab(index);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(BuildContext context, String url) {
    IconData iconData;
    
    if (url.isEmpty || url == 'about:blank') {
      iconData = Icons.home_outlined;
    } else {
      iconData = Icons.language;
    }
    
    return Icon(
      iconData,
      size: 24,
      color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
    );
  }
}
