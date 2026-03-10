import 'package:flutter/material.dart';
import 'package:restcut/widgets/common_app_bar_with_tabs.dart';
import 'package:go_router/go_router.dart';
import 'package:restcut/router/modules/profile.dart';
import 'package:restcut/router/modules/clip.dart';
import 'package:restcut/pages/login/need_login_wrapper_widget.dart';
import 'package:restcut/models/video.dart';
import 'package:restcut/store/video.dart';
import 'task/task_tab/task_tab_content.dart';
import 'record/video_records_tab_content.dart';

// 筛选回调接口
abstract class FilterCallback {
  void onFilter();
}

class TaskRecordPage extends StatefulWidget {
  final String? clipTaskId; // 用于自动显示视频剪辑进度弹窗的任务ID
  final String? edittingRecordId; // 用于自动跳转到RoundClipPage的编辑记录ID

  const TaskRecordPage({super.key, this.clipTaskId, this.edittingRecordId});

  @override
  State<TaskRecordPage> createState() => _TaskRecordPageState();
}

class _TaskRecordPageState extends State<TaskRecordPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 用于调用子组件的筛选方法
  final GlobalKey _taskPageKey = GlobalKey();
  final GlobalKey _videoRecordsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // 当 tab 切换时，强制重建以更新筛选按钮
      setState(() {});
    });

    // 如果有指定的视频剪辑任务ID，延迟切换到本地任务tab
    if (widget.clipTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(0); // 切换到本地任务tab
      });
    }

    // 如果有指定的编辑记录ID，延迟跳转到RoundClipPage
    if (widget.edittingRecordId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final edittingRecord =
            await LocalVideoStorage().findById(widget.edittingRecordId!)
                as EdittingVideoRecord?;
        if (edittingRecord != null && mounted) {
          context.push(ClipRoute.roundClip, extra: edittingRecord);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '任务记录',
        tabs: const [
          Tab(text: '本地任务'),
          Tab(text: '剪辑记录'),
        ],
        controller: _tabController,
        leftWidget: _buildMenuButton(),
        rightWidget: _buildFilterButton(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TaskTabContent(key: _taskPageKey, clipTaskId: widget.clipTaskId),
          NeedLoginWrapperWidget(
            child: VideoRecordsTabContent(key: _videoRecordsKey),
          ),
        ],
      ),
    );
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

  void _onLocalTaskFilter() {
    // 调用本地任务的筛选功能
    // 通过 GlobalKey 调用子组件的方法
    final taskPageState = _taskPageKey.currentState;
    if (taskPageState != null) {
      // 使用 dynamic 类型来避免类型检查错误
      (taskPageState as dynamic).showFilter();
    }
  }

  void _onVideoRecordsFilter() {
    // 调用剪辑记录的筛选功能
    // 通过 GlobalKey 调用子组件的方法
    final videoRecordsState = _videoRecordsKey.currentState;
    if (videoRecordsState != null) {
      // 使用 dynamic 类型来避免类型检查错误
      (videoRecordsState as dynamic).showFilter();
    }
  }

  Widget _buildFilterButton() {
    // 根据当前选中的 tab 来决定筛选功能
    if (_tabController.index == 0) {
      // 本地任务 tab - 显示本地任务筛选
      return IconButton(
        icon: const Icon(Icons.filter_list, color: Colors.black),
        onPressed: _onLocalTaskFilter,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    } else {
      // 剪辑记录 tab - 显示剪辑记录筛选
      return IconButton(
        icon: const Icon(Icons.filter_list, color: Colors.black),
        onPressed: _onVideoRecordsFilter,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      );
    }
  }
}
