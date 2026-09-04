import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:huji_app/api/api_manager.dart';
import 'package:huji_app/api/models/autoclip/issue_models.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

/// Desktop settings "help & feedback" section body: FAQ, contact channels,
/// and the feedback form — inlined in the settings right pane (mobile page
/// pushes a full-screen scaffold instead).
class HujiHelpFeedbackSettingsSection extends StatefulWidget {
  const HujiHelpFeedbackSettingsSection({super.key});

  @override
  State<HujiHelpFeedbackSettingsSection> createState() =>
      _HujiHelpFeedbackSettingsSectionState();
}

class _HujiHelpFeedbackSettingsSectionState
    extends State<HujiHelpFeedbackSettingsSection> {
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
      TpToast.show(
        context,
        message: l10n.pleaseEnterTitle,
        variant: TpToastVariant.warning,
      );
      return;
    }
    if (_descController.text.trim().isEmpty) {
      TpToast.show(
        context,
        message: l10n.pleaseEnterDescription,
        variant: TpToastVariant.warning,
      );
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
      if (!mounted) return;
      TpToast.show(
        context,
        message: l10n.feedbackSubmittedSuccessfully,
        variant: TpToastVariant.success,
      );
      _titleController.clear();
      _descController.clear();
      _contactController.clear();
      setState(() {
        _selectedType = IssueTypeEnum.bug;
      });
    } catch (e) {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.submitFailedRetryLater,
        variant: TpToastVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      TpToast.show(
        context,
        message: context.hujiL10n.cannotOpenLink,
        variant: TpToastVariant.error,
      );
    }
  }

  Future<void> _copyQqGroup() async {
    await Clipboard.setData(const ClipboardData(text: '112856301'));
    if (!mounted) return;
    TpToast.show(
      context,
      message: context.hujiL10n.qqGroupCopied,
      variant: TpToastVariant.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.hujiL10n;
    final styles = TpTextStyles.of(context);

    Widget sectionTitle(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(title, style: styles.mdSemibold),
        );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TpCard.outlined(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle(l10n.faqTitle),
                _buildFAQItem(
                  l10n.faqHowToUploadVideo,
                  l10n.faqHowToUploadVideoAnswer,
                ),
                _buildDivider(),
                _buildFAQItem(
                  l10n.faqSupportedFormats,
                  l10n.faqSupportedFormatsAnswer,
                ),
                _buildDivider(),
                _buildFAQItem(
                  l10n.faqHowToSelectSport,
                  l10n.faqHowToSelectSportAnswer,
                ),
                _buildDivider(),
                _buildFAQItem(
                  l10n.faqClippingDuration,
                  l10n.faqClippingDurationAnswer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TpCard.outlined(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle(l10n.contactUs),
                _buildContactRow(
                  Icons.email,
                  l10n.emailSupport,
                  'restcut@163.com',
                  () => _launchUrl('mailto:restcut@163.com'),
                ),
                _buildDivider(),
                _buildContactRow(
                  Icons.phone,
                  l10n.customerHotline,
                  '17679358123',
                  () => _launchUrl('tel:17679358123'),
                ),
                _buildDivider(),
                _buildContactRow(
                  Icons.web,
                  l10n.officialWebsite,
                  'www.restcut.com',
                  () => _launchUrl('https://www.restcut.com'),
                ),
                _buildDivider(),
                _buildContactRow(
                  Icons.discord,
                  l10n.discordCommunity,
                  'discord.com/channels/1518551459053178960',
                  () => _launchUrl(
                    'https://discord.com/channels/1518551459053178960/1518551461242474558',
                  ),
                ),
                _buildDivider(),
                _buildContactRow(
                  Icons.groups,
                  l10n.qqGroup,
                  '112856301',
                  () => _copyQqGroup(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TpCard.outlined(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle(l10n.feedback),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _buildTypeChip(
                            IssueTypeEnum.bug,
                            l10n.issueTypeBug,
                          ),
                          const SizedBox(width: 12),
                          _buildTypeChip(
                            IssueTypeEnum.requirement,
                            l10n.issueTypeSuggestion,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TpInput(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: l10n.feedbackTitleHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TpTextarea(
                        controller: _descController,
                        decoration: InputDecoration(
                          hintText: l10n.feedbackDescriptionHint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TpInput(
                        controller: _contactController,
                        decoration: InputDecoration(
                          hintText: l10n.contactOptionalHint,
                          prefixIcon: const Icon(Icons.contact_mail),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TpButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  Throttles.throttle(
                                    'desktop_help_feedback_submit',
                                    const Duration(seconds: 2),
                                    _submitFeedback,
                                  );
                                },
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.submitFeedback),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final cs = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        iconColor: cs.onSurfaceVariant,
        title: Text(
          question,
          style: TpTextStyles.of(context).md,
        ),
        children: [
          Text(
            answer,
            style: TpTextStyles.of(context).md.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return TpHover(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TpTextStyles.of(context).md),
            const Spacer(),
            Text(
              value,
              style: TpTextStyles.of(context).md.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
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
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: cs.primaryContainer,
      labelStyle: TpTextStyles.of(context).sm.copyWith(
            color: selected ? cs.onPrimaryContainer : cs.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
      onSelected: (v) {
        if (v) setState(() => _selectedType = type);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
