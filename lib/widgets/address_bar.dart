import 'package:flutter/material.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:provider/provider.dart';

class BrowserAddressBar extends StatefulWidget {
  final Function(String) onSubmitted;
  final VoidCallback? onRefresh;
  final VoidCallback? onQrScan;
  final bool isHomePage;

  const BrowserAddressBar({
    super.key,
    required this.onSubmitted,
    this.onRefresh,
    this.onQrScan,
    this.isHomePage = false,
  });

  @override
  State<BrowserAddressBar> createState() => _BrowserAddressBarState();
}

class _BrowserAddressBarState extends State<BrowserAddressBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;
  String _lastUrl = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webViewModel = Provider.of<WebViewModel>(context);

    // 当不在编辑状态时，更新地址栏文本
    if (!_isEditing) {
      _updateUrlText(webViewModel);
    }

    // 判断是否显示锁图标
    final url = webViewModel.url;
    final isSecure = url?.scheme == 'https';
    final showLockIcon = !widget.isHomePage && isSecure;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 地址输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // 锁图标（在输入框内部左侧）
                  if (showLockIcon)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.green,
                      ),
                    ),
                  
                  // 输入框
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: '搜索或输入网址',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: showLockIcon ? 8 : 16,
                          vertical: 12,
                        ),
                        suffixIcon: _isEditing
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 14),
                      textInputAction: TextInputAction.go,
                      keyboardType: TextInputType.url,
                      onSubmitted: (value) {
                        widget.onSubmitted(value);
                        _focusNode.unfocus();
                      },
                      onTap: () {
                        _controller.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _controller.text.length,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 右侧按钮：首页显示二维码扫描，网页显示刷新
          _buildActionButton(webViewModel),
        ],
      ),
    );
  }

  Widget _buildActionButton(WebViewModel webViewModel) {
    // 如果是首页，显示二维码扫描按钮
    if (widget.isHomePage) {
      return IconButton(
        icon: const Icon(
          Icons.qr_code_scanner,
          size: 22,
        ),
        onPressed: widget.onQrScan ?? () {
          // TODO: 实现二维码扫描功能
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('二维码扫描功能开发中...')),
          );
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      );
    }

    // 在网页中，根据加载状态显示刷新或停止按钮
    final isLoading = webViewModel.progress < 1.0 && webViewModel.progress > 0.0;

    return IconButton(
      icon: Icon(
        isLoading ? Icons.close : Icons.refresh,
        size: 22,
      ),
      onPressed: () async {
        if (isLoading) {
          await webViewModel.webViewController?.stopLoading();
        } else {
          await webViewModel.webViewController?.reload();
        }
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
    );
  }

  void _updateUrlText(WebViewModel webViewModel) {
    String displayText;
    
    if (widget.isHomePage) {
      // 首页显示"主页"
      displayText = '主页';
    } else {
      // 网页显示 URL
      final url = webViewModel.url?.toString() ?? '';
      displayText = url;
    }
    
    // 只有当文本真正改变时才更新
    if (displayText != _lastUrl) {
      _lastUrl = displayText;
      _controller.text = displayText;
    }
  }
}
