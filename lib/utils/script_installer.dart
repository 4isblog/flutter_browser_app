import 'package:flutter/material.dart';
import '../services/userscript_parser.dart';
import '../widgets/script_install_dialog.dart';

class ScriptInstaller {
  /// 检测并处理用户脚本 URL
  static Future<void> handleUrl(BuildContext context, String url) async {
    // 检查是否是用户脚本 URL
    if (!UserScriptParser.isUserScriptUrl(url)) {
      return;
    }

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在加载脚本...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 获取脚本代码 URL
      String? codeUrl = UserScriptParser.getScriptCodeUrl(url);
      
      // 如果无法获取代码 URL，尝试直接使用原 URL
      codeUrl ??= url;

      // 下载并解析脚本
      final script = await UserScriptParser.parseFromUrl(codeUrl);

      if (context.mounted) {
        // 关闭加载对话框
        Navigator.pop(context);

        if (script != null) {
          // 显示安装对话框
          final installed = await showDialog<bool>(
            context: context,
            builder: (context) => ScriptInstallDialog(script: script),
          );

          if (installed == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已安装脚本: ${script.name}'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: '查看',
                  textColor: Colors.white,
                  onPressed: () {
                    // TODO: 跳转到脚本管理页面
                  },
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法解析脚本'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error handling script URL: $e');
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载脚本失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示脚本安装提示（浮动按钮）
  static void showInstallPrompt(
    BuildContext context,
    String url,
    VoidCallback onDismiss,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.extension, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('检测到用户脚本，是否安装？'),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: '安装',
          textColor: Colors.white,
          onPressed: () {
            handleUrl(context, url);
            onDismiss();
          },
        ),
      ),
    );
  }
}
