import 'package:flutter/material.dart';
import 'package:flutter_browser/database/favorites_database.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/favorite_model.dart';
import 'package:flutter_browser/models/user_agent_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_browser/models/window_model.dart';
import 'package:flutter_browser/pages/downloads_page.dart';
import 'package:flutter_browser/pages/favorites_page.dart';
import 'package:flutter_browser/pages/history_page.dart';
import 'package:flutter_browser/pages/modern_settings_page.dart';
import 'package:flutter_browser/pages/qr_scanner_page.dart';
import 'package:flutter_browser/util.dart';
import 'package:flutter_browser/webview_tab.dart';
import 'package:flutter_browser/widgets/address_bar.dart';
import 'package:flutter_browser/widgets/bottom_menu.dart';
import 'package:flutter_browser/widgets/bottom_navigation_bar.dart';
import 'package:flutter_browser/widgets/home_page.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ModernBrowser extends StatefulWidget {
  const ModernBrowser({super.key});

  @override
  State<ModernBrowser> createState() => _ModernBrowserState();
}

class _ModernBrowserState extends State<ModernBrowser> {
  bool _showHomePage = true;

  @override
  void initState() {
    super.initState();
    _initBrowser();
  }

  Future<void> _initBrowser() async {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final browserModel = Provider.of<BrowserModel>(context, listen: false);

    // 恢复浏览器设置
    await browserModel.restore();
    final settings = browserModel.getSettings();

    // 根据设置决定启动行为
    switch (settings.startupBehavior) {
      case 'restore':
        // 恢复上次的标签页
        await windowModel.restoreInfo();
        if (windowModel.webViewTabs.isEmpty) {
          setState(() {
            _showHomePage = true;
          });
        } else {
          setState(() {
            _showHomePage = false;
          });
        }
        break;

      case 'custom':
        // 打开自定义网址
        if (windowModel.webViewTabs.isNotEmpty) {
          windowModel.closeAllTabs();
        }
        if (settings.homePageEnabled && settings.customUrlHomePage.isNotEmpty) {
          _addNewTab(url: settings.customUrlHomePage);
        } else {
          setState(() {
            _showHomePage = true;
          });
        }
        break;

      case 'home':
      default:
        // 显示主页 - 创建一个首页标签
        if (windowModel.webViewTabs.isNotEmpty) {
          windowModel.closeAllTabs();
        }
        _addHomeTab();
        break;
    }
  }

  void _addNewTab({String? url, bool isIncognito = false}) {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final settings = browserModel.getSettings();

    // 创建新标签页
    final webViewSettings = isIncognito
        ? InAppWebViewSettings(
            incognito: true,
            cacheEnabled: false,
            thirdPartyCookiesEnabled: false,
          )
        : InAppWebViewSettings();
    
    // 应用 User-Agent 设置
    if (Util.isIOS() || Util.isAndroid()) {
      final userAgent = _getUserAgentFromSettings(settings);
      if (userAgent.isNotEmpty) {
        webViewSettings.userAgent = userAgent;
      }
    }
    
    final webViewModel = WebViewModel(
      url: url != null && url.isNotEmpty ? WebUri(url) : null,
      isIncognitoMode: isIncognito,
      settings: webViewSettings,
    );
    
    final webViewTab = WebViewTab(
      key: GlobalKey(),
      webViewModel: webViewModel,
    );

    windowModel.addTab(webViewTab);

    setState(() {
      // 如果没有指定 URL，显示首页让用户输入
      _showHomePage = (url == null || url.isEmpty);
    });
  }
  
