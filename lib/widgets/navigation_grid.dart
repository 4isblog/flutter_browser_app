import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/navigation_model.dart';
import '../services/api_service.dart';

class NavigationGrid extends StatefulWidget {
  final Function(String url) onNavigate;

  const NavigationGrid({
    super.key,
    required this.onNavigate,
  });

  @override
  State<NavigationGrid> createState() => _NavigationGridState();
}

class _NavigationGridState extends State<NavigationGrid> {
  List<NavigationItem> _navigations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNavigations();
  }

  Future<void> _loadNavigations() async {
    try {
      final navigations = await ApiService.getNavigations();
      if (mounted) {
        setState(() {
          _navigations = navigations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading navigations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_navigations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Text(
              '常用网站',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _navigations.length,
            itemBuilder: (context, index) {
              final nav = _navigations[index];
              return _buildNavigationItem(nav);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem nav) {
    return InkWell(
      onTap: () => widget.onNavigate(nav.url),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: nav.icon != null && nav.icon!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: nav.icon!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(
                          Icons.language,
                          size: 32,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.language,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.language,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // 名称
            Flexible(
              child: Text(
                nav.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
