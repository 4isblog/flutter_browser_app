import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/version_model.dart';

class VersionChecker {
  /// 检查版本更新
  static Future<void> checkForUpdate(BuildContext context,
      {bool showNoUpdateDialog = false}) async {
    try {
      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 检查更新
      final versionResponse = await ApiService.checkVersion(currentVersion);

      if (versionResponse == null) {
        if (showNoUpdateDialog && context.mounted) {
          _showErrorDialog(context, '无法检查更新，请稍后再试');
        }
        return;
      }

      if (versionResponse.hasUpdate && versionResponse.updateInfo != null) {
        if (context.mounted) {
          _showUpdateDialog(context, versionResponse.updateInfo!);
        }
      } else if (showNoUpdateDialog && context.mounted) {
        _showNoUpdateDialog(context);
      }
    } catch (e) {
      print('Error checking for update: $e');
      if (showNoUpdateDialog && context.mounted) {
        _showErrorDialog(context, '检查更新失败：$e');
      }
    }
  }

  /// 显示更新对话框
  static void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => PopScope(
        canPop: !updateInfo.forceUpdate,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('发现新版本'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '版本 ${updateInfo.version}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '更新内容：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(updateInfo.updateLog),
                if (updateInfo.forceUpdate) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '这是强制更新，必须更新才能继续使用',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!updateInfo.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后更新'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadUpdate(updateInfo.downloadUrl);
              },
              child: const Text('立即更新'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示无更新对话框
  static void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已是最新版本'),
        content: const Text('当前已是最新版本，无需更新'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 下载更新
  static Future<void> _downloadUpdate(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('无法打开下载链接: $downloadUrl');
      }
    } catch (e) {
      print('Error launching download URL: $e');
    }
  }
}
