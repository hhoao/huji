import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/profile.dart';
import 'package:restcut/widgets/common_app_bar_with_tabs.dart';
import 'package:restcut/pages/login/need_login_wrapper_widget.dart';
import 'package:restcut/pages/video/video_list_tab_content.dart';

class VideoListPage extends StatefulWidget {
  final TabController? tabController;
  const VideoListPage({super.key, this.tabController});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

enum VideoLayoutMode { feed, list }

class _VideoListPageState extends State<VideoListPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<VideoListTabContentState> _videoListKey = GlobalKey();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        widget.tabController ?? TabController(length: 2, vsync: this);
  }

  Widget _buildMenuButton() {
    return IconButton(
      icon: const Icon(Icons.menu, color: Colors.black),
      onPressed: () {
        context.push(ProfileRoute.settings);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildFilterButton() {
    return IconButton(
      icon: const Icon(Icons.filter_list, color: Colors.black),
      onPressed: () {
        _videoListKey.currentState?.showFilterDialog();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '视频列表',
        controller: _tabController,
        leftWidget: _buildMenuButton(),
        rightWidget: _buildFilterButton(),
      ),
      body: NeedLoginWrapperWidget(
        child: VideoListTabContent(key: _videoListKey),
      ),
    );
  }
}
