import 'package:flutter/material.dart';
import '../database/ad_block_database.dart';
import '../models/ad_block_rule.dart';
import '../services/ad_block_service.dart';

class AdBlockPage extends StatefulWidget {
  const AdBlockPage({super.key});

  @override
  State<AdBlockPage> createState() => _AdBlockPageState();
}

class _AdBlockPageState extends State<AdBlockPage> {
  final _database = AdBlockDatabase();
  final _service = AdBlockService();
  List<AdBlockRule> _rules = [];
  bool _isLoading = true;
  final Map<String, bool> _updating = {};

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rules = await _database.getAllRules();
      if (mounted) {
        setState(() {
          _rules = rules;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading rules: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleRule(AdBlockRule rule) async {
    try {
      await _database.toggleRule(rule.id, !rule.enabled);
      await _service.reloadRules();
      await _loadRules();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rule.enabled ? '已禁用' : '已启用'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling rule: $e');
    }
  }

  Future<void> _updateRule(AdBlockRule rule) async {
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateProgressDialog(
        rule: rule,
        service: _service,
        onComplete: () {
          Navigator.pop(context);
          _loadRules();
        },
      ),
    );
  }

  Future<void> _deleteRule(AdBlockRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除规则'),
        content: Text('确定要删除"${rule.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _database.deleteRule(rule.id);
        await _service.reloadRules();
        await _loadRules();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除')),
          );
        }
      } catch (e) {
        print('Error deleting rule: $e');
      }
    }
  }

  Future<void> _addPresetRules() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加预设规则'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: PresetAdBlockRules.presets.map((preset) {
              return ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.description),
                onTap: () async {
                  Navigator.pop(context);
                  await _database.addRule(preset);
                  await _updateRule(preset);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('广告拦截'),
        actions: [
          // 统计按钮
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showStats,
            tooltip: '拦截统计',
          ),
          // 白名单按钮
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            onPressed: _showWhitelist,
            tooltip: '白名单',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPresetRules,
            tooltip: '添加规则',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return _buildRuleCard(rule);
                  },
                ),
    );
  }

  void _showStats() {
    final cacheStats = _service.cacheStats;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('拦截统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('已拦截请求', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${_service.blockedCount}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '缓存统计',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('缓存大小:', style: TextStyle(fontSize: 12)),
                Text('${cacheStats['blockCacheSize']} 条', style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('白名单:', style: TextStyle(fontSize: 12)),
                Text('${cacheStats['whitelistSize']} 个', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '本次会话统计，重启应用后重置',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _service.resetStats();
              _service.clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('统计和缓存已重置')),
              );
            },
            child: const Text('重置'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showWhitelist() {
    final whitelist = _service.whitelistedDomains.toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('白名单'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (whitelist.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('白名单为空', style: TextStyle(color: Colors.grey)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: whitelist.length,
                    itemBuilder: (context, index) {
                      final domain = whitelist[index];
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(domain),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            _service.removeFromWhitelist(domain);
                            Navigator.pop(context);
                            _showWhitelist();
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _addToWhitelist(),
            child: const Text('添加'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _addToWhitelist() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加到白名单'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '域名',
            hintText: '例如: example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final domain = controller.text.trim();
              if (domain.isNotEmpty) {
                _service.addToWhitelist(domain);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加 $domain 到白名单')),
                );
              }
            },
            child: const Text('添加'),
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
          Icon(Icons.block, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('还没有广告拦截规则', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右上角 + 添加规则', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildRuleCard(AdBlockRule rule) {
    final isUpdating = _updating[rule.id] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield,
                  color: rule.enabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rule.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.enabled,
                  onChanged: (value) => _toggleRule(rule),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${rule.ruleCount} 条规则',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (isUpdating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _updateRule(rule),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('更新'),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteRule(rule),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 下载进度对话框
class _UpdateProgressDialog extends StatefulWidget {
  final AdBlockRule rule;
  final AdBlockService service;
  final VoidCallback onComplete;

  const _UpdateProgressDialog({
    required this.rule,
    required this.service,
    required this.onComplete,
  });

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  double _progress = 0.0;
  String _status = '准备下载...';
  bool _isComplete = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startUpdate();
  }

  Future<void> _startUpdate() async {
    try {
      final success = await widget.service.updateRule(
        widget.rule,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _status = status;
              _isComplete = progress >= 1.0;
              _hasError = progress == 0.0 && status.contains('错误');
            });
          }
        },
      );

      if (!success && mounted) {
        setState(() {
          _hasError = true;
        });
      }

      // 自动关闭
      if (success && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _status = '错误: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('更新 ${widget.rule.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _hasError ? Colors.red : Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _status,
            style: TextStyle(
              fontSize: 14,
              color: _hasError ? Colors.red : Colors.grey[700],
            ),
          ),
          if (_isComplete && !_hasError) ...[
            const SizedBox(height: 8),
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
          ],
        ],
      ),
      actions: [
        if (_hasError || _isComplete)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isComplete) {
                widget.onComplete();
              }
            },
            child: const Text('关闭'),
          ),
      ],
    );
  }
}
