import 'package:flutter/material.dart';
import 'package:restcut/api/models/member/user_models.dart';
import 'package:restcut/services/user_service.dart';
import 'package:restcut/pages/user/avatar_picker_widget.dart';
import 'package:restcut/constants/theme_manager.dart';
import 'package:restcut/utils/debounce/throttles.dart';

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
      _showSnackBar('加载用户信息失败: $e');
    }
  }

  Future<void> _updateBasicInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSex == null) {
      _showSnackBar('请选择性别');
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
      _showSnackBar('信息更新成功');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('信息更新失败: $e');
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
        title: Text('编辑资料', style: Theme.of(context).textTheme.headlineMedium),
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
                  const SizedBox(height: 8),
                  Text(
                    '更换头像',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                    '名字',
                    _nicknameController.text,
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(
                            text: _nicknameController.text,
                          );
                          return AlertDialog(
                            title: Text(
                              '修改名字',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: '请输入名字',
                                hintStyle: Theme.of(
                                  context,
                                ).textTheme.bodyMedium,
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  '取消',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, controller.text),
                                child: Text(
                                  '确定',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
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
                    '性别',
                    _selectedSex == 1 ? '男' : '女',
                    onTap: () async {
                      final result = await showDialog<int>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: Text(
                            '选择性别',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          children: [
                            SimpleDialogOption(
                              child: Text(
                                '男',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onPressed: () => Navigator.pop(context, 1),
                            ),
                            SimpleDialogOption(
                              child: Text(
                                '女',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onPressed: () => Navigator.pop(context, 2),
                            ),
                          ],
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
                  _buildEditRow('手机号', _userInfo?.mobile ?? '暂未绑定'),
                  _buildDivider(),
                  _buildEditRow('邮箱', _userInfo?.email ?? '暂未绑定'),
                  _buildDivider(),
                  _buildEditRow('积分', '${_userInfo?.experience ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                    : Text(
                        '保存',
                        style: Theme.of(
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
