import 'package:flutter/material.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/widgets/settings/log_viewer_panel.dart';

/// Full-page log viewer (mobile / standalone entry points).
///
/// Desktop settings open the same panel through [showLogViewerDialog].
class LogViewerPage extends StatelessWidget {
  const LogViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.hujiL10n.logViewerTitle)),
      body: const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: LogViewerPanel(),
      ),
    );
  }
}
