import 'package:flutter/material.dart';
import 'package:flutter_browser/database/favorites_database.dart';
import 'package:flutter_browser/models/favorite_model.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final favorites = await FavoritesDatabase.instance.getAllFavorites();

    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _deleteFavorite(FavoriteModel favorite) async {
    final url = favorite.url?.toString() ?? '';
    await FavoritesDatabase.instance.deleteFavorite(url);
    _loadFavorites();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已从收藏中移除'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllFavorites() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空收藏'),
        content: const Text('确定要清空所有收藏吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '清空',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FavoritesDatabase.instance.deleteAllFavorites();
      _loadFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空所有收藏')),
        );
      }
    }
  }

  List<FavoriteModel> get _filteredFavorites {
    if (_searchQuery.isEmpty) {
      return _favorites;
    }

    return _favorites.where((favorite) {
      final title = favorite.title?.toLowerCase() ?? '';
      final url = favorite.url?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return title.contains(query) || url.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllFavorites,
              tooltip: '清空收藏',
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          if (_favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索收藏',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

          // 收藏列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _favorites.isEmpty
                    ? _buildEmptyState()
                    : _filteredFavorites.isEmpty
                        ? _buildNoResultsState()
                        : _buildFavoritesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有收藏',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在网页菜单中点击"添加到收藏"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '没有找到匹配的收藏',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      itemCount: _filteredFavorites.length,
      itemBuilder: (context, index) {
        final favorite = _filteredFavorites[index];
        return _buildFavoriteItem(favorite);
      },
    );
  }

  Widget _buildFavoriteItem(FavoriteModel favorite) {
    final url = favorite.url?.toString() ?? '';
    final title = favorite.title ?? url;

    return Dismissible(
      key: Key(url),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteFavorite(favorite);
      },
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star,
            color: Colors.amber,
            size: 20,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showFavoriteOptions(favorite),
        ),
        onTap: () {
          // 返回 URL 给调用者
          Navigator.pop(context, url);
        },
      ),
    );
  }

  void _showFavoriteOptions(FavoriteModel favorite) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('打开'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(this.context, favorite.url?.toString());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteFavorite(favorite);
              },
            ),
          ],
        ),
      ),
    );
  }
}
