import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/autoclip/issue_models.dart';
import 'package:huji_app/constants/theme_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class HelpFeedbackPage extends StatefulWidget {
  const HelpFeedbackPage({super.key});

  @override
  State<HelpFeedbackPage> createState() => _HelpFeedbackPageState();
}

class _HelpFeedbackPageState extends State<HelpFeedbackPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contactController = TextEditingController();
  IssueTypeEnum _selectedType = IssueTypeEnum.bug;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final l10n = context.hujiL10n;
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar(l10n.pleaseEnterTitle);
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnackBar(l10n.pleaseEnterDescription);
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final contact = _contactController.text.trim();
      final req = IssueCreateReqVO(
        title: _titleController.text.trim(),
        description: _descController.text.trim() +
            (contact.isNotEmpty ? '\n${l10n.contactInfoPrefix(contact)}' : ''),
        type: _selectedType,
      );
      await Api.issue.createIssue(req);
      _showSnackBar(l10n.feedbackSubmittedSuccessfully);
      _titleController.clear();
      _descController.clear();
      _contactController.clear();
      setState(() {
        _selectedType = IssueTypeEnum.bug;
      });
    } catch (e) {
      _showSnackBar(context.hujiL10n.submitFailedRetryLater);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar(context.hujiL10n.cannotOpenLink);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.hujiL10n.helpAndFeedback, style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // FAQ分组
          _buildCard([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(context.hujiL10n.faqTitle, style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildFAQItem(
              context.hujiL10n.faqHowToUploadVideo,
              context.hujiL10n.faqHowToUploadVideoAnswer,
            ),
            _buildDivider(),
            _buildFAQItem(
              context.hujiL10n.faqSupportedFormats,
              context.hujiL10n.faqSupportedFormatsAnswer,
            ),
            _buildDivider(),
            _buildFAQItem(
              context.hujiL10n.faqHowToSelectSport,
              context.hujiL10n.faqHowToSelectSportAnswer,
            ),
            _buildDivider(),
            _buildFAQItem(
              context.hujiL10n.faqClippingDuration,
              context.hujiL10n.faqClippingDurationAnswer,
            ),
          ]),
          SizedBox(height: 16),
          // 联系方式分组
          _buildCard([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(context.hujiL10n.contactUs, style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _buildContactRow(
              Icons.email,
              context.hujiL10n.emailSupport,
              'restcut@163.com',
              () => _launchUrl('mailto:restcut@163.com'),
            ),
            _buildDivider(),
            _buildContactRow(
              Icons.phone,
              context.hujiL10n.customerHotline,
              '17679358123',
              () => _launchUrl('tel:17679358123'),
            ),
            _buildDivider(),
            _buildContactRow(
              Icons.web,
              context.hujiL10n.officialWebsite,
              'www.restcut.com',
              () => _launchUrl('https://www.restcut.com'),
            ),
          ]),
          SizedBox(height: 16),
          // 反馈分组
          _buildCard([
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(context.hujiL10n.feedback, style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Row(
              children: [
                _buildTypeChip(IssueTypeEnum.bug, context.hujiL10n.issueTypeBug),
                SizedBox(width: 12),
                _buildTypeChip(
                  IssueTypeEnum.requirement,
                  context.hujiL10n.issueTypeSuggestion,
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: context.hujiL10n.feedbackTitleHint,
                hintStyle: Theme.of(context).textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: context.hujiL10n.feedbackDescriptionHint,
                hintStyle: Theme.of(context).textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _contactController,
              decoration: InputDecoration(
                hintText: context.hujiL10n.contactOptionalHint,
                hintStyle: Theme.of(context).textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.contact_mail),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Throttles.throttle(
                            'help_feedback_submit',
                            const Duration(seconds: 2),
                            () => _submitFeedback(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeManager.to.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(context.hujiL10n.submitFeedback, style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ]),
          SizedBox(height: 32),
          // 版本信息
          Center(
            child: Column(
              children: [
                Text(context.hujiL10n.settingsVersionInfo, style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Text(
                  'AutoClip v1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '© 2024 AutoClip. All rights reserved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      shape: const Border(), // 移除默认边框
      collapsedShape: const Border(), // 移除折叠时的边框
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              size: 22,
            ),
            SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
    height: 1,
    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
  );

  Widget _buildTypeChip(IssueTypeEnum type, String label) {
    final bool selected = _selectedType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      ),
      selected: selected,
      selectedColor: ThemeManager.to.primaryColor,
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
      ),
      onSelected: (v) {
        if (v) setState(() => _selectedType = type);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