  void _addHomeTab({bool isIncognito = false}) {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final settings = browserModel.getSettings();
    
    // 创建一个首页标签
    final webViewSettings = isIncognito
        ? InAppWebViewSettings(
            incognito: true,
            cacheEnabled: false,
            thirdPartyCookiesEnabled: false,
          )
        : InAppWebViewSettings();
    
    // 应用 User-Agent 设置
    if (Util.isIOS() || Util.isAndroid()) {
      final userAgent = _getUserAgentFromSettings(settings);
      if (userAgent.isNotEmpty) {
        webViewSettings.userAgent = userAgent;
      }
    }
    
    final webViewModel = WebViewModel(
      url: null,
      isIncognitoMode: isIncognito,
      settings: webViewSettings,
    );
    
    final webViewTab = WebViewTab(
      key: GlobalKey(),
      webViewModel: webViewModel,
    );
    
    windowModel.addTab(webViewTab);
    
    setState(() {
      _showHomePage = true;
    });
  }

  void _handleUrlSubmit(String input) {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final browserModel = Provider.of<BrowserModel>(context, listen: false);
    final settings = browserModel.getSettings();

    String url = input.trim();

    // 处理 bilibili:// scheme，转换为 https://
    if (url.startsWith('bilibili://')) {
      url = url.replaceFirst('bilibili://', 'https://m.bilibili.com/');
    }

    // 判断是搜索还是 URL
    if (!url.contains('.') || !url.contains('://')) {
      // 使用搜索引擎
      url = settings.searchEngine.searchUrl + Uri.encodeComponent(url);
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final currentTab = windowModel.getCurrentTab();
    
    // 检查当前标签是否是无痕模式
    final isIncognito = currentTab?.webViewModel.isIncognitoMode ?? false;
    
    // 如果当前标签页存在
    if (currentTab != null) {
      final currentUrl = currentTab.webViewModel.url;
      
      // 如果当前标签页是空的（没有 URL 或是 about:blank）
      if (currentUrl == null || currentUrl.toString().isEmpty || currentUrl.toString() == 'about:blank') {
        // 关闭当前空标签页
        final currentIndex = windowModel.getCurrentTabIndex();
        windowModel.closeTab(currentIndex);
        
        // 创建新标签页并加载 URL，保持无痕模式状态
        _addNewTab(url: url, isIncognito: isIncognito);
      } else {
        // 如果当前标签页已经有内容，创建新标签页，保持无痕模式状态
        _addNewTab(url: url, isIncognito: isIncognito);
      }
      
      setState(() {
        _showHomePage = false;
      });
    } else {
      // 如果没有标签页，创建新标签页（默认非无痕）
      _addNewTab(url: url);
    }
  }

  Future<void> _openQRScanner() async {
    // 打开二维码扫描页面
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerPage(),
      ),
    );

