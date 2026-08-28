import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/changelog.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:shared_ui/shared_ui.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  List<ChangelogEntry> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final entries = await ChangelogData.entries;

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.hujiL10n.loadChangelogFailed('$e');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.hujiL10n.changelog),
        backgroundColor: context.theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (!_isLoading)
            TpIconButton(
              icon: Icons.refresh,
              onTap: _loadChangelog,
              tooltip: context.hujiL10n.actionRefresh,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(context.hujiL10n.loadingChangelog),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return TpEmptyState(
        centered: true,
        icon: Icons.error_outline,
        title: _errorMessage!,
        actionLabel: context.hujiL10n.actionRetry,
        onAction: _loadChangelog,
      );
    }

    if (_entries.isEmpty) {
      return TpEmptyState(
        centered: true,
        icon: Icons.description_outlined,
        title: context.hujiL10n.noChangelogEntries,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 关于更新日志的说明
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.theme.primaryColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        context.hujiL10n.aboutChangelogTitle,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.hujiL10n.aboutChangelogDescription,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // 更新日志列表
          ..._entries.map(
            (entry) => Column(
              children: [
                ChangelogData.buildChangelogItem(context, entry),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
