import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_script_model.dart';
import '../database/user_scripts_database.dart';

class ScriptExportService {
  static final ScriptExportService _instance = ScriptExportService._internal();
  final _database = UserScriptsDatabase();

  factory ScriptExportService() {
    return _instance;
  }

  ScriptExportService._internal();

  /// 导出所有脚本到 JSON 文件
  Future<String?> exportAllScripts() async {
    try {
      final scripts = await _database.getAllScripts();
      
      if (scripts.isEmpty) {
        return null;
      }

      final data = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'scripts': scripts.map((script) => script.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // 保存到临时文件
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/userscripts_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      print('Error exporting scripts: $e');
      return null;
    }
  }

  /// 导出单个脚本
  Future<String?> exportScript(UserScriptModel script) async {
    try {
      final data = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'scripts': [script.toJson()],
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/userscript_${script.name}_$timestamp.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      print('Error exporting script: $e');
      return null;
    }
  }

  /// 分享脚本文件
  Future<void> shareScripts(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '用户脚本备份',
      );
    } catch (e) {
      print('Error sharing scripts: $e');
    }
  }

  /// 从 JSON 文件导入脚本
  Future<ImportResult> importScripts(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (data['version'] != '1.0') {
        return ImportResult(
          success: false,
          message: '不支持的文件版本',
          importedCount: 0,
        );
      }

      final scriptsData = data['scripts'] as List<dynamic>;
      int importedCount = 0;
      int skippedCount = 0;

      for (final scriptData in scriptsData) {
        try {
          final script = UserScriptModel.fromJson(scriptData as Map<String, dynamic>);
          
          // 检查是否已存在同名脚本
          final existing = await _database.getScriptByName(script.name);
          
          if (existing != null) {
            skippedCount++;
            continue;
          }

          await _database.addScript(script);
          importedCount++;
        } catch (e) {
          print('Error importing script: $e');
          skippedCount++;
        }
      }

      return ImportResult(
        success: true,
        message: '成功导入 $importedCount 个脚本${skippedCount > 0 ? '，跳过 $skippedCount 个' : ''}',
        importedCount: importedCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入失败: $e',
        importedCount: 0,
      );
    }
  }

  /// 从文件路径导入
  Future<ImportResult> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      return await importScripts(jsonString);
    } catch (e) {
      return ImportResult(
        success: false,
        message: '读取文件失败: $e',
        importedCount: 0,
      );
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int skippedCount;

  ImportResult({
    required this.success,
    required this.message,
    required this.importedCount,
    this.skippedCount = 0,
  });
}
