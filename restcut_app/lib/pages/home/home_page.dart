import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restcut/api/models/autoclip/video_models.dart';
import 'package:restcut/config/environment.dart';
import 'package:restcut/pages/home/home_video_list_widget.dart';
import 'package:restcut/widgets/file_picker/file_selection_page.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/clip.dart';
import 'package:restcut/router/modules/message.dart';
import 'package:restcut/router/modules/profile.dart';
import 'package:restcut/router/modules/tools.dart';
import 'package:restcut/store/message.dart';
import 'package:restcut/utils/debounce/throttles.dart';

import '../../widgets/common_app_bar_with_tabs.dart';

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
      'title': 'AI比赛自动剪辑',
      'subtitle': '自动剪辑精彩片段，移除休息捡球片段',
      'image': 'assets/images/163.png',
      'color': Colors.blue,
    },
  ];

  // 全屏加载遮罩
  Widget _buildLoadingOverlay() {
    if (!_pickFileLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              '正在加载...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
          const SizedBox(height: 18),

          buildStartClipWidget(),

          const SizedBox(height: 12),

          const SizedBox(height: 74, child: HomeVideoListWidget()),

          const SizedBox(height: 18),

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['subtitle'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
    return Scaffold(
      appBar: CommonAppBar(
        title: '主页',
        leftWidget: _buildMenuButton(),
        rightWidget: _buildMessageButton(),
      ),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(children: [_buildMainContent(), _buildLoadingOverlay()]),
      ),
    );
  }

  Widget _buildMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.black),
      onPressed: () {
        Throttles.throttle(
          'home_menu',
          const Duration(milliseconds: 500),
          () => context.push(ProfileRoute.settings),
        );
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildMessageButton() {
    return Obx(() {
      final messageStore = MessageStore.instance;
      final unreadCount = messageStore.unreadCount;
      // final unreadCount = 0;

      return Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.black),
            onPressed: () {
              Throttles.throttle(
                'home_message',
                const Duration(milliseconds: 500),
                () => context.push(MessageRoute.message),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget buildStartClipWidget() {
    return GestureDetector(
      onTap: () {
        Throttles.throttle(
          'start_clip',
          const Duration(milliseconds: 500),
          () => _pickVideoAndGoToConfig(null),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.cloud_upload,
                color: Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '开始剪辑',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '实用工具',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Container(
              child: _buildToolCard(
                icon: Icons.sports_golf,
                title: '乒乓球剪辑',
                subtitle: '剪辑乒乓球比赛视频',
                color: Colors.red,
                onTap: () {
                  Throttles.throttle(
                    'pingpong_clip',
                    const Duration(milliseconds: 500),
                    () => _pickVideoAndGoToConfig(SportType.pingpong),
                  );
                },
              ),
            ),
            Container(
              child: _buildToolCard(
                icon: Icons.sports_tennis,
                title: '羽毛球剪辑',
                subtitle: '剪辑羽毛球比赛视频',
                color: Colors.blue,
                onTap: () {
                  Throttles.throttle(
                    'badminton_clip',
                    const Duration(milliseconds: 500),
                    () => _pickVideoAndGoToConfig(SportType.badminton),
                  );
                },
              ),
            ),
            Container(
              child: _buildToolCard(
                icon: Icons.image,
                title: '图片压缩',
                subtitle: '压缩图片文件',
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
            ),
            Container(
              child: _buildToolCard(
                icon: Icons.video_file,
                title: '视频压缩',
                subtitle: '压缩视频文件',
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
            ),

            if (EnvironmentConfig.isDevelopment)
              Container(
                child: _buildToolCard(
                  icon: Icons.sports_tennis,
                  title: '测试页',
                  subtitle: '测试环境',
                  color: Colors.blue,
                  onTap: () {
                    Throttles.throttle(
                      'test_page',
                      const Duration(milliseconds: 500),
                      () => context.push(ToolsRoute.test),
                    );
                  },
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
