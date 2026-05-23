import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:restcut/api/models/autoclip/app_models.dart';
import 'package:restcut/services/app_update_service.dart';

class ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;
  final ChangelogType type;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
    this.type = ChangelogType.feature,
  });
}

enum ChangelogType {
  major, // 重大更新
  feature, // 功能更新
  bugfix, // 错误修复
  improvement, // 改进
  security, // 安全更新
}

class ChangelogData {
  static const String _changelogPath = 'CHANGELOG.md';

  static Future<List<ChangelogEntry>> get entries async {
    try {
      List<AppChangelogRespVO> updateInfo = await AppUpdateService.instance
          .getAppChangelog();
      return ChangelogData.parseMarkdownContent(
        updateInfo.map((e) => e.changelog).join('\n'),
      );
    } catch (e) {
      return await _parseChangelogFile();
    }
  }

  // 解析 CHANGELOG.md 文件
  static Future<List<ChangelogEntry>> _parseChangelogFile() async {
    final file = await rootBundle.loadString(_changelogPath);
    return parseMarkdownContent(file);
  }

  // 解析 Markdown 内容
  static List<ChangelogEntry> parseMarkdownContent(String content) {
    final List<ChangelogEntry> entries = [];
    final lines = content.split('\n');

    String? currentVersion;
    String? currentDate;
    List<String> currentChanges = [];
    ChangelogType currentType = ChangelogType.feature;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 匹配版本标题: ## [1.1.0] - (2025-7.18)
      final versionMatch = RegExp(
        r'^## \[([^\]]+)\]\s*-\s*\(([^)]+)\)',
      ).firstMatch(line);
      if (versionMatch != null) {
        // 保存前一个版本的数据
        if (currentVersion != null && currentChanges.isNotEmpty) {
          entries.add(
            ChangelogEntry(
              version: currentVersion,
              date: currentDate ?? '',
              changes: List.from(currentChanges),
              type: currentType,
            ),
          );
        }

        // 开始新版本
        currentVersion = versionMatch.group(1);
        currentDate = versionMatch.group(2);
        currentChanges.clear();
        currentType = _determineTypeFromVersion(currentVersion!);
        continue;
      }

      // 匹配功能标题: ### 新增功能
      if (line.startsWith('### ')) {
        final section = line.substring(4).trim();
        currentType = _determineTypeFromSection(section);
        continue;
      }

      // 匹配变更项: * 引入续传api
      if (line.startsWith('* ') && currentVersion != null) {
        final change = line.substring(2).trim();
        if (change.isNotEmpty) {
          currentChanges.add(change);
        }
        continue;
      }

      // 匹配变更项: - 引入续传api (支持破折号格式)
      if (line.startsWith('- ') && currentVersion != null) {
        final change = line.substring(2).trim();
        if (change.isNotEmpty) {
          currentChanges.add(change);
        }
        continue;
      }
    }

    // 添加最后一个版本
    if (currentVersion != null && currentChanges.isNotEmpty) {
      entries.add(
        ChangelogEntry(
          version: currentVersion,
          date: currentDate ?? '',
          changes: List.from(currentChanges),
          type: currentType,
        ),
      );
    }

    return entries;
  }

  // 根据版本号确定类型
  static ChangelogType _determineTypeFromVersion(String version) {
    if (version.contains('0.')) {
      return ChangelogType.feature; // 预发布版本
    }

    final parts = version.split('.');
    if (parts.length >= 2) {
      final major = int.tryParse(parts[0].replaceAll('v', '')) ?? 0;
      final minor = int.tryParse(parts[1]) ?? 0;

      if (major > 0 && minor == 0) {
        return ChangelogType.major; // 主版本更新
      }
    }

    return ChangelogType.feature;
  }

  // 根据章节标题确定类型
  static ChangelogType _determineTypeFromSection(String section) {
    switch (section) {
      case '新增功能':
      case 'Features':
      case '新增':
        return ChangelogType.feature;
      case '修复':
      case 'Bug Fixes':
      case '修复问题':
        return ChangelogType.bugfix;
      case '改进':
      case 'Improvements':
      case '优化':
        return ChangelogType.improvement;
      case '安全更新':
      case 'Security':
        return ChangelogType.security;
      case '重大更新':
      case 'Breaking Changes':
        return ChangelogType.major;
      default:
        return ChangelogType.feature;
    }
  }

  // 获取最新版本信息
  static Future<ChangelogEntry> get latest async {
    final entriesList = await entries;
    return entriesList.first;
  }

  // 获取指定版本的更新日志
  static Future<ChangelogEntry?> getByVersion(String version) async {
    final entriesList = await entries;
    try {
      return entriesList.firstWhere((entry) => entry.version == version);
    } catch (e) {
      return null;
    }
  }

  // 获取最近的n个版本
  static Future<List<ChangelogEntry>> getRecent(int count) async {
    final entriesList = await entries;
    return entriesList.take(count).toList();
  }

  // 根据类型筛选更新日志
  static Future<List<ChangelogEntry>> getByType(ChangelogType type) async {
    final entriesList = await entries;
    return entriesList.where((entry) => entry.type == type).toList();
  }

  // 获取更新类型的中文描述
  static String getTypeDescription(ChangelogType type) {
    switch (type) {
      case ChangelogType.major:
        return '重大更新';
      case ChangelogType.feature:
        return '功能更新';
      case ChangelogType.bugfix:
        return '错误修复';
      case ChangelogType.improvement:
        return '改进优化';
      case ChangelogType.security:
        return '安全更新';
    }
  }

  // 获取更新类型的颜色
  static int getTypeColor(ChangelogType type) {
    switch (type) {
      case ChangelogType.major:
        return 0xFFE91E63; // 粉红色
      case ChangelogType.feature:
        return 0xFF2196F3; // 蓝色
      case ChangelogType.bugfix:
        return 0xFF4CAF50; // 绿色
      case ChangelogType.improvement:
        return 0xFFFF9800; // 橙色
      case ChangelogType.security:
        return 0xFFF44336; // 红色
    }
  }

  static Widget buildChangelogItem(BuildContext context, ChangelogEntry entry) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本标题和日期
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      ChangelogData.getTypeColor(entry.type),
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    entry.version,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(ChangelogData.getTypeColor(entry.type)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(
                      ChangelogData.getTypeColor(entry.type),
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ChangelogData.getTypeDescription(entry.type),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(ChangelogData.getTypeColor(entry.type)),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 更新内容列表
            ...entry.changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: BoxDecoration(
                        color: Color(
                          ChangelogData.getTypeColor(entry.type),
                        ).withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        change,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
