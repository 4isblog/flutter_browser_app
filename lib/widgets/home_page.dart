import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'navigation_grid.dart';

class BrowserHomePage extends StatefulWidget {
  final Function(String) onUrlSubmit;
  final bool isIncognito;

  const BrowserHomePage({
    super.key,
    required this.onUrlSubmit,
    this.isIncognito = false,
  });

  @override
  State<BrowserHomePage> createState() => _BrowserHomePageState();
}

class _BrowserHomePageState extends State<BrowserHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _logoUrl;
  bool _logoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final logoConfig = await ApiService.getLogo();
      if (mounted) {
        setState(() {
          _logoUrl = logoConfig?.imageUrl;
          _logoLoading = false;
        });
      }
    } catch (e) {
      print('Error loading logo: $e');
      if (mounted) {
        setState(() {
          _logoLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        // 点击空白区域取消焦点
        _focusNode.unfocus();
      },
      child: Container(
        color: widget.isIncognito
            ? (Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.grey[800])
            : Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                
                // 无痕模式提示
                if (widget.isIncognito)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.deepPurple.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: Colors.deepPurple[200],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '无痕模式',
                          style: TextStyle(
                            color: Colors.deepPurple[200],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Logo
                SizedBox(
                  width: 80,
                  height: 80,
                  child: _logoLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : (_logoUrl != null && _logoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _logoUrl!,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/icon/icon.png',
                                width: 80,
                                height: 80,
                              ),
                            )
                          : Image.asset(
                              'assets/icon/icon.png',
                              width: 80,
                              height: 80,
                            )),
                ),
                
                const SizedBox(height: 40),
                
                // 搜索框
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: '搜索或输入网址',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(fontSize: 15),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        widget.onUrlSubmit(value.trim());
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 导航网格（仅在非无痕模式下显示）
                if (!widget.isIncognito)
                  NavigationGrid(
                    onNavigate: (url) {
                      widget.onUrlSubmit(url);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
