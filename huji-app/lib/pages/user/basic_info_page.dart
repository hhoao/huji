import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:huji_app/api/models/member/user_models.dart';
import 'package:huji_app/services/user_service.dart';
import 'package:huji_app/pages/user/avatar_picker_widget.dart';
import 'package:huji_app/constants/theme_manager.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';

class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({super.key});

  @override
  State<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();

  bool _isLoading = false;
  UserInfo? _userInfo;
  int? _selectedSex;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await UserService.getAndRefreshUserInfo();
      setState(() {
        _userInfo = userInfo;
        _nicknameController.text = userInfo?.nickname ?? '';
        _selectedSex = userInfo?.sex ?? 1;
      });
    } catch (e) {
      if (mounted) {
        TpToast.show(
          context,
          message: context.hujiL10n.loadUserInfoFailed('$e'),
          variant: TpToastVariant.error,
        );
      }
    }
  }

  Future<void> _updateBasicInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSex == null) {
      TpToast.show(
        context,
        message: context.hujiL10n.pleaseSelectGender,
        variant: TpToastVariant.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserService.updateUserBasicInfo(
        UpdateUserBasicInfoParams(
          nickname: _nicknameController.text,
          sex: _selectedSex!,
        ),
      );
      TpToast.show(
        context,
        message: context.hujiL10n.infoUpdatedSuccessfully,
        variant: TpToastVariant.success,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      TpToast.show(
        context,
        message: context.hujiL10n.infoUpdateFailed('$e'),
        variant: TpToastVariant.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAvatarChanged(String avatarPath) {
    setState(() {
      _userInfo?.avatar = avatarPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.hujiL10n.editProfile, style: Theme.of(context).textTheme.headlineMedium),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 头像
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: AvatarPickerWidget(
                      currentAvatar: _userInfo?.avatar ?? '',
                      onAvatarChanged: _onAvatarChanged,
                      size: 88,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(context.hujiL10n.changeAvatar, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // 信息分组卡片
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildEditRow(
                    context.hujiL10n.name,
                    _nicknameController.text,
                    onTap: () async {
                      final result = await showTpDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController(
                            text: _nicknameController.text,
                          );
                          return TpDialog(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TpDialogHeader(
                                  title: context.hujiL10n.editName,
                                ),
                                SizedBox(height: ctx.tpSpacing.lg),
                                TpInput(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: context.hujiL10n.enterName,
                                  ),
                                ),
                                TpDialogActions(
                                  children: [
                                    TpButton(
                                      variant: TpButtonVariant.ghost,
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(
                                        context.hujiL10n.taskStatusCancelledShort,
                                      ),
                                    ),
                                    TpButton(
                                      onPressed: () => Navigator.pop(
                                        ctx,
                                        controller.text,
                                      ),
                                      child: Text(
                                        context.hujiL10n.actionConfirm,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                      if (result != null && result.isNotEmpty) {
                        setState(() {
                          _nicknameController.text = result;
                        });
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    context.hujiL10n.gender,
                    _selectedSex == 1
                        ? context.hujiL10n.male
                        : context.hujiL10n.female,
                    onTap: () async {
                      final result = await showTpDialog<int>(
                        context: context,
                        builder: (ctx) => TpDialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TpDialogHeader(
                                title: context.hujiL10n.selectGender,
                              ),
                              SizedBox(height: ctx.tpSpacing.lg),
                              TpButton(
                                variant: TpButtonVariant.ghost,
                                onPressed: () => Navigator.pop(ctx, 1),
                                child: Text(context.hujiL10n.male),
                              ),
                              TpButton(
                                variant: TpButtonVariant.ghost,
                                onPressed: () => Navigator.pop(ctx, 2),
                                child: Text(context.hujiL10n.female),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedSex = result;
                        });
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    context.hujiL10n.phoneNumber,
                    _userInfo?.mobile ?? context.hujiL10n.notBound,
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    context.hujiL10n.email,
                    _userInfo?.email ?? context.hujiL10n.notBound,
                  ),
                  _buildDivider(),
                  _buildEditRow(
                    context.hujiL10n.points,
                    '${_userInfo?.experience ?? 0}',
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // 底部按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Throttles.throttle(
                          'update_basic_info',
                          const Duration(seconds: 2),
                          () => _updateBasicInfo(),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeManager.to.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(context.hujiL10n.actionSave, style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditRow(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (onTap != null)
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