    // 如果扫描到内容，处理结果
    if (result != null && result.isNotEmpty) {
      _handleUrlSubmit(result);
    }
  }

  Future<void> _openFavorites() async {
    // 打开收藏页面
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(),
      ),
    );

    // 如果选择了收藏，打开该URL
    if (result != null && result.isNotEmpty) {
      _handleUrlSubmit(result);
    }
  }

  Future<void> _toggleFavorite() async {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final currentTab = windowModel.getCurrentTab();
    
    if (currentTab == null) return;
    
    final url = currentTab.webViewModel.url?.toString();
    final title = currentTab.webViewModel.title;
    
    if (url == null || url.isEmpty || url == 'about:blank') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法收藏此页面')),
      );
      return;
    }

    // 检查是否已收藏
    final isFavorite = await FavoritesDatabase.instance.isFavorite(url);
    
    if (isFavorite) {
      // 取消收藏
      await FavoritesDatabase.instance.deleteFavorite(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已从收藏中移除')),
        );
      }
    } else {
      // 添加收藏
      final favorite = FavoriteModel(
        url: currentTab.webViewModel.url,
        title: title ?? url,
        favicon: currentTab.webViewModel.favicon,
      );
      
      await FavoritesDatabase.instance.addFavorite(favorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加到收藏')),
        );
      }
    }
  }

  Future<void> _openHistory() async {
    // 打开历史记录页面
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryPage(),
      ),
    );

    // 如果选择了历史记录，打开该URL
    if (result != null && result.isNotEmpty) {
      _handleUrlSubmit(result);
    }
  }

  void _showTabsView() {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 使用 StatefulBuilder 来支持动态更新
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 计算动态高度：每个标签约60px，加上标题栏、底部按钮等固定高度
            final tabCount = windowModel.webViewTabs.length;
            final screenHeight = MediaQuery.of(context).size.height;
            
            // 固定部分高度：拖动指示器(28) + 标题栏(56) + 分隔线(1) + 底部按钮(82) + 内边距(32) = 约200
            final fixedHeight = 200.0;
            // 每个标签卡片高度：内容(50) + 间距(12) = 62
            final tabItemHeight = 62.0;
            // 计算所需总高度
            final contentHeight = fixedHeight + (tabCount * tabItemHeight);
            // 转换为比例，最小0.3，最大0.9
            final initialSize = (contentHeight / screenHeight).clamp(0.3, 0.9);
            
            return DraggableScrollableSheet(
              initialChildSize: initialSize,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // 拖动指示器
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${windowModel.webViewTabs.length} 个标签页',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // 标签页列表
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: windowModel.webViewTabs.length,
                        itemBuilder: (context, index) {
                          final tab = windowModel.webViewTabs[index];
                          final isCurrentTab = windowModel.getCurrentTabIndex() == index;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTabCardInModal(
                              context,
                              tab,
                              index,
                              isCurrentTab,
                              windowModel,
                              setModalState,
                            ),
                          );
                        },
                      ),
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
                      child: SafeArea(
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _addHomeTab();
                            },
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabCardInModal(
    BuildContext context,
    WebViewTab tab,
    int index,
    bool isCurrentTab,
    WindowModel windowModel,
    StateSetter setModalState,
  ) {
    final url = tab.webViewModel.url?.toString() ?? '';
    final isIncognito = tab.webViewModel.isIncognitoMode;
    
    // 判断标题显示
    String title;
    if (url.isEmpty || url == 'about:blank') {
      // 如果是空白页，显示"首页"或"无痕首页"
      title = isIncognito ? '无痕首页' : '首页';
    } else if (tab.webViewModel.title?.isNotEmpty == true) {
      // 如果有标题，显示标题
      title = tab.webViewModel.title!;
    } else {
      // 否则显示"新标签页"或"无痕标签页"
      title = isIncognito ? '无痕标签页' : '新标签页';
    }
    
    return Container(
      decoration: BoxDecoration(
        color: isIncognito
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[800])
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: isIncognito
            ? Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
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
            Navigator.pop(context);
            
            // 检查切换到的标签是否是首页状态
            final url = tab.webViewModel.url;
            setState(() {
              _showHomePage = (url == null || 
                               url.toString().isEmpty || 
                               url.toString() == 'about:blank');
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // 左侧图标 - 统一使用地球图标或无痕图标
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isIncognito
                        ? Colors.deepPurple.withValues(alpha: 0.3)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[100]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncognito ? Icons.privacy_tip_outlined : Icons.language,
                    size: 18,
                    color: isIncognito
                        ? Colors.deepPurple
                        : Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 中间标题
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isIncognito
                          ? Colors.deepPurple[200]
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 右侧关闭按钮
                InkWell(
                  onTap: () {
                    windowModel.closeTab(index);
                    
                    // 使用 setModalState 更新弹窗内的UI
                    setModalState(() {});
                    
                    if (windowModel.webViewTabs.isEmpty) {
                      Navigator.pop(context);
                      // 关闭所有标签后，创建一个新的首页标签
                      _addHomeTab();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isIncognito ? Colors.deepPurple[200] : Colors.grey[600],
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

  void _showBottomMenu() {
    final windowModel = Provider.of<WindowModel>(context, listen: false);
    final currentTab = windowModel.getCurrentTab();
    final webViewModel = currentTab?.webViewModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomMenu(
        onNewTab: () {
          Navigator.pop(context);
          _addHomeTab();
        },
        onNewIncognitoTab: () {
          Navigator.pop(context);
          _addHomeTab(isIncognito: true);
        },
        onAddToFavorites: () {
          Navigator.pop(context);
          _toggleFavorite();
        },
        onFavorites: () {
          Navigator.pop(context);
          _openFavorites();
        },
        onHistory: () {
          Navigator.pop(context);
          _openHistory();
        },
        onDownloads: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DownloadsPage(),
            ),
          );
        },
        onSettings: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ModernSettingsPage(),
            ),
          );
        },
        onShare: () async {
          Navigator.pop(context);
          final url = webViewModel?.url?.toString();
          if (url != null) {
            await Share.share(url);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final windowModel = Provider.of<WindowModel>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // 如果不在首页，先返回首页
        if (!_showHomePage) {
          setState(() {
            _showHomePage = true;
          });
          return;
        }
        
        // 如果在首页，显示退出确认对话框
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('退出应用'),
            content: const Text('确定要退出浏览器吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('退出'),
              ),
            ],
          ),
        );
        
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 地址栏
            BrowserAddressBar(
              onSubmitted: _handleUrlSubmit,
              isHomePage: _showHomePage,
              onQrScan: _openQRScanner,
            ),

            // 主内容区域
            Expanded(
              child: _buildContent(windowModel),
            ),

            // 底部导航栏
            BrowserBottomNavigationBar(
              isHomePage: _showHomePage,
              onHomePressed: () async {
                final windowModel = Provider.of<WindowModel>(context, listen: false);
                
                // 如果有标签页，将当前标签重置为首页状态
                if (windowModel.webViewTabs.isNotEmpty) {
                  final currentTab = windowModel.getCurrentTab();
                  if (currentTab != null) {
                    // 清空WebView内容和历史记录
                    final controller = currentTab.webViewModel.webViewController;
                    if (controller != null) {
                      // 加载空白页面
                      await controller.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
                      // 清空历史记录
                      await controller.clearHistory();
                    }
                    
                    // 清空当前标签的URL和标题
                    currentTab.webViewModel.url = null;
                    currentTab.webViewModel.title = null;
                    currentTab.webViewModel.favicon = null;
                  }
                  
                  setState(() {
                    _showHomePage = true;
                  });
                } else {
                  // 如果没有标签页，创建一个首页标签
                  _addHomeTab();
                }
              },
              onTabsPressed: _showTabsView,
              onMenuPressed: _showBottomMenu,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildContent(WindowModel windowModel) {
    // 显示主页（只有在没有标签页或明确要求显示首页时）
    if (_showHomePage && windowModel.webViewTabs.isEmpty) {
      return BrowserHomePage(
        onUrlSubmit: _handleUrlSubmit,
        isIncognito: false,
      );
    }

    // 如果有标签页但要求显示首页，在首页上方叠加显示
    if (_showHomePage && windowModel.webViewTabs.isNotEmpty) {
      final currentTab = windowModel.getCurrentTab();
      final isIncognito = currentTab?.webViewModel.isIncognitoMode ?? false;
      
      return Stack(
        children: [
          // 底层显示当前标签页
          _buildTabContent(windowModel),
          // 上层显示首页
          BrowserHomePage(
            onUrlSubmit: _handleUrlSubmit,
            isIncognito: isIncognito,
          ),
        ],
      );
    }

    // 显示当前标签页
    return _buildTabContent(windowModel);
  }

  Widget _buildTabContent(WindowModel windowModel) {
    final currentIndex = windowModel.getCurrentTabIndex();
    return IndexedStack(
      index: currentIndex,
      children: windowModel.webViewTabs.map((tab) {
        final isCurrentTab = currentIndex == tab.webViewModel.tabIndex;

        if (isCurrentTab) {
          return tab;
        } else {
          // 非当前标签页，返回空容器以节省资源
          return Container();
        }
      }).toList(),
    );
  }

  String _getUserAgentFromSettings(BrowserSettings settings) {
    if (settings.userAgentIndex >= 0 && settings.userAgentIndex < PresetUserAgents.length) {
      final preset = PresetUserAgents[settings.userAgentIndex];
      if (preset.value == 'custom') {
        return settings.customUserAgent;
      }
      return preset.value;
    }
    // 默认返回 Chrome 移动端
    return PresetUserAgents[1].value;
  }
}
