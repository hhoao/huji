import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:huji_app/api/models/autoclip/video_models.dart';
import 'package:huji_app/config/environment.dart';
import 'package:huji_app/pages/home/home_video_list_widget.dart';
import 'package:huji_app/widgets/file_picker/file_selection_page.dart';
import 'package:go_router/go_router.dart';
import 'package:huji_app/router/modules/clip.dart';
import 'package:huji_app/router/modules/message.dart';
import 'package:huji_app/router/modules/profile.dart';
import 'package:huji_app/router/modules/tools.dart';
import 'package:huji_app/store/message.dart';
import 'package:huji_app/utils/debounce/throttles.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../widgets/common_app_bar_with_tabs.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/theme/themed_mobile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final bool _pickFileLoading = false;
  final int _currentCarouselIndex = 0;
  // 轮播图数据
  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image': 'assets/images/163.png',
      'color': Colors.blue,
    },
  ];

  // 全屏加载遮罩
  Widget _buildLoadingOverlay() {
    if (!_pickFileLoading) return const SizedBox.shrink();

    final styles = TpTextStyles.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              context.hujiL10n.homeLoading,
              style: styles.lgMediumColored(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // 主要内容widget
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 轮播图
          _buildCarousel(),
          SizedBox(height: 18),

          buildStartClipWidget(),

          SizedBox(height: 12),

          SizedBox(height: 74, child: HomeVideoListWidget()),

          SizedBox(height: 18),

          // 工具栏
          _buildToolsSection(),
        ],
      ),
    );
  }

  Future<void> _pickVideoAndGoToConfig(SportType? sportType) async {
    // 跳转到剪辑类型选择页面
    context.push(ClipRoute.clipTypeSelection, extra: {'sportType': sportType});
  }

  Widget _buildCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 200,
        viewportFraction: 1,
        enlargeCenterPage: true,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 6),
        // autoPlayAnimationDuration: const Duration(milliseconds: 1000),
        autoPlayCurve: Curves.fastOutSlowIn,
      ),
      items: _carouselItems.map((item) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item['color'].withValues(alpha: 0.8),
                    item['color'].withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // 背景图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      item['image'],
                      // "assets/images/163.png",
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // 文字内容
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 60, // 为指示器留出空间
                    child: Builder(
                      builder: (context) {
                        final styles = TpTextStyles.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.hujiL10n.homeCarouselAiClipTitle,
                              style: styles.display.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              context.hujiL10n.homeCarouselAiClipSubtitle,
                              style: styles.lgColored(Colors.white70),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // 指示器 - 左下角
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      children: _carouselItems.asMap().entries.map((entry) {
                        return Container(
                          width: 6.0,
                          height: 6.0,
                          margin: const EdgeInsets.only(right: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == entry.key
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Scaffold(
      appBar: CommonAppBar(
        title: context.hujiL10n.navHome,
        leftWidget: _buildMenuButton(),
        rightWidget: _buildMessageButton(),
      ),
      backgroundColor: cs.legacyPageBackground,
      body: SafeArea(
        child: Stack(children: [_buildMainContent(), _buildLoadingOverlay()]),
      ),
    );
  }

  Widget _buildMenuButton() {
    return TpIconButton(
      icon: Icons.menu,
      onTap: () {
        Throttles.throttle(
          'home_menu',
          const Duration(milliseconds: 500),
          () => context.push(ProfileRoute.settings),
        );
      },
    );
  }

  Widget _buildMessageButton() {
    return Obx(() {
      final messageStore = MessageStore.instance;
      final unreadCount = messageStore.unreadCount;
      final styles = TpTextStyles.of(context);
      // final unreadCount = 0;

      return Stack(
        children: [
          TpIconButton(
            icon: Icons.mail_outline,
            onTap: () {
              Throttles.throttle(
                'home_message',
                const Duration(milliseconds: 500),
                () => context.push(MessageRoute.message),
              );
            },
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  textAlign: TextAlign.center,
                  textScaler: kLegacyCaptionTextScaler,
                  style: styles.xsBoldColored(Colors.white).copyWith(height: 1.0),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget buildStartClipWidget() {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);
    return TpCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      outlined: true,
      elevation: TpCardElevation.medium,
      color: cs.legacyCardFill,
      child: TpHover(
        onTap: () {
          Throttles.throttle(
            'start_clip',
            const Duration(milliseconds: 500),
            () => _pickVideoAndGoToConfig(null),
          );
        },
        borderRadius: BorderRadius.circular(16),
        pressScale: 0.97,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  // 与 restcut_app 首页"开始剪辑"图标保持一致(蓝色云上传)
                  color: Color(0xFFE3F2FD), // Colors.blue[50]
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.cloud_upload,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  context.hujiL10n.homeStartClip,
                  style: styles.xl.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: cs.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.hujiL10n.homeToolsSection,
          textScaler: kLegacySectionTitleTextScaler,
          style: styles.xl.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildToolCard(
              icon: Icons.sports_golf,
              title: context.hujiL10n.homePingpongClip,
              subtitle: context.hujiL10n.homePingpongClipDesc,
              color: Colors.red,
              onTap: () {
                Throttles.throttle(
                  'pingpong_clip',
                  const Duration(milliseconds: 500),
                  () => _pickVideoAndGoToConfig(SportType.pingpong),
                );
              },
            ),
            _buildToolCard(
              icon: Icons.sports_tennis,
              title: context.hujiL10n.homeBadmintonClip,
              subtitle: context.hujiL10n.homeBadmintonClipDesc,
              color: Colors.blue,
              onTap: () {
                Throttles.throttle(
                  'badminton_clip',
                  const Duration(milliseconds: 500),
                  () => _pickVideoAndGoToConfig(SportType.badminton),
                );
              },
            ),
            _buildToolCard(
              icon: Icons.image,
              title: context.hujiL10n.taskTypeImageCompress,
              subtitle: context.hujiL10n.homeImageCompressDesc,
              color: Colors.purple,
              onTap: () {
                Throttles.throttle(
                  'image_compress',
                  const Duration(milliseconds: 500),
                  () async {
                    final result = await FileSelection.selectImages(
                      context: context,
                      allowMultiple: true,
                    );
                    if (result != null && result.isNotEmpty) {
                      if (mounted) {
                        context.push(
                          ToolsRoute.imageCompress,
                          extra: result.map((e) => File(e.path)).toList(),
                        );
                      }
                    }
                  },
                );
              },
            ),
            _buildToolCard(
              icon: Icons.video_file,
              title: context.hujiL10n.taskTypeVideoCompress,
              subtitle: context.hujiL10n.homeVideoCompressDesc,
              color: Colors.teal,
              onTap: () {
                Throttles.throttle(
                  'video_compress',
                  const Duration(milliseconds: 500),
                  () async {
                    final files = await FileSelection.selectVideos(
                      context: context,
                      allowMultiple: false,
                      initialTab: TabType.photoGallery,
                    );
                    if (files != null && files.isNotEmpty && mounted) {
                      context.push(
                        ToolsRoute.videoCompress,
                        extra: File(files.first.path),
                      );
                    }
                  },
                );
              },
            ),
            if (EnvironmentConfig.isDevelopment)
              _buildToolCard(
                icon: Icons.sports_tennis,
                title: context.hujiL10n.testPageTitle,
                subtitle: context.hujiL10n.testEnvironmentSubtitle,
                color: Colors.blue,
                onTap: () {
                  Throttles.throttle(
                    'test_page',
                    const Duration(milliseconds: 500),
                    () => context.push(ToolsRoute.test),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = context.cs;
    final styles = TpTextStyles.of(context);
    return TpCard.tiled(
      padding: EdgeInsets.zero,
      color: cs.legacyCardFill,
      child: TpHover(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        pressScale: 0.97,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  SizedBox(width: 6),
                  Text(
                    title,
                    style: styles.mdSemiboldColored(cs.onSurface),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                textScaler: kLegacyCaptionTextScaler,
                style: styles.mutedXs,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
