import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_browser/database/downloads_database.dart';
import 'package:flutter_browser/models/download_model.dart';
import 'package:open_file/open_file.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<DownloadModel> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
    });

    final downloads = await DownloadsDatabase.instance.getAllDownloads();

    setState(() {
      _downloads = downloads;
      _isLoading = false;
    });
  }

  Future<void> _deleteDownload(DownloadModel download) async {
    // 删除文件
    try {
      final file = File(download.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略文件删除错误
    }

    // 删除数据库记录
    await DownloadsDatabase.instance.deleteDownload(download.id!);
    _loadDownloads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
    }
  }

  Future<void> _clearAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空下载列表'),
        content: const Text('确定要清空所有下载记录吗？文件将被删除。'),
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
      // 删除所有文件
      for (var download in _downloads) {
        try {
          final file = File(download.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // 忽略错误
        }
      }

      await DownloadsDatabase.instance.clearAllDownloads();
      _loadDownloads();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空下载列表')),
        );
      }
    }
  }

  Future<void> _openFile(DownloadModel download) async {
    final file = File(download.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件不存在')),
        );
      }
      return;
    }

    final result = await OpenFile.open(download.filePath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开文件: ${result.message}')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';

    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载'),
        actions: [
          if (_downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllDownloads,
              tooltip: '清空下载列表',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloads.isEmpty
              ? _buildEmptyState()
              : _buildDownloadsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有下载',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '下载的文件会显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsList() {
    return ListView.builder(
      itemCount: _downloads.length,
      itemBuilder: (context, index) {
        final download = _downloads[index];
        return _buildDownloadItem(download);
      },
    );
  }

  Widget _buildDownloadItem(DownloadModel download) {
    return Dismissible(
      key: Key(download.id.toString()),
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
        _deleteDownload(download);
      },
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFileIconColor(download.fileName),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(download.fileName),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          download.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_formatFileSize(download.totalBytes)} • ${_formatTime(download.startTime)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (download.isDownloading || download.isPaused)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: download.progress,
                  backgroundColor: Colors.grey[300],
                ),
              ),
          ],
        ),
        trailing: _buildTrailingWidget(download),
        onTap: download.isCompleted ? () => _openFile(download) : null,
      ),
    );
  }

  Widget _buildTrailingWidget(DownloadModel download) {
    if (download.isCompleted) {
      return IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showDownloadOptions(download),
      );
    } else if (download.isFailed) {
      return const Icon(Icons.error, color: Colors.red);
    } else {
      return Text(
        '${(download.progress * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      );
    }
  }

  void _showDownloadOptions(DownloadModel download) {
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
                _openFile(download);
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
                _deleteDownload(download);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.blue;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber;
      case 'apk':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
